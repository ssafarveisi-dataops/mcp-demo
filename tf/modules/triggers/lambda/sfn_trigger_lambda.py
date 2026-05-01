# /// script
# requires-python = ">=3.14"
# dependencies = [
#     "boto3>=1.42.97",
# ]
# ///

"""sfn_trigger_lambda.py
-----------------------
AWS Lambda function triggered by an EventBridge CRON rule.

Behaviour on each invocation
-----------------------------
1. Read ``STATE_MACHINE_ARN`` and ``SQS_QUEUE_URL`` from the environment.
2. If the target Step Function already has a RUNNING execution -> skip and
   leave the SQS message untouched (it will be picked up on the next tick).
3. Poll the SQS FIFO queue for exactly one message (short-poll).
4. If the queue is empty -> do nothing and return successfully.
5. Parse the message body as JSON, extract the first record from the
   ``Records`` list (as produced by S3 event notifications), and pass the
   ``s3`` object of that record as the Step Function input.
   - ``ExecutionAlreadyExists`` -> delete the duplicate message and skip.
   - Any other ``ClientError``  -> leave the message in the queue and re-raise.
6. Delete the SQS message only after a successful ``StartExecution`` call.
7. Return ``{"status": "STARTED", "executionArn": ..., "messageId": ...}``.

Concurrency policy
------------------
At most **one** execution of the state machine may run at a time. The lambda
checks for any RUNNING execution before dequeuing; if one is found the
message is left in the queue and the lambda exits successfully.

Required environment variables
--------------------------------
STATE_MACHINE_ARN  -- ARN of the AWS Step Functions state machine.
SQS_QUEUE_URL      -- URL of the SQS FIFO queue.
"""

import json
import logging
import os
from typing import Any

import boto3
from botocore.exceptions import ClientError

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# ---------------------------------------------------------------------------
# AWS clients  (module-level so they are reused across Lambda warm starts)
# ---------------------------------------------------------------------------

_sfn_client = boto3.client("stepfunctions")
_sqs_client = boto3.client("sqs")


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _is_step_function_running(state_machine_arn: str) -> bool:
    """
    Return *True* if at least one execution of *state_machine_arn* is RUNNING.

    Paginates ``list_executions`` with ``statusFilter="RUNNING"`` and
    ``maxResults=1`` so the loop exits as soon as the first RUNNING execution
    is found — typically in a single API call.

    :param state_machine_arn: Full ARN of the AWS Step Functions state machine.
    :return: True - one or more RUNNING executions exist.
             False - no RUNNING executions exist.
    """
    logger.info(
        "Checking for RUNNING executions of state machine: %s",
        state_machine_arn,
    )

    kwargs: dict[str, Any] = {
        "stateMachineArn": state_machine_arn,
        "statusFilter": "RUNNING",
        "maxResults": 1,
    }

    while True:
        response = _sfn_client.list_executions(**kwargs)
        executions = response.get("executions", [])

        if executions:
            logger.info(
                "Found RUNNING execution: executionArn=%s",
                executions[0]["executionArn"],
            )
            return True

        next_token = response.get("nextToken")
        if not next_token:
            break

        kwargs["nextToken"] = next_token

    logger.info("No RUNNING executions found for state machine: %s", state_machine_arn)
    return False


def _receive_one_message(queue_url: str) -> dict[str, Any] | None:
    """Attempt to receive exactly one message from an SQS FIFO queue (short-poll).

    Parameters
    ----------
    queue_url:
        URL of the SQS FIFO queue.

    Returns
    -------
    dict | None
        The raw SQS message dict (keys include ``MessageId``, ``ReceiptHandle``,
        and ``Body``), or ``None`` if the queue was empty.
    """
    logger.info("Polling SQS queue for one message (short-poll): %s", queue_url)

    response = _sqs_client.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=1,
        WaitTimeSeconds=0,
    )

    messages = response.get("Messages", [])
    if not messages:
        return None

    message = messages[0]
    logger.info(
        "Received SQS message: MessageId=%s ReceiptHandle=%s",
        message["MessageId"],
        message["ReceiptHandle"],
    )
    return message


def _delete_sqs_message(
    queue_url: str,
    receipt_handle: str,
    message_id: str,
) -> None:
    """Delete a single SQS message.

    Logs a WARNING if deletion fails but does **not** raise, so that an
    already-started Step Function execution is never rolled back on account
    of a cleanup failure.  Any future duplicate delivery of the same message
    is handled safely by the ``ExecutionAlreadyExists`` guard in the handler.

    Parameters
    ----------
    queue_url:
        URL of the SQS FIFO queue.
    receipt_handle:
        Receipt handle returned by ``receive_message``.
    message_id:
        SQS ``MessageId`` -- used only in log messages for traceability.
    """
    try:
        _sqs_client.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=receipt_handle,
        )
        logger.info("Deleted SQS message: MessageId=%s", message_id)
    except ClientError as exc:
        logger.warning(
            "Failed to delete SQS message MessageId=%s after a successful "
            "StartExecution call.  The message will become visible again after "
            "its visibility timeout; any duplicate delivery is handled via the "
            "ExecutionAlreadyExists guard.  Error: %s",
            message_id,
            exc,
        )


# ---------------------------------------------------------------------------
# Lambda handler
# ---------------------------------------------------------------------------


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """
    AWS Lambda entry-point, triggered by an EventBridge CRON rule.

    At most one Step Function execution is allowed to run at a time.  When the
    state machine is idle the handler dequeues one message, wraps its JSON body
    under the ``detail`` key, and starts a new execution.

    Parameters
    ----------
    event:
        EventBridge scheduled-event payload (not consumed by this function).
    context:
        Lambda context object (not consumed by this function).

    Returns
    -------
    dict
        One of the following response shapes::

            {"status": "SKIPPED", "reason": "Step Function already running"}
            {"status": "SKIPPED", "reason": "SQS queue is empty"}
            {"status": "SKIPPED",
             "reason": "Execution already exists (duplicate message)",
             "messageId": "<id>"}
            {"status": "STARTED",
             "executionArn": "<arn>",
             "messageId": "<id>"}

    Raises
    ------
    ClientError
        Re-raised for any ``start_execution`` failure other than
        ``ExecutionAlreadyExists``.  The SQS message is intentionally *not*
        deleted so it re-enters the queue after its visibility timeout expires.
    KeyError
        Raised if ``STATE_MACHINE_ARN`` or ``SQS_QUEUE_URL`` are absent from
        the Lambda environment.
    json.JSONDecodeError
        Raised if the SQS message body is not valid JSON.
    """
    # ------------------------------------------------------------------
    # 1. Required environment variables
    # ------------------------------------------------------------------
    state_machine_arn: str = os.environ["STATE_MACHINE_ARN"]
    sqs_queue_url: str = os.environ["SQS_QUEUE_URL"]

    logger.info(
        "lambda_handler invoked | STATE_MACHINE_ARN=%s  SQS_QUEUE_URL=%s",
        state_machine_arn,
        sqs_queue_url,
    )

    # ------------------------------------------------------------------
    # 2. Guard: skip if a Step Function execution is already running.
    #    The SQS message is left untouched so it is picked up next tick.
    # ------------------------------------------------------------------
    if _is_step_function_running(state_machine_arn):
        logger.info(
            "An execution is already RUNNING -- "
            "leaving the SQS message in the queue for the next invocation."
        )
        return {"status": "SKIPPED", "reason": "Step Function already running"}

    # ------------------------------------------------------------------
    # 3. Dequeue exactly one message
    # ------------------------------------------------------------------
    message = _receive_one_message(sqs_queue_url)

    if message is None:
        logger.info("SQS queue is empty -- nothing to do.")
        return {"status": "SKIPPED", "reason": "SQS queue is empty"}

    message_id: str = message["MessageId"]
    receipt_handle: str = message["ReceiptHandle"]

    # ------------------------------------------------------------------
    # 4. Build the Step Function input
    #    The SQS message body is expected to be valid JSON
    # ------------------------------------------------------------------
    # The SQS message body is expected to be a raw JSON of an S3 event notification
    body = json.loads(message["Body"])
    try:
        # Extract the S3 event data to match the expected input format of the Step Function state machine.
        sfn_input: str = message["Body"]
        # Generate a run name based on the object key and eTag
        run_name = f"{body['object']['key']}_{body['object']['etag']}"
    except KeyError:
        logger.warning("SQS message body does not contain required keys.")
        return {
            "status": "FAILED",
            "reason": "SQS message body does not contain required keys",
        }

    logger.info(
        "Starting Step Function execution | stateMachineArn=%s  executionName=%s",
        state_machine_arn,
        run_name,
    )

    # ------------------------------------------------------------------
    # 5. Start the Step Function execution.
    #    name=MessageId serves as an idempotency key: SQS MessageIds are
    #    UUIDs and satisfy Step Functions naming constraints.
    # ------------------------------------------------------------------
    try:
        sfn_response = _sfn_client.start_execution(
            stateMachineArn=state_machine_arn,
            name=run_name,
            input=sfn_input,
        )
    except ClientError as exc:
        error_code: str = exc.response["Error"]["Code"]

        if error_code == "ExecutionAlreadyExists":
            # SQS delivered the same message twice.  The execution already
            # exists; delete the duplicate and return a graceful SKIPPED.
            logger.info(
                "ExecutionAlreadyExists for executionName=%s -- "
                "duplicate SQS delivery detected.  Deleting duplicate message.",
                message_id,
            )
            _delete_sqs_message(sqs_queue_url, receipt_handle, message_id)
            return {
                "status": "SKIPPED",
                "reason": "Execution already exists (duplicate message)",
                "messageId": message_id,
            }

        # Any other error: leave the message in the queue for a natural retry.
        logger.error(
            "start_execution failed (code=%s) for messageId=%s.  "
            "Message left in queue for retry.",
            error_code,
            message_id,
            exc_info=True,
        )
        raise

    execution_arn: str = sfn_response["executionArn"]
    logger.info(
        "Step Function execution started | executionArn=%s  messageId=%s",
        execution_arn,
        message_id,
    )

    # ------------------------------------------------------------------
    # 6. Delete the SQS message (best-effort; logs warning on failure).
    # ------------------------------------------------------------------
    _delete_sqs_message(sqs_queue_url, receipt_handle, message_id)

    return {
        "status": "STARTED",
        "executionArn": execution_arn,
        "messageId": message_id,
    }
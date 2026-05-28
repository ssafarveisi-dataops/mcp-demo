# /// script
# requires-python = ">=3.14"
# dependencies = [
#     "boto3>=1.42.97",
# ]
# ///

"""invoke_agentcore_runtime.py
------------------
AWS Lambda function that wraps AWS Bedrock AgentCore Runtime invocations.

Purpose
-------
This Lambda function provides a wrapper around the Bedrock AgentCore Runtime
API to avoid the 60-second HTTP timeout limitation in Step Functions when
calling the service directly via the SDK integration. By invoking the agent
through Lambda, we can support execution times up to 900 seconds (15 minutes).

Behaviour
---------
1. Read AGENT_RUNTIME_ARN from environment variables.
2. Extract Payload from the event.
3. Extract RuntimeSessionId from the Payload (using request_id field).
4. Call bedrock-agentcore:invoke_agent_runtime with these parameters.
5. Return the response from the AgentCore invocation directly.

Note: Retries and session management are handled at the Step Functions level.

Required event structure
------------------------
{
  "Payload": {
    "request_id": "unique-session-id",
    ...other payload fields...
  }
}

Required environment variables
-------------------------------
AGENT_RUNTIME_ARN -- ARN of the Bedrock AgentCore Runtime to invoke.

Returns
-------
{
  "Response": { ...structured JSON from agent... }
}

Required IAM permissions
------------------------
- bedrock-agentcore:InvokeAgentRuntime
- logs:CreateLogGroup
- logs:CreateLogStream
- logs:PutLogEvents
"""

from __future__ import annotations

import json
import logging
import os
from typing import Any

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# ---------------------------------------------------------------------------
# AWS clients (module-level so they are reused across Lambda warm starts)
# ---------------------------------------------------------------------------
config = Config(
    read_timeout=900,
    connect_timeout=900,
    retries={"max_attempts": 0},
)
_bedrock_client = boto3.client("bedrock-agentcore", config=config)


# ---------------------------------------------------------------------------
# Lambda handler
# ---------------------------------------------------------------------------


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """
    AWS Lambda entry-point for invoking Bedrock AgentCore Runtime.

    This handler wraps calls to the Bedrock AgentCore Runtime API, allowing
    Step Functions to invoke agents with execution times up to 900 seconds
    without hitting HTTP timeout limitations.

    The Lambda simply passes the payload through to the agent and returns
    the response. Session management (stopping sessions) is handled by the
    Step Functions workflow.

    Parameters
    ----------
    event:
        Lambda event containing:
        - Payload: Full payload containing request_id and other data
    context:
        Lambda context object (provides runtime information).

    Returns
    -------
    dict
        Response from the agent (passed through directly):
        - Response: Structured JSON object with the agent's response

    Raises
    ------
    ValueError
        If required fields are missing from the event or environment.
    ClientError
        If the AgentCore invocation fails.
    """
    # ------------------------------------------------------------------
    # 1. Extract required parameters from environment and event
    # ------------------------------------------------------------------
    try:
        agent_runtime_arn: str = os.environ["AGENT_RUNTIME_ARN"]
    except KeyError:
        logger.error("Missing required environment variable: AGENT_RUNTIME_ARN")
        raise ValueError("Missing required environment variable: AGENT_RUNTIME_ARN")

    try:
        payload: dict[str, Any] = event["Payload"]
        runtime_session_id: str = payload["id"]
    except KeyError as exc:
        logger.error(
            "Missing required field in event | MissingField=%s Event=%s",
            str(exc),
            json.dumps(event, default=str),
            exc_info=True,
        )
        raise ValueError(f"Missing required field in event: {exc}") from exc

    logger.info(
        "Lambda invoked | AgentRuntimeArn=%s RuntimeSessionId=%s RemainingTimeMs=%d",
        agent_runtime_arn,
        runtime_session_id,
        context.get_remaining_time_in_millis(),
    )

    # ------------------------------------------------------------------
    # 2. Invoke the agent
    # ------------------------------------------------------------------
    try:
        logger.info(
            "Invoking agent runtime | AgentRuntimeArn=%s RuntimeSessionId=%s",
            agent_runtime_arn,
            runtime_session_id,
        )

        response = _bedrock_client.invoke_agent_runtime(
            agentRuntimeArn=agent_runtime_arn,
            runtimeSessionId=runtime_session_id,
            payload=json.dumps(payload),
        )

        logger.info(
            "Agent runtime invocation succeeded | RuntimeSessionId=%s",
            runtime_session_id,
        )

    except ClientError as exc:
        error_code = exc.response.get("Error", {}).get("Code", "Unknown")
        error_message = exc.response.get("Error", {}).get("Message", "")
        logger.error(
            "Failed to invoke agent runtime | ErrorCode=%s ErrorMessage=%s "
            "RuntimeSessionId=%s",
            error_code,
            error_message,
            runtime_session_id,
            exc_info=True,
        )
        # Re-raise the error so Step Functions can handle the retry
        raise

    # ------------------------------------------------------------------
    # 3. Return the response directly (pass-through)
    # ------------------------------------------------------------------
    # The response from invoke_agent_runtime contains structured JSON.
    # We pass it through directly - Step Functions will handle session cleanup.
    logger.info(
        "Agent runtime invocation completed | RuntimeSessionId=%s",
        runtime_session_id,
    )

    # Return the full response from the agent
    json_response = json.loads(response["response"].read())

    return json_response

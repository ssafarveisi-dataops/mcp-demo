{
  "Comment": "Trigger Glue job and then start Metaflow training",
  "StartAt": "GlueJob",
  "States": {
    "GlueJob": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "${glue_job_name}",
        "Arguments": {
          "--bucket.$": "$.bucket.name",
          "--key.$": "$.object.key"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Glue.AWSGlueException",
            "Glue.ResourceNumberLimitExceededException",
            "States.TaskFailed"
          ],
          "IntervalSeconds": 10,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "GlueJobFailed"
        }
      ],
      "ResultPath": "$.glueResult",
      "Next": "PrepareTrainingInput"
    },

    "GlueJobFailed": {
      "Type": "Pass",
      "Parameters": {
        "status": "FAILED",
        "stage": "GlueJob",
        "error.$": "$.error"
      },
      "End": true
    },

    "PrepareTrainingInput": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "arn:aws:lambda:eu-west-1:463470983643:function:construct-metaflow-input",
        "Payload.$": "$"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 5,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "PrepareTrainingInputFailed"
        }
      ],
      "ResultSelector": {
        "bucket.$": "$.Payload.bucket",
        "prefix.$": "$.Payload.prefix",
        "state_machine_name.$": "$.Payload.state_machine_name"
      },
      "ResultPath": "$.TrainingInput",
      "Next": "MetaflowTraining"
    },

    "PrepareTrainingInputFailed": {
      "Type": "Pass",
      "Parameters": {
        "status": "FAILED",
        "stage": "PrepareTrainingInput",
        "error.$": "$.error"
      },
      "End": true
    },

    "MetaflowTraining": {
      "Type": "Task",
      "Resource": "arn:aws:states:::states:startExecution.sync",
      "Parameters": {
        "StateMachineArn.$": "States.Format('arn:aws:states:eu-west-1:463470983643:stateMachine:{}', $.TrainingInput.state_machine_name)",
        "Input": {
          "Parameters.$": "States.Format('\\{\"bucket\":\"{}\",\"prefix\":\"{}\"\\}', $.TrainingInput.bucket, $.TrainingInput.prefix)",
          "AWS_STEP_FUNCTIONS_STARTED_BY_EXECUTION_ID.$": "$$.Execution.Id"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "StepFunctions.ExecutionLimitExceeded",
            "StepFunctions.AWSStepFunctionsException",
            "States.TaskFailed"
          ],
          "IntervalSeconds": 10,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "MetaflowTrainingFailed"
        }
      ],
      "End": true
    },

    "MetaflowTrainingFailed": {
      "Type": "Pass",
      "Parameters": {
        "status": "FAILED",
        "stage": "MetaflowTraining",
        "error.$": "$.error"
      },
      "End": true
    }
  }
}

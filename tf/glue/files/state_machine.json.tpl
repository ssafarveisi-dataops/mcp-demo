{
  "Comment": "Trigger Glue job with partition info",
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
      "Catch": [
        {
          "ErrorEquals": ["States.TaskFailed"],
          "ResultPath": "$.error",
          "Next": "CheckGlueJobStatus"
        }
      ],
      "ResultPath": "$.taskResult",
      "Next": "CheckGlueJobStatus"
    },
    "CheckGlueJobStatus": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.error",
          "IsPresent": true,
          "Next": "PrintErrorMessage"
        }
      ],
        "Default": "PrepareTrainingInput"
    },
    "PrintErrorMessage": {
      "Type": "Pass",
      "Result": {
        "status": "FAILED"
      },
      "ResultPath": "$.message",
      "End": true
    },
    "PrepareTrainingInput": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "arn:aws:lambda:eu-west-1:463470983643:function:construct-metaflow-input",
        "Payload.$": "$"
      },
      "ResultSelector": {
        "bucket.$": "$.Payload.bucket",
        "prefix.$": "$.Payload.prefix",
        "state_machine_name.$": "$.Payload.state_machine_name"
      },
      "ResultPath": "$.TrainingInput",
      "Next": "MetaflowTraining"
    },
    "MetaflowTraining": {
      "Type": "Task",
      "Resource": "arn:aws:states:::states:startExecution.sync",
      "Parameters": {
        "Input": {
          "Parameters.$": "States.Format('\\{\"bucket\":\"{}\",\"prefix\":\"{}\"\\}', $.TrainingInput.bucket, $.TrainingInput.prefix)",
          "AWS_STEP_FUNCTIONS_STARTED_BY_EXECUTION_ID": "{% $states.context.Execution.Id %}"
        },
        "StateMachineArn.$": "States.Format('arn:aws:states:eu-west-1:463470983643:stateMachine:{}', $.TrainingInput.state_machine_name)"
      },
      "End": true
    }
  }
}

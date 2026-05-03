{
  "Comment": "Trigger Glue job with partition info",
  "StartAt": "StartGlueJob",
  "States": {
    "StartGlueJob": {
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
        "Default": "PrintSuccessMessage"
    },
    "PrintSuccessMessage": {
      "Type": "Pass",
      "Result": {
        "status": "SUCCEEDED"
      },
      "ResultPath": "$.message",
      "End": true
    },
    "PrintErrorMessage": {
      "Type": "Pass",
      "Result": {
        "status": "FAILED"
      },
      "ResultPath": "$.message",
      "End": true
    }
  }
}
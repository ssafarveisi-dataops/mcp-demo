{
  "Comment": "Demo Step Function",
  "StartAt": "ProcessData",
  "States": {
    "ProcessData": {
      "Type": "Map",
      "ItemReader": {
        "Resource": "arn:aws:states:::s3:getObject",
        "ReaderConfig": {
          "InputType": "JSONL"
        },
        "Parameters": {
          "Bucket.$": "$.InputS3Bucket",
          "Key.$": "$.InputS3Key"
        }
      },
      "MaxConcurrency": ${max_concurrency},
      "ToleratedFailurePercentage": 25,
      "Label": "ProcessJSONL",
      "ItemProcessor": {
        "ProcessorConfig": {
          "Mode": "DISTRIBUTED",
          "ExecutionType": "STANDARD"
        },
        "StartAt": "InvokeAgentRuntime",
        "States": {
          "InvokeAgentRuntime": {
            "Type": "Task",
            "Resource": "arn:aws:states:::lambda:invoke",
            "Parameters": {
              "FunctionName": "arn:aws:lambda:eu-west-1:463470983643:function:demo-step-functions-invoke-agent",
              "Payload": {
                "Payload.$": "$"
              }
            },
            "ResultSelector": {
              "Response.$": "$.Payload"
            },
            "OutputPath": "$.Response",
            "Retry": [
              {
                "ErrorEquals": ["States.ALL"],
                "BackoffRate": 2,
                "IntervalSeconds": 2,
                "MaxAttempts": 3,
                "JitterStrategy": "FULL"
              }
            ],
            "Catch": [
              {
                "ErrorEquals": ["States.ALL"],
                "ResultPath": "$.ErrorInfo",
                "Next": "StopSessionFailed"
              }
            ],
            "TimeoutSeconds": 900,
            "HeartbeatSeconds": 900,
            "Next": "StopSessionSuccess"
          },
          "StopSessionSuccess": {
            "Type": "Task",
            "Resource": "arn:aws:states:::aws-sdk:bedrockagentcore:stopRuntimeSession",
            "Parameters": {
              "AgentRuntimeArn": "arn:aws:bedrock-agentcore:eu-west-1:463470983643:runtime/strands_agent-ZicWM58L42",
              "RuntimeSessionId.$": "$.id"
            },
            "ResultPath": null,
            "End": true
          },
          "StopSessionFailed": {
            "Type": "Task",
            "Resource": "arn:aws:states:::aws-sdk:bedrockagentcore:stopRuntimeSession",
            "Parameters": {
              "AgentRuntimeArn": "arn:aws:bedrock-agentcore:eu-west-1:463470983643:runtime/strands_agent-ZicWM58L42",
              "RuntimeSessionId.$": "$.id"
            },
            "ResultPath": "$.StopResult",
            "Next": "FailItem"
          },
          "FailItem": {
            "Type": "Fail",
            "Cause": "Agent invocation failed after retries.",
            "Error": "AgentInvocationFailed"
          }
        }
      },
      "ResultWriter": {
        "Resource": "arn:aws:states:::s3:putObject",
        "Parameters": {
          "Bucket.$": "$.OutputS3Bucket",
          "Prefix.$": "$.OutputS3Prefix"
        },
        "WriterConfig": {
          "OutputType": "JSONL",
          "Transformation": "COMPACT"
        }
      },
      "ResultPath": "$.MapResult",
      "Next": "WriteDoneFile"
    },
    "WriteDoneFile": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:s3:putObject",
      "Parameters": {
        "Bucket.$": "$.OutputS3Bucket",
        "Key.$": "States.Format('{}/{}/.DONE', $.OutputS3Prefix, States.ArrayGetItem(States.StringSplit($.MapResult.MapRunArn, ':'), 7))",
        "Body": ""
      },
      "End": true
    }
  }
}

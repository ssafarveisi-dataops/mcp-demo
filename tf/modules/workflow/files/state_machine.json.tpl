{
  "Comment": "Demo Step Function",
  "StartAt": "ExtractMessage",
  "States": {
    "ExtractMessage": {
      "Type": "Pass",
      "Parameters": {
        "message.$": "$[0]"
      },
      "ResultPath": "$",
      "Next": "ParseBody"
    },
    "ParseBody": {
      "Type": "Pass",
      "Parameters": {
        "parsed.$": "States.StringToJson($.message.body)"
      },
      "ResultPath": "$",
      "Next": "ValidateInput"
    },
    "ValidateInput": {
      "Type": "Choice",
      "Choices": [
        {
          "And": [
            {
              "Variable": "$.parsed.Records[0].s3.bucket.name",
              "IsPresent": true
            },
            {
              "Variable": "$.parsed.Records[0].s3.object.key",
              "IsPresent": true
            }
          ],
          "Next": "ProcessData"
        }
      ],
      "Default": "SkipExecution"
    },
    "SkipExecution": {
      "Type": "Succeed"
    },
    "ProcessData": {
      "Type": "Map",
      "ItemReader": {
        "Resource": "arn:aws:states:::s3:getObject",
        "ReaderConfig": {
          "InputType": "JSONL"
        },
        "Parameters": {
          "Bucket.$": "$.parsed.Records[0].s3.bucket.name",
          "Key.$": "$.parsed.Records[0].s3.object.key"
        }
      },
      "MaxConcurrency": ${max_concurrency},
      "ToleratedFailurePercentage": 5,
      "ItemProcessor": {
        "ProcessorConfig": {
          "Mode": "DISTRIBUTED",
          "ExecutionType": "STANDARD"
        },
        "StartAt": "InvokeAgentRuntime",
        "States": {
          "InvokeAgentRuntime": {
            "Type": "Task",
            "Parameters": {
              "AgentRuntimeArn": "arn:aws:bedrock-agentcore:eu-west-1:463470983643:runtime/strands_agent-ZicWM58L42",
              "Payload.$": "$",
              "RuntimeSessionId.$": "$.id"
            },
            "Resource": "arn:aws:states:::aws-sdk:bedrockagentcore:invokeAgentRuntime",
            "TimeoutSeconds": 900,
            "Retry": [
              {
                "ErrorEquals": ["States.ALL"],
                "BackoffRate": 2,
                "IntervalSeconds": 1,
                "MaxAttempts": 3,
                "JitterStrategy": "FULL"
              }
            ],
            "Catch": [
              {
                "ErrorEquals": ["States.ALL"],
                "ResultPath": "$.bedrockRuntimeError",
                "Next": "StopRuntimeSession"
              }
            ],
            "ResultPath": "$.bedrockRuntimeResult",
            "Next": "StopRuntimeSession"
          },
          "StopRuntimeSession": {
            "Type": "Task",
            "Parameters": {
              "AgentRuntimeArn": "arn:aws:bedrock-agentcore:eu-west-1:463470983643:runtime/strands_agent-ZicWM58L42",
              "RuntimeSessionId.$": "$.id",
              "Qualifier": "DEFAULT"
            },
            "Resource": "arn:aws:states:::aws-sdk:bedrockagentcore:stopRuntimeSession",
            "ResultPath": "$.stopRuntimeResult",
            "Next": "CheckInvokeStatus",
            "TimeoutSeconds": 60,
            "Retry": [
              {
                "ErrorEquals": [
                  "States.ALL"
                ],
                "BackoffRate": 2,
                "IntervalSeconds": 1,
                "MaxAttempts": 3,
                "JitterStrategy": "FULL"
              }
            ]
          },
          "CheckInvokeStatus": {
            "Type": "Choice",
            "Choices": [
              {
                "Variable": "$.bedrockRuntimeError",
                "IsPresent": true,
                "Next": "FailAfterCleanup"
              }
            ],
            "Default": "ParseResponse"
          },
          "FailAfterCleanup": {
            "Type": "Fail",
            "ErrorPath": "$.bedrockRuntimeError.Error",
            "CausePath": "$.bedrockRuntimeError.Cause"
          },
          "ParseResponse": {
            "Type": "Pass",
            "Parameters": {
              "parsed.$": "States.StringToJson($.bedrockRuntimeResult.Response)",
              "stopRuntimeResult.$": "$.stopRuntimeResult"
            },
            "End": true
          }
        }
      },
      "ResultWriter": {
        "Resource": "arn:aws:states:::s3:putObject",
        "Parameters": {
          "Bucket": "${output_bucket}",
          "Prefix": "results/"
        },
        "WriterConfig": {
          "OutputType": "JSONL",
          "Transformation": "COMPACT"
        }
      },
      "End": true
    }
  }
}
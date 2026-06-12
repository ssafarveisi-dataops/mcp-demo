<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_arbitrary_s3_bucket_name"></a> [arbitrary\_s3\_bucket\_name](#input\_arbitrary\_s3\_bucket\_name) | Name of the S3 bucket where the raw data for the Metaflow workflow exists | `string` | `"demo-data-lake-glue-etl"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"eu-west-1"` | no |
| <a name="input_batch_instance_types"></a> [batch\_instance\_types](#input\_batch\_instance\_types) | EC2 instance types to use for AWS batch jobs | `list(string)` | <pre>[<br/>  "c4.large",<br/>  "c4.xlarge",<br/>  "g4dn.xlarge",<br/>  "g4dn.2xlarge"<br/>]</pre> | no |
| <a name="input_batch_max_vcpu"></a> [batch\_max\_vcpu](#input\_batch\_max\_vcpu) | maximum number of vCPUs to use on a batch job; defaults to 32 | `string` | `32` | no |
| <a name="input_batch_min_vcpu"></a> [batch\_min\_vcpu](#input\_batch\_min\_vcpu) | minimum number of vCPUs to use on a batch job; defaults to 2 | `string` | `2` | no |
| <a name="input_batch_queue_name"></a> [batch\_queue\_name](#input\_batch\_queue\_name) | Name of AWS batch queue | `string` | `"metaflow"` | no |
| <a name="input_batch_security_group_name"></a> [batch\_security\_group\_name](#input\_batch\_security\_group\_name) | Name of the security group used for tasks in the AWS batch compute environment | `string` | `"metaflow_batch_compute_security_group"` | no |
| <a name="input_batch_service_role_name"></a> [batch\_service\_role\_name](#input\_batch\_service\_role\_name) | Name of the AWS batch service IAM role | `string` | `"aws_batch_service_role"` | no |
| <a name="input_bid_percentage"></a> [bid\_percentage](#input\_bid\_percentage) | Spot bid percentage for AWS Batch compute | `string` | `"100"` | no |
| <a name="input_dynamodb_name"></a> [dynamodb\_name](#input\_dynamodb\_name) | name of the AWS Dynamo DB | `string` | `"metaflow"` | no |
| <a name="input_ecs_instance_role_name"></a> [ecs\_instance\_role\_name](#input\_ecs\_instance\_role\_name) | Name of the ECS IAM instance role | `string` | `"metaflow_ecs_instance_role"` | no |
| <a name="input_eventbridge_role_name"></a> [eventbridge\_role\_name](#input\_eventbridge\_role\_name) | name of the eventbridge role | `string` | `"metaflow_eventbridge_role"` | no |
| <a name="input_metaflow_iam_role_name"></a> [metaflow\_iam\_role\_name](#input\_metaflow\_iam\_role\_name) | Name of the metaflow IAM role that allows interacting with S3, ECR, etc. | `string` | `"metaflow_iam_role"` | no |
| <a name="input_step_functions_role_name"></a> [step\_functions\_role\_name](#input\_step\_functions\_role\_name) | name of the step function role | `string` | `"metaflow_step_functions_role"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_METAFLOW_DEFAULT_METADATA"></a> [METAFLOW\_DEFAULT\_METADATA](#output\_METAFLOW\_DEFAULT\_METADATA) | Default metadata provider for Metaflow. This is used by the Metaflow client to determine which metadata provider to use if one is not explicitly specified in the code. |
| <a name="output_METAFLOW_SERVICE_INTERNAL_URL"></a> [METAFLOW\_SERVICE\_INTERNAL\_URL](#output\_METAFLOW\_SERVICE\_INTERNAL\_URL) | URL for Metadata Service (Accessible in VPC) |
| <a name="output_METAFLOW_SERVICE_URL"></a> [METAFLOW\_SERVICE\_URL](#output\_METAFLOW\_SERVICE\_URL) | URL for Metadata Service (Open to Public Access) |
| <a name="output_database_password"></a> [database\_password](#output\_database\_password) | The database password |
| <a name="output_metaflow_datastore_bucket_name"></a> [metaflow\_datastore\_bucket\_name](#output\_metaflow\_datastore\_bucket\_name) | Name of the bucket where we store metaflow data |
| <a name="output_metaflow_eventbridge_role_arn"></a> [metaflow\_eventbridge\_role\_arn](#output\_metaflow\_eventbridge\_role\_arn) | IAM role for Amazon EventBridge to access AWS Step Functions. |
| <a name="output_metaflow_step_functions_dynamodb_policy"></a> [metaflow\_step\_functions\_dynamodb\_policy](#output\_metaflow\_step\_functions\_dynamodb\_policy) | Policy json allowing access to the step functions dynamodb table. |
| <a name="output_metaflow_step_functions_dynamodb_table_arn"></a> [metaflow\_step\_functions\_dynamodb\_table\_arn](#output\_metaflow\_step\_functions\_dynamodb\_table\_arn) | AWS DynamoDB table arn for tracking AWS Step Functions execution metadata. |
| <a name="output_metaflow_step_functions_dynamodb_table_name"></a> [metaflow\_step\_functions\_dynamodb\_table\_name](#output\_metaflow\_step\_functions\_dynamodb\_table\_name) | AWS DynamoDB table name for tracking AWS Step Functions execution metadata. |
| <a name="output_metaflow_step_functions_role_arn"></a> [metaflow\_step\_functions\_role\_arn](#output\_metaflow\_step\_functions\_role\_arn) | IAM role for AWS Step Functions to access AWS resources (AWS Batch, AWS DynamoDB). |
| <a name="output_migration_function_arn"></a> [migration\_function\_arn](#output\_migration\_function\_arn) | ARN of DB Migration Function |
| <a name="output_network_load_balancer_dns_name"></a> [network\_load\_balancer\_dns\_name](#output\_network\_load\_balancer\_dns\_name) | The DNS addressable name for the Network Load Balancer that accepts requests and forwards them to our Fargate MetaData service instance(s) |
| <a name="output_rds_master_instance_endpoint"></a> [rds\_master\_instance\_endpoint](#output\_rds\_master\_instance\_endpoint) | The database connection endpoint in address:port format |
<!-- END_TF_DOCS -->

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cidr_blocks"></a> [cidr\_blocks](#input\_cidr\_blocks) | CIDR blocks to be set in SG ingress rules | `list(string)` | n/a | yes |
| <a name="input_ecs_execution_role_arn"></a> [ecs\_execution\_role\_arn](#input\_ecs\_execution\_role\_arn) | ARN for the ECS execution role | `string` | n/a | yes |
| <a name="input_ecs_task_role_arn"></a> [ecs\_task\_role\_arn](#input\_ecs\_task\_role\_arn) | ARN for the ECS task role | `string` | n/a | yes |
| <a name="input_metadata_service_rds_db_name"></a> [metadata\_service\_rds\_db\_name](#input\_metadata\_service\_rds\_db\_name) | Name for the metadata service RDS's db name | `string` | `"metaflow"` | no |
| <a name="input_metadata_service_rds_username"></a> [metadata\_service\_rds\_username](#input\_metadata\_service\_rds\_username) | Username for the metadata service RDS | `string` | `"metaflow"` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | List of private subnets where the load balancer is deployed | `list(string)` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix for all resource names | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID for the VPC where the resources are deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_METAFLOW_SERVICE_INTERNAL_URL"></a> [METAFLOW\_SERVICE\_INTERNAL\_URL](#output\_METAFLOW\_SERVICE\_INTERNAL\_URL) | URL for Metadata Service (Accessible in VPC) |
| <a name="output_METAFLOW_SERVICE_URL"></a> [METAFLOW\_SERVICE\_URL](#output\_METAFLOW\_SERVICE\_URL) | URL for Metadata Service (Open to Public Access) |
| <a name="output_metadata_service_rds_db_name"></a> [metadata\_service\_rds\_db\_name](#output\_metadata\_service\_rds\_db\_name) | n/a |
| <a name="output_metadata_service_rds_endpoint"></a> [metadata\_service\_rds\_endpoint](#output\_metadata\_service\_rds\_endpoint) | n/a |
| <a name="output_metadata_service_rds_password"></a> [metadata\_service\_rds\_password](#output\_metadata\_service\_rds\_password) | n/a |
| <a name="output_metadata_service_rds_username"></a> [metadata\_service\_rds\_username](#output\_metadata\_service\_rds\_username) | n/a |
| <a name="output_metadata_service_sg_id"></a> [metadata\_service\_sg\_id](#output\_metadata\_service\_sg\_id) | n/a |
| <a name="output_migration_function_arn"></a> [migration\_function\_arn](#output\_migration\_function\_arn) | ARN of DB Migration Function |
| <a name="output_network_load_balancer_dns_name"></a> [network\_load\_balancer\_dns\_name](#output\_network\_load\_balancer\_dns\_name) | The DNS addressable name for the Network Load Balancer that accepts requests and forwards them to our Fargate MetaData service instance(s) |
<!-- END_TF_DOCS -->

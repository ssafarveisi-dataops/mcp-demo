<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alb_listener_arn"></a> [alb\_listener\_arn](#input\_alb\_listener\_arn) | ARN for the application load balancer listener | `string` | n/a | yes |
| <a name="input_cidr_blocks"></a> [cidr\_blocks](#input\_cidr\_blocks) | CIDR blocks to be set in SG ingress rules | `list(string)` | n/a | yes |
| <a name="input_ecs_execution_role_arn"></a> [ecs\_execution\_role\_arn](#input\_ecs\_execution\_role\_arn) | ARN for the ECS execution role | `string` | n/a | yes |
| <a name="input_ecs_task_role_arn"></a> [ecs\_task\_role\_arn](#input\_ecs\_task\_role\_arn) | ARN for the ECS task role | `string` | n/a | yes |
| <a name="input_metadata_service_rds_db_name"></a> [metadata\_service\_rds\_db\_name](#input\_metadata\_service\_rds\_db\_name) | The DB name for the metadata service RDS | `string` | n/a | yes |
| <a name="input_metadata_service_rds_endpoint"></a> [metadata\_service\_rds\_endpoint](#input\_metadata\_service\_rds\_endpoint) | Endpoint for the metadata service RDS | `string` | n/a | yes |
| <a name="input_metadata_service_rds_password"></a> [metadata\_service\_rds\_password](#input\_metadata\_service\_rds\_password) | Password for the metadata service RDS | `string` | n/a | yes |
| <a name="input_metadata_service_rds_username"></a> [metadata\_service\_rds\_username](#input\_metadata\_service\_rds\_username) | The username for the metadata service RDS | `string` | n/a | yes |
| <a name="input_metadata_service_sg_id"></a> [metadata\_service\_sg\_id](#input\_metadata\_service\_sg\_id) | ID for the metadata service security group | `string` | n/a | yes |
| <a name="input_metaflow_datastore_root"></a> [metaflow\_datastore\_root](#input\_metaflow\_datastore\_root) | S3 metaflow datastore root. Example: s3://bucket/metaflow | `string` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | List of private subnets where the load balancer is deployed | `list(string)` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix for all resource names | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID for the VPC where the resources are deployed | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

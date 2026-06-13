<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_batch_ecs_instance_profile_arn"></a> [batch\_ecs\_instance\_profile\_arn](#input\_batch\_ecs\_instance\_profile\_arn) | ECS instance profile ARN for batch jobs | `string` | n/a | yes |
| <a name="input_batch_instance_types"></a> [batch\_instance\_types](#input\_batch\_instance\_types) | EC2 instance types to use for AWS batch jobs | `list(string)` | <pre>[<br/>  "c4.large",<br/>  "c4.xlarge",<br/>  "g4dn.xlarge",<br/>  "g4dn.2xlarge"<br/>]</pre> | no |
| <a name="input_batch_max_vcpu"></a> [batch\_max\_vcpu](#input\_batch\_max\_vcpu) | maximum number of vCPUs to use on a batch job; defaults to 32 | `string` | `32` | no |
| <a name="input_batch_min_vcpu"></a> [batch\_min\_vcpu](#input\_batch\_min\_vcpu) | minimum number of vCPUs to use on a batch job; defaults to 2 | `string` | `2` | no |
| <a name="input_batch_service_role_arn"></a> [batch\_service\_role\_arn](#input\_batch\_service\_role\_arn) | ARN for the batch service role | `string` | n/a | yes |
| <a name="input_batch_spot_fleet_role_arn"></a> [batch\_spot\_fleet\_role\_arn](#input\_batch\_spot\_fleet\_role\_arn) | ARN for the spot fleet role | `string` | n/a | yes |
| <a name="input_bid_percentage"></a> [bid\_percentage](#input\_bid\_percentage) | Spot bid percentage for AWS Batch compute | `string` | `"100"` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | List of private subnets where the load balancer is deployed | `list(string)` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix for all resource names | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID for the VPC where the resources are deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_batch_job_queue_name"></a> [batch\_job\_queue\_name](#output\_batch\_job\_queue\_name) | n/a |
<!-- END_TF_DOCS -->

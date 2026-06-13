<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_arbitrary_s3_bucket_name"></a> [arbitrary\_s3\_bucket\_name](#input\_arbitrary\_s3\_bucket\_name) | Name of the S3 bucket where the raw data for the Metaflow workflow exists | `string` | n/a | yes |
| <a name="input_metaflow_s3_datastore_root_bucket_name"></a> [metaflow\_s3\_datastore\_root\_bucket\_name](#input\_metaflow\_s3\_datastore\_root\_bucket\_name) | Name of the S3 bucket where metaflow's artifacts are stored | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_METAFLOW_S3_DATASTORE_ROOT_BUCKET_NAME"></a> [METAFLOW\_S3\_DATASTORE\_ROOT\_BUCKET\_NAME](#output\_METAFLOW\_S3\_DATASTORE\_ROOT\_BUCKET\_NAME) | Making sure the metadata service uses an S3 bucket to which it has access |
| <a name="output_batch_ecs_instance_profile_arn"></a> [batch\_ecs\_instance\_profile\_arn](#output\_batch\_ecs\_instance\_profile\_arn) | n/a |
| <a name="output_batch_service_role_arn"></a> [batch\_service\_role\_arn](#output\_batch\_service\_role\_arn) | n/a |
| <a name="output_batch_spot_fleet_role_arn"></a> [batch\_spot\_fleet\_role\_arn](#output\_batch\_spot\_fleet\_role\_arn) | n/a |
| <a name="output_eventbridge_role_arn"></a> [eventbridge\_role\_arn](#output\_eventbridge\_role\_arn) | n/a |
| <a name="output_metadata_svc_ecs_task_execution_role_arn"></a> [metadata\_svc\_ecs\_task\_execution\_role\_arn](#output\_metadata\_svc\_ecs\_task\_execution\_role\_arn) | n/a |
| <a name="output_metadata_svc_ecs_task_role_arn"></a> [metadata\_svc\_ecs\_task\_role\_arn](#output\_metadata\_svc\_ecs\_task\_role\_arn) | n/a |
| <a name="output_metaflow_access_role_arn"></a> [metaflow\_access\_role\_arn](#output\_metaflow\_access\_role\_arn) | n/a |
| <a name="output_step_functions_role_arn"></a> [step\_functions\_role\_arn](#output\_step\_functions\_role\_arn) | n/a |
<!-- END_TF_DOCS -->

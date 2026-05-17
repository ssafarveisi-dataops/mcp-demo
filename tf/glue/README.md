<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"eu-west-1"` | no |
| <a name="input_data_lake_bucket"></a> [data\_lake\_bucket](#input\_data\_lake\_bucket) | Bucket where the raw events are located | `string` | `"demo-data-lake-glue-etl"` | no |
| <a name="input_source_code_bucket"></a> [source\_code\_bucket](#input\_source\_code\_bucket) | Bucket where the source code the spark ETL application is located | `string` | `"demo-glue-etl-pyspark-scripts"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

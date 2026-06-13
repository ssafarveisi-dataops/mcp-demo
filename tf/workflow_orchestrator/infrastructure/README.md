<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_batch_instance_types"></a> [batch\_instance\_types](#input\_batch\_instance\_types) | EC2 instance types to use for AWS batch jobs | `list(string)` | <pre>[<br/>  "c4.large",<br/>  "c4.xlarge",<br/>  "g4dn.xlarge",<br/>  "g4dn.2xlarge"<br/>]</pre> | no |
| <a name="input_batch_max_vcpu"></a> [batch\_max\_vcpu](#input\_batch\_max\_vcpu) | maximum number of vCPUs to use on a batch job; defaults to 32 | `string` | `32` | no |
| <a name="input_batch_min_vcpu"></a> [batch\_min\_vcpu](#input\_batch\_min\_vcpu) | minimum number of vCPUs to use on a batch job; defaults to 2 | `string` | `2` | no |
| <a name="input_bid_percentage"></a> [bid\_percentage](#input\_bid\_percentage) | Spot bid percentage for AWS Batch compute | `string` | `"100"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

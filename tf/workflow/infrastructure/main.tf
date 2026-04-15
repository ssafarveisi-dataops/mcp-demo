module "buckets" {
  source          = "../../modules/buckets"
  resource_prefix = local.resource_prefix
}

module "workflow" {
  source             = "../../modules/workflow"
  resource_prefix    = local.resource_prefix
  role_arn           = data.terraform_remote_state.iam.outputs.sfn_role_arn
  output_bucket      = module.buckets.output_bucket_name
  execution_role_arn = data.terraform_remote_state.iam.outputs.sfn_role_arn
}

module "triggers" {
  source               = "../../modules/triggers"
  resource_prefix      = local.resource_prefix
  input_bucket_name    = module.buckets.input_bucket_name
  eventbridge_sfn_role = data.terraform_remote_state.iam.outputs.eventbridge_sfn_role_arn
  sfn_workflow_arn     = module.workflow.state_machine_arn
}

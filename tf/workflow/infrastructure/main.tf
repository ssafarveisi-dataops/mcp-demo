module "queue" {
  source                 = "../../modules/queue"
  resource_prefix        = local.resource_prefix
  sqs_eventbridge_policy = data.terraform_remote_state.iam.outputs.sqs_eventbridge_policy
}

module "buckets" {
  source          = "../../modules/buckets"
  resource_prefix = local.resource_prefix
}

module "workflow" {
  source             = "../../modules/workflow"
  resource_prefix    = local.resource_prefix
  output_bucket      = module.buckets.output_bucket_name
  execution_role_arn = data.terraform_remote_state.iam.outputs.sfn_role_arn
}

module "triggers" {
  source               = "../../modules/triggers"
  resource_prefix      = local.resource_prefix
  sqs_queue_url        = module.queue.sqs_queue_url
  state_machine_arn    = module.workflow.state_machine_arn
  lambda_role_arn      = data.terraform_remote_state.iam.outputs.lambda_role_arn
  input_bucket_name    = module.buckets.input_bucket_name
  sqs_queue_arn        = module.queue.sqs_queue_arn
  eventbridge_role_arn = data.terraform_remote_state.iam.outputs.eventbridge_role_arn
}

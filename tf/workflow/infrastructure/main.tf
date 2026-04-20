module "queue" {
  source                     = "../../modules/queue"
  resource_prefix            = local.resource_prefix
  bucket_notification_policy = data.terraform_remote_state.iam.outputs.bucket_notification_policy
}

module "buckets" {
  source          = "../../modules/buckets"
  resource_prefix = local.resource_prefix
  sqs_queue_arn   = module.queue.sqs_queue_arn
}

module "workflow" {
  source             = "../../modules/workflow"
  resource_prefix    = local.resource_prefix
  role_arn           = data.terraform_remote_state.iam.outputs.sfn_role_arn
  output_bucket      = module.buckets.output_bucket_name
  execution_role_arn = data.terraform_remote_state.iam.outputs.sfn_role_arn
}

module "triggers" {
  source          = "../../modules/triggers"
  resource_prefix = local.resource_prefix
  pipe_target_arn = module.workflow.state_machine_arn
  pipe_source_arn = module.queue.sqs_queue_arn
  pipe_role_arn   = data.terraform_remote_state.iam.outputs.pipe_role_arn
}

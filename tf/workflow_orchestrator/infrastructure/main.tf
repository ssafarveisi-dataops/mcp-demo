module "buckets" {
  source = "../modules/buckets"

  metaflow_s3_bucket_name = data.terraform_remote_state.iam.outputs.METAFLOW_S3_DATASTORE_ROOT_BUCKET_NAME
}

module "batch" {
  source = "../modules/batch"

  resource_prefix                = local.resource_prefix
  vpc_id                         = local.vpc_id
  private_subnets                = local.private_subnet_list
  batch_ecs_instance_profile_arn = data.terraform_remote_state.iam.outputs.batch_ecs_instance_profile_arn
  batch_service_role_arn         = data.terraform_remote_state.iam.outputs.batch_service_role_arn
  batch_spot_fleet_role_arn      = data.terraform_remote_state.iam.outputs.batch_spot_fleet_role_arn
}

module "metadata_service" {
  source = "../modules/metadata-service"

  resource_prefix               = local.resource_prefix
  cidr_blocks                   = local.vpc_cidr
  vpc_id                        = local.vpc_id
  private_subnets               = local.private_subnet_list
  ecs_execution_role_arn        = data.terraform_remote_state.iam.outputs.metadata_svc_ecs_task_execution_role_arn
  ecs_task_role_arn             = data.terraform_remote_state.iam.outputs.metadata_svc_ecs_task_role_arn
  metadata_service_rds_db_name  = local.metadata_rds_db_name
  metadata_service_rds_username = local.metadata_rds_username
}

module "ui" {
  source = "../modules/ui"

  resource_prefix               = local.resource_prefix
  vpc_id                        = local.vpc_id
  private_subnets               = local.private_subnet_list
  cidr_blocks                   = local.vpc_cidr
  ecs_execution_role_arn        = data.terraform_remote_state.iam.outputs.metadata_svc_ecs_task_execution_role_arn
  ecs_task_role_arn             = data.terraform_remote_state.iam.outputs.metadata_svc_ecs_task_role_arn
  metadata_service_rds_db_name  = module.metadata_service.metadata_service_rds_db_name
  metadata_service_rds_endpoint = module.metadata_service.metadata_service_rds_endpoint
  metadata_service_rds_password = module.metadata_service.metadata_service_rds_password
  metadata_service_rds_username = module.metadata_service.metadata_service_rds_username
  metaflow_datastore_root       = module.buckets.METAFLOW_DATASTORE_SYSROOT_S3
  metadata_service_sg_id        = module.metadata_service.metadata_service_sg_id
  alb_listener_arn              = data.terraform_remote_state.alb.outputs.alb_listener_arn
}

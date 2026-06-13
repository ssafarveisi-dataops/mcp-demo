output "batch_ecs_instance_profile_arn" {
  value = aws_iam_instance_profile.batch_ecs_instance_profile.arn
}

output "batch_spot_fleet_role_arn" {
  value = aws_iam_role.batch_spot_fleet_role.arn
}

output "batch_service_role_arn" {
  value = aws_iam_role.batch_service_role.arn
}

output "metaflow_access_role_arn" {
  value = aws_iam_role.metaflow_access_role.arn
}

output "eventbridge_role_arn" {
  value = aws_iam_role.eventbridge_role.arn
}

output "step_functions_role_arn" {
  value = aws_iam_role.step_functions_role.arn
}

output "metadata_svc_ecs_task_role_arn" {
  value = aws_iam_role.metadata_svc_ecs_task_role.arn
}

output "metadata_svc_ecs_task_execution_role_arn" {
  value = aws_iam_role.metadata_svc_ecs_task_execution_role.arn
}

# Making sure the metadata service uses an S3 bucket to which it has access
output "METAFLOW_S3_DATASTORE_ROOT_BUCKET_NAME" {
  value = var.metaflow_s3_datastore_root_bucket_name
}

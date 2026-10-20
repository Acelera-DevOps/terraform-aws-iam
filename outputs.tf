output "github_actions_role_arn" {
  description = "ARN of the Keyless GitHub Actions OIDC Deployer IAM Role"
  value       = aws_iam_role.github_actions_deployer.arn
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS Task Execution Role (infrastructure plane)"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the PoLP ECS Application Task Role (workload runtime plane)"
  value       = aws_iam_role.ecs_application_task_role.arn
}

output "permissions_boundary_arn" {
  description = "ARN of the IAM Permissions Boundary policy"
  value       = aws_iam_policy.permissions_boundary.arn
}

output "access_analyzer_arn" {
  description = "ARN of the AWS IAM Access Analyzer"
  value       = try(aws_accessanalyzer_analyzer.this[0].arn, null)
}

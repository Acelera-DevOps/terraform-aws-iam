provider "aws" {
  region = "us-east-1"
}

module "zero_trust_iam" {
  source = "../../"

  project_name                = "acelera-platform"
  environment                 = "production"
  github_org                  = "Acelera-DevOps"
  github_repo                 = "terraform-aws-ecs"
  create_github_oidc_provider = true
  enable_access_analyzer      = true

  tags = {
    SecurityTier = "zero-trust-critical"
    CostCenter   = "platform-security"
  }
}

output "github_actions_role_arn" {
  value = module.zero_trust_iam.github_actions_role_arn
}

output "ecs_execution_role_arn" {
  value = module.zero_trust_iam.ecs_execution_role_arn
}

output "ecs_task_role_arn" {
  value = module.zero_trust_iam.ecs_task_role_arn
}

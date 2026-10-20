variable "project_name" {
  description = "Project or platform identifier used to prefix IAM roles and policies"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, production)"
  type        = string
  default     = "production"
}

variable "github_org" {
  description = "GitHub organization or owner allowed to assume the OIDC deployer role"
  type        = string
  default     = "Acelera-DevOps"
}

variable "github_repo" {
  description = "GitHub repository name allowed to assume the OIDC deployer role (supports '*' or specific repo)"
  type        = string
  default     = "terraform-aws-ecs"
}

variable "create_github_oidc_provider" {
  description = "Whether to create the GitHub Actions OIDC identity provider in AWS IAM"
  type        = bool
  default     = true
}

variable "permissions_boundary_managed_policies" {
  description = "Optional additional managed policy ARNs to reference alongside the custom Permissions Boundary"
  type        = list(string)
  default     = []
}

variable "enable_access_analyzer" {
  description = "Whether to enable AWS IAM Access Analyzer for continuous external access detection"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all IAM roles, policies, and analyzers"
  type        = map(string)
  default     = {}
}

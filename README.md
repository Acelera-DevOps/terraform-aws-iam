# Terraform AWS Zero-Trust IAM & PoLP Reference Architecture

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.6.0-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS_Provider-~%3E5.0-FF9900?logo=amazonaws&logoColor=white)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Zero Trust](https://img.shields.io/badge/Security-Keyless_OIDC_%2B_PoLP-00C853)](./oidc-github.tf)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

Production-ready **Terraform AWS IAM Reference Architecture** implementing **Keyless GitHub Actions OIDC Federation**, strict separation of **ECS Execution vs. Application Task Roles**, **Permissions Boundaries** against privilege escalation, and continuous external access auditing via **AWS IAM Access Analyzer**.

---

## Architecture Overview

```mermaid
flowchart LR
    subgraph GH["GitHub Actions CI/CD"]
        WF["Workflow Run<br/>(repo:Acelera-DevOps/terraform-aws-ecs:*)"]
    end

    subgraph AWS_IAM["AWS IAM Zero-Trust Control Plane"]
        OIDC["IAM OIDC Provider<br/>token.actions.githubusercontent.com"]
        PB["Permissions Boundary<br/>(Blocks IAM Escalation & Audit Tampering)"]
        DEPLOY_ROLE["GitHub Deployer Role<br/>(Short-Lived STS Token ≤ 1h)"]
        EXEC_ROLE["ECS Task Execution Role<br/>(ECR Pull + CloudWatch Logs)"]
        TASK_ROLE["ECS Application Task Role<br/>(Scoped SSM / Secrets / S3 + Confused Deputy Guard)"]
        AA["IAM Access Analyzer<br/>(Continuous External Access Detection)"]
    end

    WF -- "1. OIDC JWT (aud=sts.amazonaws.com)" --> OIDC
    OIDC -- "2. AssumeRoleWithWebIdentity" --> DEPLOY_ROLE
    DEPLOY_ROLE -- "3. iam:PassRole (ecs-tasks only)" --> EXEC_ROLE & TASK_ROLE
    PB -. "Enforces Maximum Privilege Ceiling" .-> DEPLOY_ROLE & EXEC_ROLE & TASK_ROLE
    AA -. "Audits Resource Policies" .-> AWS_IAM
```

---

## Security Controls Matrix

| Control Domain | Implementation (`terraform-aws-iam`) | Threat Mitigated |
|----------------|--------------------------------------|------------------|
| **Keyless CI/CD Federation** | `aws_iam_openid_connect_provider` + `StringEquals` (`aud`) & `StringLike` (`sub`) conditions in [`oidc-github.tf`](./oidc-github.tf) | Eliminates long-lived `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` leakage in CI/CD |
| **Execution vs. Task Plane Split** | Separate `ecs_task_execution_role` and `ecs_application_task_role` in [`ecs-roles.tf`](./ecs-roles.tf) | Prevents application code RCE from accessing cluster-wide ECR or infrastructure privileges |
| **Cross-Service Confused Deputy Guard** | `aws:SourceAccount` and `aws:SourceArn` conditions on ECS Task Role trust policy | Prevents external or unauthorized ECS services from assuming the workload's Task Role |
| **Permissions Boundary Guardrails** | `aws_iam_policy.permissions_boundary` attached to all roles in [`permissions-boundary.tf`](./permissions-boundary.tf) | Blocks `iam:CreateUser`, `iam:CreateAccessKey`, boundary removal, and `cloudtrail:StopLogging` / `guardduty:DeleteDetector` |
| **Scoped `iam:PassRole`** | Restricted to exact ECS role ARNs + `iam:PassedToService = ecs-tasks.amazonaws.com` | Prevents CI/CD pipelines from passing administrative roles to arbitrary AWS services |
| **Continuous Policy Verification** | `aws_accessanalyzer_analyzer` (`ACCOUNT` scope) in [`access-analyzer.tf`](./access-analyzer.tf) | Automatically flags unintended external access to IAM roles, S3 buckets, or KMS keys |

---

## Quick Start

```hcl
module "iam_zero_trust" {
  source = "git::https://github.com/Acelera-DevOps/terraform-aws-iam.git?ref=main"

  project_name                = "acelera-platform"
  environment                 = "production"
  github_org                  = "Acelera-DevOps"
  github_repo                 = "terraform-aws-ecs"
  create_github_oidc_provider = true
  enable_access_analyzer      = true

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### Using the OIDC Role in GitHub Actions

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - name: Configure AWS Credentials (Keyless OIDC)
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789012:role/acelera-platform-production-github-actions-deployer
      aws-region: us-east-1
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_name` | Project or platform identifier prefix | `string` | n/a | yes |
| `environment` | Deployment environment (`dev`, `staging`, `production`) | `string` | `"production"` | no |
| `github_org` | GitHub organization allowed to assume OIDC role | `string` | `"Acelera-DevOps"` | no |
| `github_repo` | GitHub repository allowed to assume OIDC role | `string` | `"terraform-aws-ecs"` | no |
| `create_github_oidc_provider` | Create the GitHub OIDC provider resource | `bool` | `true` | no |
| `permissions_boundary_managed_policies` | Optional additional managed policy ARNs | `list(string)` | `[]` | no |
| `enable_access_analyzer` | Provision AWS IAM Access Analyzer | `bool` | `true` | no |
| `tags` | Common tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `github_actions_role_arn` | ARN of the Keyless GitHub Actions OIDC Deployer IAM Role |
| `ecs_execution_role_arn` | ARN of the ECS Task Execution Role |
| `ecs_task_role_arn` | ARN of the PoLP ECS Application Task Role |
| `permissions_boundary_arn` | ARN of the IAM Permissions Boundary policy |
| `access_analyzer_arn` | ARN of the AWS IAM Access Analyzer |

---

## Author

**Erik Tonon** — Cloud & Platform Architect / SRE  
Website: [eriktonon.com](https://eriktonon.com)

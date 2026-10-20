# =============================================================================
# 3. IAM Permissions Boundary (Privilege Escalation & Security Guardrails)
# =============================================================================

resource "aws_iam_policy" "permissions_boundary" {
  name        = "${local.name_prefix}-permissions-boundary"
  description = "Permissions Boundary preventing IAM privilege escalation, boundary detachment, and security audit tampering"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowScopedWorkloadServicesWithinBoundary"
        Effect   = "Allow"
        Action   = [
          "ecs:*",
          "ecr:*",
          "logs:*",
          "cloudwatch:*",
          "ssm:*",
          "ssmmessages:*",
          "secretsmanager:*",
          "s3:*",
          "kms:Decrypt",
          "kms:DescribeKey",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyPrivilegeEscalationAndIAMMutation"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:CreateAccessKey",
          "iam:CreateLoginProfile",
          "iam:DeleteRolePermissionsBoundary",
          "iam:DeleteUserPermissionsBoundary",
          "iam:PutRolePermissionsBoundary",
          "iam:PutUserPermissionsBoundary",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy",
          "iam:CreatePolicyVersion",
          "iam:SetDefaultPolicyVersion"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenySecurityAuditAndGuardrailTampering"
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "cloudtrail:UpdateTrail",
          "guardduty:DeleteDetector",
          "guardduty:DisassociateFromMasterAccount",
          "access-analyzer:DeleteAnalyzer",
          "config:StopConfigurationRecorder"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-permissions-boundary"
  })
}

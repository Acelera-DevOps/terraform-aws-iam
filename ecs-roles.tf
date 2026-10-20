# =============================================================================
# 2. Strict Separation of ECS Task Execution Role vs Application Task Role
# =============================================================================

# 2A. ECS Task Execution Role (Infrastructure Plane: ECR Pull + CloudWatch Logs)
resource "aws_iam_role" "ecs_task_execution_role" {
  name                 = "${local.name_prefix}-ecs-execution-role"
  description          = "ECS Agent Execution Role for pulling ECR images and shipping container logs"
  permissions_boundary = aws_iam_policy.permissions_boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTasksAssumeExecutionRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecs-execution-role"
    Role = "ecs-execution"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_managed" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2B. ECS Application Task Role (Application Plane: Scoped PoLP Runtime Access)
resource "aws_iam_role" "ecs_application_task_role" {
  name                 = "${local.name_prefix}-ecs-task-role"
  description          = "Zero-Trust PoLP Application Task Role for runtime AWS SDK calls"
  permissions_boundary = aws_iam_policy.permissions_boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTasksAssumeTaskRoleWithSourceAccountGuard"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecs-task-role"
    Role = "ecs-application-task"
  })
}

resource "aws_iam_role_policy" "ecs_application_task_polp" {
  name = "${local.name_prefix}-ecs-task-polp-policy"
  role = aws_iam_role.ecs_application_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadApplicationScopedParametersAndSecrets"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/*",
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*"
        ]
      },
      {
        Sid    = "ScopedS3ApplicationBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-assets",
          "arn:aws:s3:::${var.project_name}-${var.environment}-assets/*"
        ]
      },
      {
        Sid    = "ECSExecSecureSessionChannel"
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

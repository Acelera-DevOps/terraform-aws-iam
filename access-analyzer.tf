# =============================================================================
# 4. AWS IAM Access Analyzer (Continuous External Access Detection)
# =============================================================================

resource "aws_accessanalyzer_analyzer" "this" {
  count         = var.enable_access_analyzer ? 1 : 0
  analyzer_name = "${local.name_prefix}-account-analyzer"
  type          = "ACCOUNT"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-account-analyzer"
  })
}

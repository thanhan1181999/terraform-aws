# Đảm bảo đang đứng trong thư mục bootstrap
output "role_arn" {
  description = "Copy giá trị này vào GitHub Secret AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "ARN của OIDC Provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}
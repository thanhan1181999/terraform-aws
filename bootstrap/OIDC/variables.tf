variable "github_org" {
  description = "GitHub username hoặc organization"
  type        = string
}

variable "github_repo" {
  description = "Tên repository"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}
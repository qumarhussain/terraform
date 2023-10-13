variable "allowed_aws_account_id" {
  description = "AWS Account ID allowed to create, pull, and push images in the ECR repository"
}

variable "untagged_image_expiration_days" {
  description = "Number of days after which untagged images will be expired"
  default     = 7
}

variable "tagged_image_count_threshold" {
  description = "Number of tagged images threshold for expiration"
  default     = 5
}

variable "tags_to_expire" {
  description = "List of tags used for expiration policy"
  default     = ["old", "deprecated", "stale"]
}

variable "scan_on_push" {
  description = "Enable image scanning during push"
  default     = true
}

resource "aws_ecr_repository" "my_repository" {
  name = "my-ecr-repository"  # Specify the name for your ECR repository

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowPullPushCreate",
        Effect    = "Allow",
        Action    = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CreateRepository"
        ],
        Resource  = aws_ecr_repository.my_repository.arn,
        Principal = {
          AWS = var.allowed_aws_account_id
        }
      }
    ]
  })

  lifecycle_policy = jsonencode({
    rules = [
      {
        rule_priority = 1,
        description   = "Expire images with specified tags",
        selection = {
          tag_status = "tagged",
          tag_prefix_list = var.tags_to_expire,
          count_type = "imageCountMoreThan",
          count_number = var.tagged_image_count_threshold
        },
        action = {
          type = "expire"
        }
      },
      {
        rule_priority = 2,
        description   = "Expire untagged images older than specified days",
        selection = {
          tag_status = "untagged",
          count_type = "sinceImagePushed",
          count_unit = "days",
          count_number = var.untagged_image_expiration_days
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

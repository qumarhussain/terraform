provider "aws" {
  region = "us-east-1"  # Specify your desired AWS region
}

resource "aws_ecr_repository" "my_repository" {
  name = "my-ecr-repository"  # Specify the name for your ECR repository

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "my_lifecycle_policy" {
  repository = aws_ecr_repository.my_repository.name

  policy = jsonencode({
    rules = [
      {
        rule_priority = 1,
        description   = "Expire images with no tags",
        selection = {
          tag_status = "untagged",
          count_type = "sinceImagePushed",
          count_unit = "days",
          count_number = 7
        },
        action = {
          type = "expire"
        }
      },
      {
        rule_priority = 2,
        description   = "Expire tagged images older than 5",
        selection = {
          tag_status = "tagged",
          count_type = "imageCountMoreThan",
          count_number = 5
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

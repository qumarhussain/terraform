data "aws_iam_policy_document" "ecr_power_user" {
  source_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_policy" "ecr_repository_policy" {
  name        = "ecr-repository-policy"
  description = "ECR repository permissions for the specified AWS account"
  policy      = data.aws_iam_policy_document.ecr_power_user.json
}

resource "aws_ecr_repository_policy" "my_repository_policy" {
  repository = aws_ecr_repository.my_repository.name
  policy     = aws_iam_policy.ecr_repository_policy.policy
}

data "aws_iam_policy_document" "ecr_power_user" {
  source_json = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPullPushCreate",
      "Effect": "Allow",
      "Action": [
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
      "Resource": "*"
    }
  ]
}
JSON
}

resource "aws_iam_policy" "ecr_repository_policy" {
  name        = "ecr-repository-policy"
  description = "ECR repository permissions for the specified AWS account"
  policy      = data.aws_iam_policy_document.ecr_power_user.json
}

resource "aws_ecr_repository" "my_repository" {
  name = "my-ecr-repository"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "my_repository_policy" {
  repository = aws_ecr_repository.my_repository.name
  policy     = aws_iam_policy.ecr_repository_policy.policy
}

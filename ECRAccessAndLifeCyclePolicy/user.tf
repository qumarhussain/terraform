provider "aws" {
  region = "us-east-1"  # Specify your desired AWS region
}

resource "aws_iam_user" "user1" {
  name = "user1"
}

resource "aws_iam_user" "user2" {
  name = "user2"
}

data "aws_iam_policy_document" "user1_policy" {
  source_json = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "CreateRepositories",
        Effect    = "Allow",
        Action    = [
          "ecr:CreateRepository",
          "ecr:GetAuthorizationToken",
          "ecr:UploadLayerPart",
          "ecr:PutImage",
          "ecr:BatchCheckLayerAvailability"
        ],
        Resource  = "*"
      }
    ]
  })
}

data "aws_iam_policy_document" "user2_policy" {
  source_json = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "ListRepositories",
        Effect    = "Allow",
        Action    = [
          "ecr:DescribeRepositories",
          "ecr:GetAuthorizationToken"
        ],
        Resource  = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "user1_policy" {
  name        = "user1-policy"
  description = "ECR permissions for user1"
  policy      = data.aws_iam_policy_document.user1_policy.json
}

resource "aws_iam_policy" "user2_policy" {
  name        = "user2-policy"
  description = "ECR permissions for user2"
  policy      = data.aws_iam_policy_document.user2_policy.json
}

resource "aws_iam_user_policy_attachment" "user1_policy_attachment" {
  user       = aws_iam_user.user1.name
  policy_arn = aws_iam_policy.user1_policy.arn
}

resource "aws_iam_user_policy_attachment" "user2_policy_attachment" {
  user       = aws_iam_user.user2.name
  policy_arn = aws_iam_policy.user2_policy.arn
}

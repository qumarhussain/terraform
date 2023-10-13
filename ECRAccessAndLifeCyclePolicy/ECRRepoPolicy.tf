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

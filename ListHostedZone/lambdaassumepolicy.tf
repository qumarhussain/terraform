# Grant the Lambda execution role permissions to assume the IAM role
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [data.aws_iam_role.lambda_assumed_role.arn]
  }
}
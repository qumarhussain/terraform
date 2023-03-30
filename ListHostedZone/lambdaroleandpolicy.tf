# Create an IAM policy document with permissions for Lambda function
data "aws_iam_policy_document" "lambda_policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ChangeResourceRecordSets",
      "route53:GetHostedZone",
      "route53:GetChange"
    ]
    resources = ["*"]
  }
}

# Create the IAM policy for Lambda function
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  policy      = data.aws_iam_policy_document.lambda_policy.json
}

# Create an IAM role for Lambda function to assume
data "aws_iam_role" "lambda_assumed_role" {
  name = "lambda_role"
}

# Attach the IAM policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = data.aws_iam_role.lambda_assumed_role.name
}

# Grant the Lambda execution role permissions to assume the IAM role
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [data.aws_iam_role.lambda_assumed_role.arn]
  }
}

resource "aws_iam_role_policy" "assume_role_policy" {
  name = "lambda_assume_role_policy"
  policy = data.aws_iam_policy_document.assume_role_policy.json
  role = aws_iam_role.lambda_role.name
}

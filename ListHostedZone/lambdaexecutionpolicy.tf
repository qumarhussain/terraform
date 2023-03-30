data "aws_iam_policy_document" "example_policy" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ChangeResourceRecordSets",
      "route53:GetHostedZone",
      "route53:GetChange"
    ]
    resources = ["*"]
  }
}

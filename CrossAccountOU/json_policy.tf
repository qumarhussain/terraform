{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "o-xxxxxxxxxx"
        }
      }
    }
  ]
}

{

resource "aws_iam_role_policy" "example" {
  role = aws_iam_role.example.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowOUs"
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = {
          AWS = "*"
        }
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID": "o-xxxxxxxxxx"
          }
          ForAnyValue:StringLike = {
            "aws:ResourceOrgPaths": ["o-a1b2c3d4e5/r-ab12/ou-ab12-11111111/*"]
          }
        }
      }
    ]
  })
}


# Define AWS provider and region
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

# Create an S3 bucket to hold the Lambda function code
resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket = "my-lambda-code-bucket"
}

# Upload the Lambda function code to the S3 bucket
resource "aws_s3_bucket_object" "lambda_code_object" {
  bucket = aws_s3_bucket.lambda_code_bucket.bucket
  key    = "list_hosted_zones_lambda.zip"
  source = "list_hosted_zones_lambda.zip"
}

# Create a new IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach an IAM policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Define the Lambda function
resource "aws_lambda_function" "list_hosted_zones_lambda" {
  function_name = "list_hosted_zones_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.7"
  timeout       = 5

  # Define environment variables
  environment {
    variables = {
      AWS_DEFAULT_REGION = "us-west-2"
    }
  }

  # Define the Lambda function code
  source_code_hash = filebase64sha256("list_hosted_zones_lambda.zip")
  s3_bucket        = aws_s3_bucket.lambda_code_bucket.id
  s3_key           = aws_s3_bucket_object.lambda_code_object.key
}

# Define the Lambda function role policy
resource "aws_iam_policy" "list_hosted_zones_policy" {
  name = "list_hosted_zones_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the Lambda role
resource "aws_iam_role_policy_attachment" "list_hosted_zones_policy_attachment" {
  policy_arn = aws_iam_policy.list_hosted_zones_policy.arn
  role       = aws_iam_role.lambda_role.name
}

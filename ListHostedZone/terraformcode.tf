# Define AWS provider and region
provider "aws" {
  region = "us-west-2"
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
resource "aws_iam_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Define the Lambda function
resource "aws_lambda_function" "simple_lambda" {
  filename      = "simple_lambda.zip"
  function_name = "simple_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.7"
  timeout       = 5

  # Define environment variables
  environment {
    variables = {
      MESSAGE = "Hello, world!"
    }
  }

  # Define the Lambda function code
  source_code_hash = filebase64sha256("simple_lambda.zip")
}

# Create a ZIP archive of the Python code
data "archive_file" "simple_lambda_zip" {
  type        = "zip"
  output_path = "simple_lambda.zip"
  source_dir  = "simple_lambda"
}

# Define the Lambda function code
resource "aws_lambda_function_code" "simple_lambda_code" {
  function_name = aws_lambda_function.simple_lambda.function_name
  source_code_hash = data.archive_file.simple_lambda_zip.output_base64sha256
}

# Define the Lambda function handler code
resource "aws_lambda_function" "simple_lambda_handler" {
  function_name = aws_lambda_function.simple_lambda.function_name
  handler = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.simple_lambda_zip.output_base64sha256
}

# Define the Lambda function role policy
resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach the policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

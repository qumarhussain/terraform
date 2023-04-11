provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "example_lambda" {
  filename      = "lambda_function.zip"
  function_name = "example_lambda_function"
  role          = aws_iam_role.example_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  environment {
    variables = {
      ORG = "my-org"
      APP = "my-app"
    }
  }

  # Use the "archive" provider to package the Lambda function code
  # into a ZIP file
  source_code_hash = archive_file.example_lambda_zip.output_base64
}

# Create a ZIP file containing the Lambda function code
resource "archive_file" "example_lambda_zip" {
  type        = "zip"
  output_path = "lambda_function.zip"
  source {
    content  = file("lambda_function.py")
    filename = "lambda_function.py"
  }
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "example_lambda_role" {
  name = "example_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach permissions to the IAM role for the Lambda function
resource "aws_iam_role_policy_attachment" "example_lambda_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  role       = aws_iam_role.example_lambda_role.name
}

# Create a CloudWatch Events rule to trigger the Lambda function at 11am every day
resource "aws_cloudwatch_event_rule" "example_lambda_schedule" {
  name        = "example_lambda_schedule"
  description = "Schedule for example Lambda function"

  schedule_expression = "cron(0 11 * * ?)"
}

# Add the Lambda function as a target for the CloudWatch Events rule
resource "aws_cloudwatch_event_target" "example_lambda_target" {
  rule      = aws_cloudwatch_event_rule.example_lambda_schedule.name
  target_id = "example_lambda_target"
  arn       = aws_lambda_function.example_lambda.arn

  input_transformer {
    input_paths = {
      org = "$.detail.org"
      env = "$.detail.env"
      app = "$.detail.app"
    }
    input_template = <<EOF
{
  "org": <org>,
  "env": <env>,
  "app": <app>
}
EOF
  }
}

# Grant permission to the CloudWatch Events rule to invoke the Lambda function
resource "aws_lambda_permission" "example_lambda_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example_lambda.function_name
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.example_lambda_schedule.arn
}

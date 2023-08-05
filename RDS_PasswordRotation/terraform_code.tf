resource "aws_lambda_function" "example" {
  function_name    = "rds-password-rotation"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.8"
  handler          = "lambda_function.lambda_handler"
  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      DB_INSTANCE_IDENTIFIER = aws_db_instance.example.identifier
      SECRET_NAME            = aws_secretsmanager_secret.example.name
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "rds-password-rotation-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "rds-password-rotation-lambda-attachment"
  policy_arn = aws_iam_policy.lambda_policy.arn
  roles      = [aws_iam_role.lambda_role.name]
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "rds-password-rotation-lambda-policy"
  description = "Policy for RDS password rotation Lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:ModifyDBInstance",
        "secretsmanager:GetSecretValue",
        "secretsmanager:RotateSecret"
      ],
      "Resource": [
        "arn:aws:rds:*:*:db:${aws_db_instance.example.identifier}",
        "arn:aws:secretsmanager:*:*:secret:${aws_secretsmanager_secret.example.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "invoke_permission" {
  statement_id  = "AllowInvokeFromCloudWatchEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.example.arn
}

resource "aws_cloudwatch_event_rule" "example" {
  name        = "rds-password-rotation-trigger"
  description = "Trigger for RDS password rotation"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.example.name
  target_id = "rds-password-rotation-target"
  arn       = aws_lambda_function.example.arn
}

resource "aws_secretsmanager_secret" "example" {
  name = "example-db-secret"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = "initial-password"
}

resource "aws_secretsmanager_secret_rotation" "example_rotation" {
  secret_id               = aws_secretsmanager_secret.example.id
  rotation_lambda_arn     = aws_lambda_function.example.arn
  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_db_instance" "example" {
  identifier            = "example-db-instance"
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = "db.t2.micro"
  allocated_storage     = 20
  storage_type          = "gp2"
  username              = "admin"
  password              = aws_secretsmanager_secret_version.example.secret_string
  publicly_accessible  = false

  # ... other RDS configuration settings ...
}

resource "aws_db_instance_password_rotation" "example_rotation" {
  db_instance_identifier         = aws_db_instance.example.identifier
  rotation_single_user            = true
  rotation_lambda_arn            = aws_lambda_function.example.arn
}

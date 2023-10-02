{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SecretsManagerPermissions",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": [
                "arn:aws:secretsmanager:region:account-id:secret:my-db-secret"
            ]
        },
        {
            "Sid": "CloudWatchLogsPermissions",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:region:account-id:log-group:/aws/lambda/your-lambda-function-name:*"
            ]
        },
        {
            "Sid": "RDSDBConnect",
            "Effect": "Allow",
            "Action": [
                "rds-db:connect"
            ],
            "Resource": [
                "arn:aws:rds-db:region:account-id:dbuser:db-instance-id/dbusername"
            ]
        },
        {
            "Sid": "DatabaseUpdate",
            "Effect": "Allow",
            "Action": [
                "rds-data:ExecuteStatement"
            ],
            "Resource": [
                "arn:aws:rds:region:account-id:db:db-instance-id/dbname"
            ]
        }
    ]
}

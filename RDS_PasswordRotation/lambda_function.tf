import boto3

def lambda_handler(event, context):
    # Retrieve the DB instance identifier and Secret Manager name from the event payload
    db_instance_identifier = event['dbInstanceIdentifier']
    secret_name = event['secretName']

    # Create an RDS client
    rds_client = boto3.client('rds')

    # Retrieve the new password from AWS Secrets Manager
    secrets_manager_client = boto3.client('secretsmanager')
    get_secret_response = secrets_manager_client.get_secret_value(
        SecretId=secret_name
    )
    new_password = get_secret_response['SecretString']

    # Update the RDS instance password
    response = rds_client.modify_db_instance(
        DBInstanceIdentifier=db_instance_identifier,
        MasterUserPassword=new_password,
        ApplyImmediately=True
    )

    # Print the response
    print(response)

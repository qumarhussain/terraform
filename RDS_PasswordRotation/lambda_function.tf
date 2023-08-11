import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        db_instance_identifier = event['dbInstanceIdentifier']
        secret_name = event['secretName']

        rds_client = boto3.client('rds')
        secrets_manager_client = boto3.client('secretsmanager')

        get_secret_response = secrets_manager_client.get_secret_value(
            SecretId=secret_name
        )
        new_password = get_secret_response['SecretString']

        response = rds_client.modify_db_instance(
            DBInstanceIdentifier=db_instance_identifier,
            MasterUserPassword=new_password,
            ApplyImmediately=True
        )

        logger.info(f"Password updated for DB instance {db_instance_identifier}: {response}")
    except Exception as e:
        logger.error(f"An error occurred: {str(e)}")
        raise e

import boto3
import json
import psycopg2
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secretsmanager_client = boto3.client('secretsmanager')

def lambda_handler(event, context):
    try:
        # Extract required parameters from the event input
        db_host = event['detail'].get('dbHost')
        db_port = event['detail'].get('dbPort')
        db_name = event['detail'].get('dbName')
        db_username = event['detail'].get('dbUsername')
        master_user_secret_name = event['detail'].get('masterUserSecretName')
        non_master_user_secret_name = event['detail'].get('nonMasterUserSecretName')
        
        # Check for missing parameters
        if not all([db_host, db_port, db_name, db_username, master_user_secret_name, non_master_user_secret_name]):
            error_message = "Missing required parameters in the event input."
            logger.error(error_message)
            return {
                'statusCode': 400,
                'body': error_message
            }
        
        logger.info("Retrieving secrets from Secrets Manager...")
        master_user_secret = secretsmanager_client.get_secret_value(SecretId=master_user_secret_name)
        non_master_user_secret = secretsmanager_client.get_secret_value(SecretId=non_master_user_secret_name)
        
        # Check if retrieved secrets are not empty
        if 'SecretString' not in master_user_secret or 'SecretString' not in non_master_user_secret:
            error_message = "Secrets retrieved from Secrets Manager are empty."
            logger.error(error_message)
            return {
                'statusCode': 500,
                'body': error_message
            }
        
        master_user_credentials = json.loads(master_user_secret['SecretString'])
        non_master_user_credentials = json.loads(non_master_user_secret['SecretString'])
        logger.info("Secrets retrieved successfully.")
        
        logger.info("Connecting to the database...")
        connection = psycopg2.connect(
            host=db_host,
            port=db_port,
            dbname=db_name,
            user=db_username,
            password=master_user_credentials.get('password')
        )
        logger.info("Connected to the database successfully.")

        # Update non-master user's password
        with connection.cursor() as cursor:
            logger.info("Updating non-master user's password...")
            update_query = "UPDATE users SET password = %s WHERE username = %s"
            cursor.execute(update_query, (non_master_user_credentials.get('password'), non_master_user_credentials.get('username')))
            connection.commit()
            logger.info("Non-master user's password updated successfully.")

        return {
            'statusCode': 200,
            'body': 'Non-master user password updated successfully'
        }

    except Exception as e:
        error_message = f"Error: {str(e)}"
        logger.error(error_message)
        return {
            'statusCode': 500,
            'body': error_message
        }
    finally:
        # Close the database connection
        if connection:
            connection.close()
            logger.info("Database connection closed.")

import os
import json
import boto3
from io import BytesIO
import pysftp
import gnupg
import zipfile
from datetime import datetime

def get_parameter(parameter_name):
    try:
        ssm = boto3.client('ssm')
        response = ssm.get_parameter(Name=parameter_name, WithDecryption=True)
        return response['Parameter']['Value']
    except Exception as e:
        print(f"Error retrieving parameter {parameter_name}: {str(e)}")
        raise e

def encrypt_with_pgp(content, pgp_public_key):
    try:
        gpg = gnupg.GPG()

        # Import the PGP public key
        imported_key = gpg.import_keys(pgp_public_key)

        # Encrypt the content using the imported PGP public key
        encrypted_data = gpg.encrypt(content, imported_key.fingerprints[0], always_trust=True)

        return str(encrypted_data)
    except Exception as e:
        print(f"Error encrypting content with PGP: {str(e)}")
        raise e

def process_files(s3, s3_bucket_name, sftp, sftp_remote_path, pgp_public_key, file1, file2):
    try:
        # Check if both files exist in S3
        file1_exists = any(obj['Key'] == file1 for obj in s3.list_objects(Bucket=s3_bucket_name)['Contents'])
        file2_exists = any(obj['Key'] == file2 for obj in s3.list_objects(Bucket=s3_bucket_name)['Contents'])

        if file1_exists and file2_exists:
            # Download the pair of files from S3
            s3_response1 = s3.get_object(Bucket=s3_bucket_name, Key=file1)
            file_content1 = s3_response1['Body'].read()

            s3_response2 = s3.get_object(Bucket=s3_bucket_name, Key=file2)
            file_content2 = s3_response2['Body'].read()

            # Encrypt the files with PGP
            encrypted_content1 = encrypt_with_pgp(file_content1, pgp_public_key)
            encrypted_content2 = encrypt_with_pgp(file_content2, pgp_public_key)

            # Zip the encrypted files
            zipped_file_name1 = f'{os.path.basename(file1)}.zip'
            zipped_file_name2 = f'{os.path.basename(file2)}.zip'

            with BytesIO() as zip_buffer:
                with zipfile.ZipFile(zip_buffer, 'a', zipfile.ZIP_DEFLATED, False) as zip_file:
                    zip_file.writestr(os.path.basename(file1 + '.pgp'), encrypted_content1)
                    zip_file.writestr(os.path.basename(file2 + '.pgp'), encrypted_content2)

                # Get the current date (ddmmyyyy)
                current_date = datetime.now().strftime('%d%m%Y')

                # Upload the zipped files to S3 archive folder with date-based subfolder
                archive_folder = f'archive/{current_date}'
                s3.upload_fileobj(zip_buffer, s3_bucket_name, f'{archive_folder}/{zipped_file_name1}')
                s3.upload_fileobj(zip_buffer, s3_bucket_name, f'{archive_folder}/{zipped_file_name2}')

            print(f"Files {file1} and {file2} successfully zipped and uploaded to S3 archive folder.")
        else:
            # Get the current date (ddmmyyyy)
            current_date = datetime.now().strftime('%d%m%Y')

            # Upload the original files to S3 error folder with date-based subfolder
            error_folder = f'error/{current_date}'
            s3.copy_object(
                Bucket=s3_bucket_name,
                CopySource={'Bucket': s3_bucket_name, 'Key': file1},
                Key=f'{error_folder}/{os.path.basename(file1)}'
            )
            s3.copy_object(
                Bucket=s3_bucket_name,
                CopySource={'Bucket': s3_bucket_name, 'Key': file2},
                Key=f'{error_folder}/{os.path.basename(file2)}'
            )

            print(f"Pair of files {file1} and {file2} not found in S3. Original files copied to S3 error folder.")

    except Exception as e:
        print(f"Error processing files: {str(e)}")
        raise e

def lambda_handler(event, context):
    try:
        # Retrieve parameter values from AWS Systems Manager Parameter Store
        s3_bucket_name = get_parameter('/your/parameter/store/s3_bucket_name')
        sftp_host = get_parameter('/your/parameter/store/sftp_host')
        sftp_username = get_parameter('/your/parameter/store/sftp_username')
        sftp_password = get_parameter('/your/parameter/store/sftp_password')
        sftp_remote_path = get_parameter('/your/parameter/store/sftp_remote_path')
        pgp_public_key = get_parameter('/your/parameter/store/pgp_public_key')
        pairs_parameter_name = '/your/parameter/store/pairs'

        # Initialize S3 client
        s3 = boto3.client('s3')

        # Initialize SFTP connection
        with pysftp.Connection(host=sftp_host, username=sftp_username, password=sftp_password) as sftp:
            # Change to the remote directory on SFTP server
            sftp.cwd(sftp_remote_path)

            # Retrieve the pairs of files from Parameter Store
            pairs_json = get_parameter(pairs_parameter_name)
            pairs = json.loads(pairs_json).get('pairs', [])

            # Process each pair of files
            for pair in pairs:
                file1, file2 = pair.get('file1', ''), pair.get('file2', '')
                if file1 and file2:
                    process_files(s3, s3_bucket_name, sftp, sftp_remote_path, pgp_public_key, file1, file2)
                else:
                    print("Invalid pair of files in Parameter Store. Skipping processing.")

    except Exception as e:
        print(f"Unhandled error in Lambda: {str(e)}")
        raise e




{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-s3-bucket-name/*",
                "arn:aws:s3:::your-s3-bucket-name"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:your-region:your-account-id:parameter/your-parameter-path/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:your-region:your-account-id:log-group:/aws/lambda/your-lambda-function-name:*"
        }
    ]
}


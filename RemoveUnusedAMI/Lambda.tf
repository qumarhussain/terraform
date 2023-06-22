import boto3
from dateutil.parser import parse

def get_ec2_instances(application, environment):
    ec2 = boto3.client('ec2')
    env_app = '*' + environment + '-' + application + '*'
    filters = [{'Name': 'tag:Name', 'Values': [env_app]}, {'Name': 'instance-state-name', 'Values': ['running']}]
    instances_info = ec2.describe_instances(Filters=filters)['Reservations']

    instances = []
    for res in instances_info:
        instances.extend(res['Instances'])

    print(f"Instances for {env_app}: {instances}")
    return instances

def get_amis(application, environment):
    ec2 = boto3.client('ec2')
    env_app = '*' + application + '-' + environment + '*'
    filters = [{'Name': 'tag:Name', 'Values': [env_app]}]
    amis = ec2.describe_images(Owners=['self'], Filters=filters)['Images']  # Assuming these are custom AMIs owned by your account.

    print(f"AMIs for {env_app}: {amis}")
    return amis

def get_amis_of_instances(instances, amis):
    matched_amis = []
    non_matched_amis = amis.copy()

    for instance in instances:
        ami_id = instance['ImageId']
        for ami in amis:
            if ami['ImageId'] == ami_id:
                matched_amis.append(ami)
                non_matched_amis.remove(ami)

    print(f"Matched AMIs: {matched_amis}")
    print(f"Non-matched AMIs: {non_matched_amis}")
    return matched_amis, non_matched_amis

def delete_amis(matched_amis, non_matched_amis):
    ec2 = boto3.client('ec2')
    # Sort AMIs by creation date
    sorted_matched_amis = sorted(matched_amis, key=lambda ami: parse(ami['CreationDate']))
    sorted_non_matched_amis = sorted(non_matched_amis, key=lambda ami: parse(ami['CreationDate']))
    # Find the creation date of the latest matched AMI
    latest_matched_ami_date = parse(sorted_matched_amis[-1]['CreationDate'])
    # Only delete non-matched AMIs that were created before the latest matched AMI
    for ami in sorted_non_matched_amis:
        if parse(ami['CreationDate']) < latest_matched_ami_date:
            response = ec2.deregister_image(ImageId=ami['ImageId'])
            print(f"AMI {ami['ImageId']} deregistered.")

def lambda_handler(event, context):
    application = event.get('application')
    environment = event.get('environment')

    if not application or not environment:
        return {
            'error': 'Both application and environment parameters are required.'
        }

    try:
        instances = get_ec2_instances(application, environment)
        amis = get_amis(application, environment)

        # Check if any instances or AMIs are found
        if not instances or not amis:
            return {
                'error': 'No matching EC2 instances or AMIs found.'
            }

        print(f"Found {len(instances)} instance(s) for environment {environment} and application {application}")
        print(f"Found {len(amis)} AMI(s) for environment {environment} and application {application}")

        matched_amis, non_matched_amis = get_amis_of_instances(instances, amis)
        print(f"Found {len(matched_amis)} matched AMI(s) and {len(non_matched_amis)} non-matched AMI(s)")

        # Only delete AMIs if there are non-matched ones
        if non_matched_amis:
            delete_amis(matched_amis, non_matched_amis)
            print(f"Deleted older non-matched AMIs.")
        
        return {
            'message': 'Completed successfully.'
        }
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        return {
            'error': str(e)
        }
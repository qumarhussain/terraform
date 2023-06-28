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
    env_app = '*' + environment + '-' + application + '*'
    filters = [{'Name': 'tag:Name', 'Values': [env_app]}]
    amis = ec2.describe_images(Owners=['self'], Filters=filters)['Images']  # Assuming these are custom AMIs owned by your account.

    print(f"AMIs for {env_app}: {amis}")
    return amis

def get_matching_amis(instances, amis):
    matching_amis = []
    for instance in instances:
        ami_id = instance['ImageId']
        matching_ami = next((ami for ami in amis if ami['ImageId'] == ami_id), None)
        if matching_ami:
            matching_amis.append(matching_ami)
    return matching_amis

def delete_amis(matching_amis, all_amis):
    ec2 = boto3.client('ec2')

    non_matching_amis = [ami for ami in all_amis if ami not in matching_amis]
    
    if matching_amis and non_matching_amis:
        latest_matching_ami_date = parse(max(matching_amis, key=lambda ami: parse(ami['CreationDate']))['CreationDate'])
        for ami in non_matching_amis:
            if parse(ami['CreationDate']) < latest_matching_ami_date:
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
        all_amis = get_amis(application, environment)

        # Check if any instances or AMIs are found
        if not instances or not all_amis:
            return {
                'error': 'No matching EC2 instances or AMIs found.'
            }

        print(f"Found {len(instances)} instance(s) for environment {environment} and application {application}")
        print(f"Found {len(all_amis)} AMI(s) for environment {environment} and application {application}")

        matching_amis = get_matching_amis(instances, all_amis)
        print(f"Found {len(matching_amis)} matching AMI(s)")

        # Only delete AMIs if there are non-matched ones
        if len(matching_amis) < len(all_amis):
            delete_amis(matching_amis, all_amis)
            print(f"Deleted older non-matched AMIs.")
        
        return {
            'message': 'Completed successfully.'
        }
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        return {
            'error': str(e)
        }
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
    app_env = '*' + application + '-' + environment + '*'
    filters = [{'Name': 'tag:Name', 'Values': [app_env]}]
    amis = ec2.describe_images(Owners=['self'], Filters=filters)['Images']  # Assuming these are custom AMIs owned by your account.

    print(f"AMIs for {app_env}: {amis}")
    return amis

def get_amis_of_instances(instances, amis):
    instances_with_amis = []

    for instance in instances:
        ami_id = instance['ImageId']
        matched_amis = []
        non_matched_amis = amis.copy()

        for ami in amis:
            if ami['ImageId'] == ami_id:
                matched_amis.append(ami)
                non_matched_amis.remove(ami)
        
        sorted_matched_amis = sorted(matched_amis, key=lambda ami: parse(ami['CreationDate']))
        sorted_non_matched_amis = sorted(non_matched_amis, key=lambda ami: parse(ami['CreationDate']))

        instances_with_amis.append({
            'instance': instance,
            'matched_amis': sorted_matched_amis,
            'non_matched_amis': sorted_non_matched_amis
        })

    return instances_with_amis

def delete_amis(instances_with_amis):
    ec2 = boto3.client('ec2')

    for instance_data in instances_with_amis:
        matched_amis = instance_data['matched_amis']
        non_matched_amis = instance_data['non_matched_amis']

        if matched_amis and non_matched_amis:
            latest_matched_ami_date = parse(matched_amis[-1]['CreationDate'])
            for ami in non_matched_amis:
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

        instances_with_amis = get_amis_of_instances(instances, amis)

        # Only delete AMIs if there are non-matched ones
        if any([instance_data['non_matched_amis'] for instance_data in instances_with_amis]):
            delete_amis(instances_with_amis)
            print(f"Deleted older non-matched AMIs.")
        
        return {
            'message': 'Completed successfully.'
        }
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        return {
            'error': str(e)
        }
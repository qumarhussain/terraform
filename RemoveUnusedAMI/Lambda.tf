import boto3

def get_ec2_instances(application, environment):
    ec2 = boto3.client('ec2')
    app_env = '*' + application + '-' + environment + '*'
    filters = [{'Name': 'tag:Name', 'Values': [app_env]}, {'Name': 'instance-state-name', 'Values': ['running']}]
    instances = ec2.describe_instances(Filters=filters)['Reservations']
    return instances

def get_amis(application, environment):
    ec2 = boto3.client('ec2')
    app_env = '*' + application + '-' + environment + '*'
    filters = [{'Name': 'tag:Name', 'Values': [app_env]}]
    amis = ec2.describe_images(Owners=['self'], Filters=filters)['Images']  # Assuming these are custom AMIs owned by your account.
    return amis

def get_amis_of_instances(instances, amis):
    matched_amis = []
    non_matched_amis = amis.copy()

    for instance in instances:
        ami_id = instance['Instances'][0]['ImageId']
        for ami in amis:
            if ami['ImageId'] == ami_id:
                matched_amis.append(ami)
                non_matched_amis.remove(ami)

    return matched_amis, non_matched_amis

def delete_amis(amis):
    ec2 = boto3.client('ec2')
    for ami in amis:
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
        instances_info = get_ec2_instances(application, environment)
        instances = []
        for res in instances_info:
            instances.extend(res['Instances'])
        print(f"Found {len(instances)} instance(s) for application {application} in environment {environment}")

        amis = get_amis(application, environment)
        print(f"Found {len(amis)} AMI(s) for application {application} in environment {environment}")

        matched_amis, non_matched_amis = get_amis_of_instances(instances, amis)
        print(f"Found {len(matched_amis)} matched AMI(s) and {len(non_matched_amis)} non-matched AMI(s)")

        delete_amis(matched_amis)

        return {
            'matched_amis': [ami['ImageId'] for ami in matched_amis],
            'non_matched_amis': [ami['ImageId'] for ami in non_matched_amis]
        }

    except Exception as e:
        print(f"An error occurred: {str(e)}")
        return {
            'error': str(e)
        }

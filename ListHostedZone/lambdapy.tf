import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    route53 = boto3.client('route53')
    instances = ec2.describe_instances()
    
    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            instance_tags = instance.get('Tags', [])
            instance_name = next((tag for tag in instance_tags if tag['Key'] == 'Name'), None)
            if instance_name:
                instance_name = instance_name['Value']
            else:
                instance_name = ''
            print(f"EC2 Instance: {instance_name or instance_id}")
            
            # Check for a Route 53 hosted zone with the same name as the instance
            response = route53.list_hosted_zones()
            for zone in response['HostedZones']:
                zone_name = zone['Name']
                if instance_name and zone_name.startswith(instance_name) or zone_name == instance_id:
                    print(f"Hosted Zone: {zone_name}")
                    zone_id = zone['Id'].split('/')[-1]
                    records = route53.list_resource_record_sets(HostedZoneId=zone_id, MaxItems='500')
                    for record in records['ResourceRecordSets']:
                        if record['Type'] == 'A' and not record['Name'].startswith(instance_name or instance_id):
                            print(f"Record Name: {record['Name']}")

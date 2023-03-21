import boto3

def get_ec2_instances():
    ec2 = boto3.client('ec2')
    instances = ec2.describe_instances()
    return instances['Reservations']

def get_matching_hosted_zones(name):
    route53 = boto3.client('route53')
    response = route53.list_hosted_zones()
    matching_zones = []
    for zone in response['HostedZones']:
        zone_name = zone['Name']
        if zone_name == name or zone_name.startswith(name + '.'):
            matching_zones.append(zone)
    return matching_zones

def get_matching_dns_records(zone_id, instance_name, instance_id):
    route53 = boto3.client('route53')
    records = route53.list_resource_record_sets(HostedZoneId=zone_id, MaxItems='500')
    matching_records = []
    for record in records['ResourceRecordSets']:
        if record['Type'] == 'A' and not record['Name'].startswith(instance_name or instance_id) and not record.get('AliasTarget'):
            matching_records.append(record)
    return matching_records

def lambda_handler(event, context):
    instances = get_ec2_instances()
    
    for reservation in instances:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            instance_tags = instance.get('Tags', [])
            instance_name = next((tag for tag in instance_tags if tag['Key'] == 'Name'), None)
            if instance_name:
                instance_name = instance_name['Value']
            else:
                instance_name = ''
            print(f"EC2 Instance: {instance_name or instance_id}")
            
            matching_zones = get_matching_hosted_zones(instance_name or instance_id)
            for zone in matching_zones:
                zone_id = zone['Id'].split('/')[-1]
                print(f"Hosted Zone: {zone['Name']}")
                
                matching_records = get_matching_dns_records(zone_id, instance_name, instance_id)
                for record in matching_records:
                    print(f"Record Name: {record['Name']}")

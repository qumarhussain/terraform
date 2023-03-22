import boto3

def get_ec2_instances(ec2_name):
    """
    Retrieves all EC2 instances containing a specific string in the name tag.
    """
    ec2 = boto3.client('ec2')
    filters = [{'Name': 'tag:Name', 'Values': ['*' + ec2_name + '*']}]
    instances = ec2.describe_instances(Filters=filters)['Reservations']
    return instances

def get_instance_name(instance):
    """
    Retrieves the name of an EC2 instance, or an empty string if it does not have a "Name" tag.
    """
    instance_tags = instance.get('Tags', [])
    instance_name = next((tag for tag in instance_tags if tag['Key'] == 'Name'), None)
    if instance_name:
        return instance_name['Value']
    else:
        return ''

def get_matching_hosted_zones(instance_name):
    """
    Retrieves all Route 53 private hosted zones containing a specific string in the name.
    """
    route53 = boto3.client('route53')
    zones = []
    response = route53.list_hosted_zones_by_name(DNSName='.', MaxItems='100')
    zones.extend(response['HostedZones'])
    while response.get('NextDNSName'):
        response = route53.list_hosted_zones_by_name(
            DNSName=response['NextDNSName'],
            HostedZoneId=response['NextHostedZoneId'],
            MaxItems='100'
        )
        zones.extend(response['HostedZones'])
    matching_zones = [zone for zone in zones if zone['Config']['PrivateZone'] and instance_name in zone['Name']]
    return matching_zones

def get_matching_dns_records(zone_id):
    """
    Retrieves all DNS record sets of type "A" that match a given hosted zone ID.
    """
    route53 = boto3.client('route53')
    records = []
    response = route53.list_resource_record_sets(HostedZoneId=zone_id, MaxItems='500')
    records.extend(response['ResourceRecordSets'])
    while response.get('NextRecordName'):
        response = route53.list_resource_record_sets(
            HostedZoneId=zone_id,
            MaxItems='500',
            StartRecordName=response['NextRecordName'],
            StartRecordType=response['NextRecordType']
        )
        records.extend(response['ResourceRecordSets'])
    matching_records = [record for record in records if record['Type'] == 'A' and not record['Name'].startswith(instance_name) and not record.get('AliasTarget', {}).get('DNSName')]
    return matching_records

def lambda_handler(event, context):
    ec2_name = event['ec2_name']
    instances = get_ec2_instances(ec2_name)
    
    # Initialize counters for summary information
    num_instances = len(instances)
    num_zones = 0
    num_records = 0
    
    for reservation in instances:
        for instance in reservation['Instances']:
            instance_name = get_instance_name(instance)
            print(f"EC2 Instance: {instance_name}")
            
            # Find all matching hosted zones for this instance
            matching_zones = get_matching_hosted_zones(instance_name)
            num_zones += len(matching_zones)
            
            for zone in matching_zones:
                zone_id = zone['Id'].split('/')[-1]
                print(f"Hosted Zone: {zone['Name']}")
                
                # Find all matching DNS record sets for this zone
                matching_records = get_matching_dns_records(zone_id)
                num_records += len(matching_records)
                
                for record in matching_records:
                    print(f"Record Name: {record['Name']}")

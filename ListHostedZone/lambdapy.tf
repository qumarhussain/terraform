import boto3

def get_ec2_instances(ec2_name):
    ec2 = boto3.client('ec2')
    filters = [{'Name': 'tag:Name', 'Values': ['*' + ec2_name + '*']}]
    instances = ec2.describe_instances(Filters=filters)['Reservations']
    return instances

def get_instance_name(instance):
    instance_tags = instance.get('Tags', [])
    instance_name = next((tag for tag in instance_tags if tag['Key'] == 'Name'), None)
    if instance_name:
        return instance_name['Value']
    else:
        return ''

def get_matching_hosted_zones(instance_name):
    route53 = boto3.client('route53')
    zones = []
    response = route53.list_hosted_zones()
    zones.extend(response['HostedZones'])
    while response.get('NextMarker'):
        response = route53.list_hosted_zones(Marker=response['NextMarker'])
        zones.extend(response['HostedZones'])
    matching_zones = [zone for zone in zones if instance_name in zone['Name'] and zone['Config']['PrivateZone']]
    return matching_zones

def get_matching_dns_records(instance_name, zone_id):
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

def delete_dns_record(zone_id, record):
    route53 = boto3.client('route53')
    change_batch = {
        'Changes': [
            {
                'Action': 'DELETE',
                'ResourceRecordSet': record
            }
        ]
    }
    response = route53.change_resource_record_sets(
        HostedZoneId=zone_id,
        ChangeBatch=change_batch
    )
    return response

def lambda_handler(event, context):
    ec2_name = event['ec2_name']
    instances = get_ec2_instances(ec2_name)
    
    num_instances = len(instances)
    num_zones = 0
    num_records = 0
    
    for reservation in instances:
        for instance in reservation['Instances']:
            instance_name = get_instance_name(instance)
            
            matching_zones = get_matching_hosted_zones(instance_name)
            num_zones += len(matching_zones)
            
            for zone in matching_zones:
                zone_id = zone['Id']
                matching_records = get_matching_dns_records(instance_name, zone_id)
                num_records += len(matching_records)
                
                for record in matching_records:
                    delete_dns_record(zone_id, record)
    
    return {
        'num_instances': num_instances,
        'num_zones': num_zones,
        'num_records_deleted': num_records
    }

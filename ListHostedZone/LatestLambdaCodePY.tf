import boto3
import logging

# Setup logging
logger = logging.getLogger()

def get_ec2_instances(instance_name):
    ec2 = boto3.client('ec2')
    filters = [{'Name': 'tag:Name', 'Values': ['*' + instance_name + '*']}, {'Name': 'instance-state-name', 'Values': ['running']}]
    instances = ec2.describe_instances(Filters=filters)['Reservations']
    return instances

def get_instance_name(instance):
    instance_tags = instance.get('Tags', [])
    instance_name = next((tag for tag in instance_tags if tag['Key'] == 'Name'), None)
    if instance_name:
        return instance_name['Value']

def get_matching_hosted_zones(zone_name):
    route53 = boto3.client('route53')
    zones = []
    response = route53.list_hosted_zones_by_name()
    zones.extend(response['HostedZones'])
    while response.get('NextMarker'):
        response = route53.list_hosted_zones_by_name(Marker=response['NextMarker'])
        zones.extend(response['HostedZones'])
    matching_zones = [zone for zone in zones if zone['Config']['PrivateZone'] and zone['Name'].startswith(zone_name)]
    return matching_zones

# Rest of your functions here...

def lambda_handler(event, context):
    # Determine debug mode
    debug = event.get('debug', False)
    logger.setLevel(logging.DEBUG if debug else logging.WARNING)

    org = event['org']
    app = event['app']
    env = event.get('env', '')
    zone_name = event.get('zone_name', '')  # fetch the hosted zone name
    ec2_name = f"{org}-{env}-{app}" if env else f"{org}-{app}"

    # Rest of your code here...

    for reservation in instances:
        for instance in reservation['Instances']:
            instance_name = get_instance_name(instance)

            logger.debug(f"Getting hosted zones for instance: {instance_name}")
            matching_zones = get_matching_hosted_zones(zone_name)
            num_zones += len(matching_zones)

    # Rest of your code here...

    return {
        'num_instances': num_instances,
        'num_zones': num_zones,
        #'num_records_deleted': num_records
    }

def lambda_handler(event, context):
    org = event['org']
    app = event['app']
    env = event.get('env', '')
    ec2_name = f"{org}-{app}-{env}" if env else f"{org}-{app}"
    instances = get_ec2_instances(ec2_name)

    num_instances = len(instances)
    num_zones = 0
    num_records = 0
    matching_records = []
    deleted_records = []

    instance_names = []
    for reservation in instances:
        for instance in reservation['Instances']:
            instance_name = get_instance_name(instance)
            instance_names.append(instance_name)

            matching_zones = get_matching_hosted_zones()
            num_zones += len(matching_zones)

            for zone in matching_zones:
                zone_id = zone['Id']
                matching_records_zone = get_matching_dns_records(instance_name, zone_id, ec2_name)
                num_records += len(matching_records_zone)
                matching_records.extend(matching_records_zone)

    # Remove duplicates from instance_names
    instance_names = list(set(instance_names))

    # Remove matching records that match instance names
    for instance_name in instance_names:
        for record in matching_records[:]:
            if instance_name in record['ResourceRecords'][0]['Value']:
                matching_records.remove(record)

    # Delete remaining matching records
    for record in matching_records:
        zone_id = record['AliasTarget']['HostedZoneId']
        delete_dns_record(zone_id, record)
        deleted_records.append(record)

    print(f"Matching records: {matching_records}")
    print(f"Deleted records: {deleted_records}")

    return {
        'num_instances': num_instances,
        'num_zones': num_zones,
        'num_records_deleted': len(deleted_records)
    }

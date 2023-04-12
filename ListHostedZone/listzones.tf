def lambda_handler(event, context):
    org = event['org']
    app = event['app']
    env = event.get('env', '')
    ec2_name = f"{org}-{env}-{app}" if env else f"{org}-{app}"
    instances = get_ec2_instances(ec2_name)

    instance_names = []
    num_instances = 0
    num_zones = 0
    num_records = 0
    matching_records = []
    deleted_records = []

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
                for record in matching_records_zone:
                    matching_records.append({'ZoneId': zone_id, 'Record': record})

    instance_names = list(set(instance_names)) # Remove duplicates from instance_names
    num_instances = len(instance_names)
    for i in range(len(matching_records)-1, -1, -1):
    if matching_records[i]['Record']['Name'].startswith(tuple(instance_names)):
        matching_records.pop(i)
		
# Create a dictionary of unique DNS records with their ZoneId
unique_matching_records = {}
for record in matching_records:
    name = record['Record']['Name']
    if name in instance_names:
        continue
    if name in unique_matching_records and unique_matching_records[name]['ZoneId'] != record['ZoneId']:
        # If the record already exists with a different ZoneId, skip it
        continue
    unique_matching_records[name] = {'ZoneId': record['ZoneId'], 'Record': record['Record']}

# Remove old matching records and replace with new unique dictionary values
matching_records.clear()
matching_records.extend(unique_matching_records.values())


    for record in matching_records:
        zone_id = record['ZoneId']
        dns_record = record['Record']
        delete_dns_record(zone_id, dns_record)
        deleted_records.append(dns_record)

    print(f"Matching records: {matching_records}")
    print(f"Deleted records: {deleted_records}")

    return {
        'num_instances': num_instances,
        'num_zones': num_zones,
        'num_records_deleted': num_records
    }

import boto3

def lambda_handler(event, context):
    client = boto3.client('route53')

    # List all the hosted zones in the account
    response = client.list_hosted_zones()

    # Print the ID and name of each hosted zone
    for hosted_zone in response['HostedZones']:
        print("Hosted Zone ID: {}, Name: {}".format(hosted_zone['Id'], hosted_zone['Name']))

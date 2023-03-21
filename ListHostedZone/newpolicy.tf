{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "ec2:DescribeInstances"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
              "route53:ListHostedZones",
              "route53:ListResourceRecordSets"
            ],
            "Resource": "*"
        }
    ]
}

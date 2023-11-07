# Route 53 Record Module

## Overview
The Route 53 Record module uses the `aws_route53_record` resource to manage DNS records in Amazon Route 53. This module enables you to create, update, or delete DNS records associated with a hosted zone. It provides flexibility in configuring various types of DNS records such as A, CNAME, MX, and more.

## Prerequisites
- **AWS Credentials:** Ensure you have valid AWS credentials configured with the necessary permissions to manage Route 53 records.
- **Hosted Zone ID:** You must have the ID of an existing Route 53 hosted zone where you want to create the DNS records.

## Usage

```hcl
module "route53_record" {
  source = "path/to/route53-record-module"

  hosted_zone_id = "Z1234567890ABCDEF12345" # Replace with your Route 53 hosted zone ID
  
  records = {
    "example.com" = {
      type    = "A"
      ttl     = 300
      records = ["1.2.3.4", "5.6.7.8"]
    }
    "www.example.com" = {
      type    = "CNAME"
      ttl     = 300
      records = ["example.com"]
    }
  }
}

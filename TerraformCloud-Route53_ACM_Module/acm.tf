## Overview
The ACM module utilizes the `aws_acm_certificate` resource to manage SSL/TLS certificates in AWS Certificate Manager (ACM). This module is designed to handle ACM certificates, ensuring that the ARN of an existing Certificate Authority (CA) is available for import. The created certificate can be used with various AWS services such as Application Load Balancers (ALB), API Gateways, and more.

### Prerequisites
- **AWS Credentials:** Ensure you have valid AWS credentials configured with the necessary permissions to create ACM certificates.
- **Certificate Authority (CA) ARN:** You must have the ARN of an existing external certificate from a CA to import it into ACM.

# Example Usage: Applying the ACM Certificate to an Application Load Balancer (ALB)
resource "aws_lb_listener" "example_listener" {
  load_balancer_arn = aws_lb.example_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  
  certificate_arn = module.acm_certificate.certificate_arn # Use the ACM certificate ARN from the module output
}
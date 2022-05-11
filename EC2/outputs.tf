output "public_ip" {
  description = "The public IP address assigned to the instance"
  value       = aws_instance.myec2.public_ip
  sensitive   = false
}
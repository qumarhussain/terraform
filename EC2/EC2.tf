resource "aws_instance" "myec2" {
  ami           = var.amiID
  instance_type = var.instanceType

  tags = {
    Name        = var.projectName
    Environment = var.env
  }
}
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucketName
  acl    = var.acl

  tags = {
    Name        = var.projectName
    Environment = var.env
  }
}
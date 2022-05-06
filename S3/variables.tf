variable "bucketName" {
  description = "S3 Bucket Name"
  type        = string
  default     = "s3-qumarhussain-test"
}
variable "acl" {
  description = "Access control list (ACL) for S3"
  type        = string
  default     = "private"
}
variable "projectName" {
  description = "Name of the project this resource is associated with"
  type        = string
  default     = "Project-TEST"
}
variable "env" {
  description = "AWS Enviorment"
  type        = string
  default     = "DEV"
}
variable "amiID" {
  description = "S3 Bucket Name"
  type        = string
  default     = "ami-0d37e07bd4ff37148"
}
variable "instanceType" {
  description = "Access control list (ACL) for S3"
  type        = string
  default     = "t2.small"
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
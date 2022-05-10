variable "dbStorage" {
  description = "DB storage allocated"
  type        = string
  default     = "5"
}
variable "dbEngine" {
  description = "Name of the db engine"
  type        = string
  default     = "postgres"
}
variable "dbVersion" {
  description = "Version of Engine"
  type        = string
  default     = "14.1"
}
variable "dbInstance" {
  description = "Type of instance"
  type        = string
  default     = "db.t3.micro"
}
variable "dbName" {
  description = "Name of DB"
  type        = string
  default     = "mydb"
}
variable "dbUser" {
  description = "DB User Name"
  type        = string
  default     = "foo"
}
variable "dbPass" {
  description = "DB Password"
  type        = string
  default     = "foobarbaz"
}
variable "brp" {
  description = "DB Backup Retention Period"
  type        = string
  default     = "5"
}
variable "paramGPName" {
  description = "DB Parameter Group Name"
  type        = string
  default     = "MyDBPGName"
}
variable "skip" {
  description = "Skip Final Snapshot"
  type        = string
  default     = "true"
}
resource "aws_db_instance" "default" {
  allocated_storage    = var.dbStorage
  engine               = var.dbEngine
  engine_version       = var.dbVersion
  instance_class       = var.dbInstance
  name                 = var.dbName
  username             = var.dbUser
  password             = var.dbPass
  backup_retention_period = var.brp
  parameter_group_name = var.paramGPName
  skip_final_snapshot  = var.skip
}

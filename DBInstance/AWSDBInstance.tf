resource "aws_db_parameter_group" "default" {
 name   = "mydbparmgroup"
 family = var.family
  parameter {
	name  = "log_statement"
	value = var.logStatement
	}
 parameter {
	name  = "log_min_duration_statement"
	value = var.logMinDurationStatement
	}

}
resource "aws_db_instance" "default" {
  allocated_storage       = var.dbStorage
  engine                  = var.dbEngine
  engine_version          = var.dbVersion
  instance_class          = var.dbInstance
  name                    = var.dbName
  username                = var.dbUser
  password                = var.dbPass
  backup_retention_period = var.brp
  parameter_group_name    = aws_db_parameter_group.default.name
  skip_final_snapshot     = var.skip
}

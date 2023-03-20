resource "aws_db_subnet_group" "default" {
  name       = "subnet-group-for-mysql"
  subnet_ids = [aws_subnet.zone1net.id, aws_subnet.zone2net.id]

  tags = {
    Name    = "MYSQL subnet group"
    costTag = var.cost_tag
  }
}


resource "aws_rds_cluster" "mysql_rds" {
  cluster_identifier        = "mysql_rds_cluster"
  availability_zones        = ["eu-central-1a", "eu-central-1b"]
  engine                    = "mysql"
  db_cluster_instance_class = "db.r6gd.xlarge"
  engine_version            = "8.0.26"
  storage_type              = "io1"
  allocated_storage         = 100
  iops                      = 1000
  master_username           = var.db_username
  master_password           = var.db_password

  backup_retention_period = 14

  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.mysql-service.id]

  db_subnet_group_name = aws_db_subnet_group.default.name

  tags = {
    costTag = var.cost_tag
  }
}
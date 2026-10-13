resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_security_group" "db" {
  name        = "${var.project}-db"
  description = "Postgres from EKS nodes only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Postgres from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }
}

resource "aws_db_instance" "this" {
  identifier     = var.project
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_encrypted = true

  db_name  = "todo"
  username = "todo"
  password = random_password.db.result

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  backup_retention_period = 1
  skip_final_snapshot     = true # portfolio cluster: fast teardown
  deletion_protection     = false
}

resource "aws_secretsmanager_secret" "database_url" {
  name                    = "${var.project}/database-url"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = "postgresql://todo:${random_password.db.result}@${aws_db_instance.this.endpoint}/todo"
}

resource "aws_db_instance" "rds" {
  identifier             = "${var.app_name}-rds-postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  db_name                = "rates"
  engine                 = "postgres"
  engine_version         = "13.5"
  username               = "postgres"
  password               = random_password.rds.result
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  publicly_accessible    = false
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "rds" {
  name       = "main"
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]

}

resource "random_password" "rds" {
  length  = 32
  upper   = true
  lower   = true
  numeric = true
  special = false

}

resource "aws_secretsmanager_secret" "rds_credentials" {
name = "${var.db_name}-credentials-5"
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    "user" : "postgres",
    "password" : random_password.rds.result,
    "name" : "rates",
    "host" : aws_db_instance.rds.address
  })
}

# data "aws_secretsmanager_secret" "secrets" {
#   arn = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${aws_secretsmanager_secret.rds_credentials.name}"
# }

# data "aws_secretsmanager_secret_version" "current" {
#   secret_id = data.aws_secretsmanager_secret.secrets.id
# }

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}



resource "aws_security_group" "rds_sg" {
  name        = "rds-postgres-sg"
  description = "Allow PostgreSQL access"
  vpc_id      = data.aws_vpc.default.id

  ingress { #inside
    description     = "Postgres access from Fargate"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.fargate_sg.id]
  }

  egress { #outside
    from_port   = 0
    to_port     = 0
    protocol    = "-1" #any protocol
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_db_subnet_group" "default" {
  name       = "default-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}


resource "aws_db_instance" "postgres" {
  identifier     = "my-postgres-db"
  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"

  allocated_storage = 20

  db_name  = "postgres"
  username = "udagram_user"
  password = "password"

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true

  multi_az = false
}


output "db_endpoint" {
  value = aws_db_instance.postgres.endpoint
}
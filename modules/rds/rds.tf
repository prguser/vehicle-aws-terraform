provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
}

# Security Group para o RDS PostgreSQL
resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_sg.id]  # Permite tráfego apenas do EKS
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# Security Group para o EKS (já configurado)
resource "aws_security_group" "eks_sg" {
  name_prefix = "eks_sg"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Permite acesso a todos na VPC (ou refinar a regra)
  }
}

# Subnet Group para o RDS (aponta para subnets privadas)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "rds-subnet-group"
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "rds_postgres" {
  identifier             = "education"
  allocated_storage    = 5  # Tamanho do disco (GB)
  engine               = "postgresql"
  engine_version       = "14.4"
  instance_class       = "db.t3.micro"  # Tipo da instância (alterar conforme necessidade)
  db_name              = "pedidos"  # Nome da base de dados
  username             = "admin"  # Usuário administrador
  password             = "mypassword"  # Senha (recomenda-se usar Terraform Secrets para senhas)
  parameter_group_name = "default.postgres13"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]  # Referencia o SG configurado acima
  skip_final_snapshot  = true  # Evita tirar snapshot final quando o DB é deletado

  tags = {
    Name = "my-postgres-db"
  }
}

# Outputs
output "rds_endpoint" {
  value = aws_db_instance.rds_postgres.endpoint
}

output "rds_db_name" {
  value = aws_db_instance.rds_postgres.db_name
}

output "rds_username" {
  value = aws_db_instance.rds_postgres.username
}

output "rds_password" {
  value = aws_db_instance.rds_postgres.password
}

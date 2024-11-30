# Provider
provider "aws" {
  region = "us-east-1"
}

# VPC
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

# Security Group para EKS (Permitir HTTP entre os serviços)
resource "aws_security_group" "eks_sg" {
  name_prefix = "eks_sg"
  vpc_id      = module.vpc.vpc_id

  # Regras de saída para todos os destinos
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir tráfego HTTP (porta 80) entre serviços no cluster
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Permitir tráfego HTTPS (porta 443) entre serviços no cluster
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# IAM Role para o Cluster EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks_cluster_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Policies para o Cluster EKS
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# IAM Role para Node Group EKS
resource "aws_iam_role" "eks_node_role" {
  name = "eks_node_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Policies para Node Group EKS
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ec2_container_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ecr_full_access" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# Policy para DynamoDB e SQS
resource "aws_iam_policy" "eks_access_policy" {
  name        = "eks-access-policy"
  description = "Policy to allow EKS to access DynamoDB, SQS, and RDS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ],
        Resource = "arn:aws:dynamodb:us-east-1:*:table/*"
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility"
        ],
        Resource = "arn:aws:sqs:us-east-1:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "rds:Connect"
        ],
        Resource = "arn:aws:rds:us-east-1:*:db/*"
      }
    ]
  })
}

# Attach IAM Policy to Node Role
resource "aws_iam_role_policy_attachment" "eks_node_policy_attachment" {
  policy_arn = aws_iam_policy.eks_access_policy.arn
  role       = aws_iam_role.eks_node_role.name
}

# Cluster EKS
resource "aws_eks_cluster" "eks_cluster" {
  name     = "eks-cluster-aws-fiap"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.eks_sg.id]
  }
}

# Node Group para EKS
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "example-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]
}

# Outputs
output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_security_group_id" {
  value = aws_security_group.eks_sg.id
}

output "eks_node_group_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "eks_node_group_name" {
  value = aws_eks_node_group.eks_node_group.node_group_name
}

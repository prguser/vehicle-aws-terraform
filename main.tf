provider "aws" {
  region  =  "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.61.0"
    }
  }

}

module "dynamo" {
  source = "./modules/dynamo"
}

module "eks" {
  source = "./modules/eks"
}

module "ecr" {
  source = "./modules/ecr"
}

module "rds" {
  source = "./modules/rds"
}




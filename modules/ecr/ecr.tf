provider "aws" {
  region = "us-east-1"
}

# Repositório ECR para ms-vehicle-core-service
resource "aws_ecr_repository" "ms_vehicle_core_service" {
  name                 = "ms-vehicle-core-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Repositório ECR para ms-vehicle-sales-service
resource "aws_ecr_repository" "ms_vehicle_sales_service" {
  name                 = "ms-vehicle-sales-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Outputs para exibir as URLs dos repositórios ECR

output "ms_vehicle_core_service_repository_url" {
  value = aws_ecr_repository.ms_vehicle_core_service.repository_url
}

output "ms_vehicle_sales_service_repository_url" {
  value = aws_ecr_repository.ms_vehicle_sales_service.repository_url
}

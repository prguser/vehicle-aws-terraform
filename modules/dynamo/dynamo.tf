provider "aws" {
  region = "us-east-1"
}

# Tabela DynamoDB para pagamentos
resource "aws_dynamodb_table" "payments_table" {
  name           = "payments-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "id" # Chave de partição

  attribute {
    name = "id"
    type = "S" # Tipo String
  }

  attribute {
    name = "cpf"
    type = "S" # Tipo String
  }

  global_secondary_index {
    name               = "cpf-index"
    hash_key           = "cpf"
    projection_type    = "ALL"
    read_capacity      = 2
    write_capacity     = 2
  }

  tags = {
    Name        = "PaymentsDynamoDBTable"
    Environment = "dev"
  }
}

# Tabela DynamoDB para veículos
resource "aws_dynamodb_table" "vehicles_table" {
  name           = "vehicles-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "vehicleId" # Chave de partição

  attribute {
    name = "vehicleId"
    type = "S" # Tipo String
  }

  attribute {
    name = "status"
    type = "S" # Tipo String
  }

  attribute {
    name = "make"
    type = "S" # Tipo String
  }

  global_secondary_index {
    name               = "status-index"
    hash_key           = "status"
    projection_type    = "ALL"
    read_capacity      = 2
    write_capacity     = 2
  }

  global_secondary_index {
    name               = "make-index"
    hash_key           = "make"
    projection_type    = "ALL"
    read_capacity      = 2
    write_capacity     = 2
  }

  tags = {
    Name        = "VehiclesDynamoDBTable"
    Environment = "dev"
  }
}

# Outputs
output "aws_dynamodb_payments_table_name" {
  value = aws_dynamodb_table.payments_table.name
}

output "aws_dynamodb_vehicles_table_name" {
  value = aws_dynamodb_table.vehicles_table.name
}

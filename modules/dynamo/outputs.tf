output "dynamodb_payments_table_name" {
  description = "Payments Table Name"
  value       = aws_dynamodb_table.payments_table.name
}

output "dynamodb_vehicles_table_name" {
  description = "Vehicles Table Name"
  value       = aws_dynamodb_table.vehicles_table.name
}
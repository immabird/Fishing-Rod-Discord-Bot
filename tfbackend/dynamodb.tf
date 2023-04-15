resource "aws_dynamodb_table" "terraform_backend_store" {
  name           = "Terraform-Backend-Store"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "ProjectKey"

  attribute {
    name = "ProjectKey"
    type = "S"
  }
}

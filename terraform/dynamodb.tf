resource "aws_dynamodb_table" "fishing_rod_bot_data" {
  name           = "Fishing-Rod-Bot-Data"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "ChannelId"

  attribute {
    name = "ChannelId"
    type = "S"
  }
}

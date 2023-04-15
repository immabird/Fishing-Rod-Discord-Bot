data "archive_file" "fishing_rod_bot_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../fishing_rod_bot"
  output_path = "${path.module}/fish.zip"
}

resource "aws_lambda_function" "fishing_rod_bot" {
  function_name    = "Fishing-Rod-Bot"
  description      = "Farms them fishies!"
  role             = aws_iam_role.fishing_rod_bot.arn
  filename         = data.archive_file.fishing_rod_bot_zip.output_path
  source_code_hash = data.archive_file.fishing_rod_bot_zip.output_base64sha256
  handler          = "fish.handler"
  runtime          = "nodejs12.x"
  memory_size      = 128
  timeout          = 10
}

resource "aws_iam_role" "fishing_rod_bot" {
  name = "Fishing-Rod-Bot"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "fishing_rod_bot_dynamodb" {
  name = "Fishing-Rod-Bot-DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action" : [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:dynamodb:us-east-2:969146440405:table/Fishing-Rod-Bot-Data"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fishing_rod_bot_dynamodb" {
  role       = aws_iam_role.fishing_rod_bot.name
  policy_arn = aws_iam_policy.fishing_rod_bot_dynamodb.arn
}

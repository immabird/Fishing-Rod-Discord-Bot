locals {
  fish_folder        = "${path.module}/${var.fishing_rod_bot_code_path}"
  fish_files         = fileset(local.fish_folder, "*.js")
  fish_hashes        = [for file in local.fish_files : sha256(file("${local.fish_folder}/${file}"))]
  fish_hashes_string = join(",", local.fish_hashes)
}

resource "terraform_data" "install_npm_packages" {
  triggers_replace = [
    sha256(file("${local.fish_folder}/package.json")),
    sha256(file("${local.fish_folder}/package-lock.json")),
    sha256(local.fish_hashes_string)
  ]
  provisioner "local-exec" {
    working_dir = local.fish_folder
    command     = "npm install"
  }
}

data "archive_file" "fishing_rod_bot_zip" {
  type        = "zip"
  source_dir  = local.fish_folder
  output_path = "${path.module}/fish.zip"

  depends_on = [
    terraform_data.install_npm_packages
  ]
}

data "aws_ssm_parameter" "discord_api_token" {
  name            = var.discord_api_token_ssm_path
  with_decryption = false
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

  environment {
    variables = {
      "DISCORD_API_TOKEN" = data.aws_ssm_parameter.discord_api_token.value
    }
  }
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

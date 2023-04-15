variable "fishing_rod_bot_code_path" {
  description = "The local path to the fishing rod bot code."
  type        = string
}

variable "discord_api_token_ssm_path" {
  description = "The path to the discord API token in SSM parameter store."
  type        = string
}

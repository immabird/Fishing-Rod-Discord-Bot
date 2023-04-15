resource "aws_cloudwatch_event_rule" "every_1_minute" {
  name                = "every-1-minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "trigger_fishing_rod_bot" {
  rule      = aws_cloudwatch_event_rule.every_1_minute.name
  target_id = aws_lambda_function.fishing_rod_bot.id
  arn       = aws_lambda_function.fishing_rod_bot.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_fishing_rod_bot" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fishing_rod_bot.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_1_minute.arn
}

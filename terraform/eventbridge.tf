# 1. The Rule: Watches for our incident pattern
resource "aws_cloudwatch_event_rule" "incident_rule" {
  name        = "auto-remediation-incident-rule"
  description = "Triggers remediation Lambda on specific incident events"

  event_pattern = jsonencode({
    source      = ["custom.incident"]
    detail-type = ["EC2 Down"]
  })
}

# 2. The Target: Sends matching events to your Lambda
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.incident_rule.name
  target_id = "TriggerRemediationLambda"
  arn       = aws_lambda_function.remediation_fn.arn
}

# 3. The Permission: Unlocks Lambda so EventBridge is allowed to call it
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remediation_fn.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.incident_rule.arn
}

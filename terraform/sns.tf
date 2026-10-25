resource "aws_sns_topic" "incident_alerts" {
  name = "auto-remediation-alerts-dev"
}

output "sns_topic_arn" {
  value = aws_sns_topic.incident_alerts.arn
}
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.incident_alerts.arn
  protocol  = "email"
  endpoint  = "fpourooshasb@gmail.com"
}
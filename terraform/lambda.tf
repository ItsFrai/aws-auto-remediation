# 1. Package the local Python code into a zip archive
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/handler.py"
  output_path = "${path.module}/handler.zip"
}

# 2. IAM Role: Trust policy allowing the Lambda service to assume this execution role
resource "aws_iam_role" "lambda_exec_role" {
  name = "auto-remediation-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 3. IAM Policy: Grants permission to write CloudWatch logs and publish to your SNS topic
resource "aws_iam_role_policy" "lambda_policy" {
  name = "auto-remediation-lambda-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CloudWatchLogging"
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid      = "SNSPublish"
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.incident_alerts.arn
      },
      {
        Sid      = "EC2Remediation"
        Effect   = "Allow"
        Action   = [
          "ec2:StartInstances",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# 4. Lambda Function: Provisions the runtime and sets the environment variable
resource "aws_lambda_function" "remediation_fn" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "auto-remediation-handler-dev"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 15

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.incident_alerts.arn
    }
  }
}

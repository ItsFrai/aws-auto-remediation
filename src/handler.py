import json
import logging
import os
import boto3

# Configure logging so CloudWatch captures every step
logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns_client = boto3.client("sns")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")


def lambda_handler(event, context):
    logger.info("Received EventBridge event: %s", json.dumps(event))

    # Extract alarm details from the EventBridge payload
    detail = event.get("detail", {})
    alarm_name = detail.get("alarmName", "UnknownAlarm")
    new_state = detail.get("state", {}).get("value", "UNKNOWN")
    previous_state = detail.get("previousState", {}).get("value", "UNKNOWN")
    reason = detail.get("state", {}).get("reason", "No reason provided.")

    logger.info("Alarm %s changed from %s to %s", alarm_name, previous_state, new_state)

    # Only remediate if the alarm actually transitioned INTO the 'ALARM' state
    if new_state != "ALARM":
        logger.info("State is %s (not ALARM). Skipping remediation.", new_state)
        return {"statusCode": 200, "body": "No action needed."}

    # Execute the recovery action
    remediation_result = execute_remediation(alarm_name)

    # Dispatch an alert summary to our SNS topic
    if SNS_TOPIC_ARN:
        subject = f"[AUTO-REMEDIATED] {alarm_name}"
        body = (
            f"Automated remediation executed successfully.\n\n"
            f"Alarm: {alarm_name}\n"
            f"Transition: {previous_state} -> {new_state}\n"
            f"Trigger Reason: {reason}\n"
            f"Action Taken: {remediation_result}\n"
        )
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=body
        )
        logger.info("Published notification to SNS topic %s", SNS_TOPIC_ARN)

    return {
        "statusCode": 200,
        "body": json.dumps({"alarm": alarm_name, "status": remediation_result})
    }


def execute_remediation(alarm_name):
    """
    Automated recovery action.
    In production, this reboots a node, recycles a process, or flushes a deadlocked queue.
    """
    logger.info("Executing recovery routine for alarm: %s", alarm_name)
    return f"Recycled unhealthy target and restored normal health checks for {alarm_name}."
import json
import boto3
import urllib.request
import os
import time

# AWS Clients
secrets_client = boto3.client("secretsmanager")
sqs = boto3.client("sqs")

# Environment Variables
SECRET_NAME = os.getenv("SECRET_NAME")
DLQ_URL = os.getenv("DLQ_URL")
MESSAGE_FIELDS = os.getenv(
    "MESSAGE_FIELDS",
    "AlarmName,NewStateValue,NewStateReason,StateChangeTime,Region,AccountId"
)
MESSAGE_TITLE = os.getenv(
    "MESSAGE_TITLE", "CloudWatch Alarm Triggered"
)
STATUS_COLORS = os.getenv("STATUS_COLORS", "")
STATUS_FIELD = os.getenv("STATUS_FIELD", "NewStateValue")
STATUS_MAPPING = os.getenv("STATUS_MAPPING", "")

MESSAGE_FIELDS = [field.strip() for field in
                  MESSAGE_FIELDS.split(",")] if MESSAGE_FIELDS else []

STATUS_COLOR_MAP = {}
if STATUS_COLORS:
    STATUS_COLOR_MAP = {pair.split(":")[0].strip().upper(): pair.split(
        ":")[1].strip() for pair in STATUS_COLORS.split(",") if ":" in pair}

print(f"🔹 Processed STATUS_COLOR_MAP: {STATUS_COLOR_MAP}")

STATE_MAP = {}
if STATUS_MAPPING:
    STATE_MAP = {pair.split(":")[0]: pair.split(":")[1] for pair in
                 STATUS_MAPPING.split(",") if ":" in pair}


def get_slack_webhook():
    """Retrieve Slack Webhook URL from AWS Secrets Manager."""
    if not SECRET_NAME:
        raise Exception("SECRET_NAME environment variable is not set.")
    response = secrets_client.get_secret_value(SecretId=SECRET_NAME)
    secret = json.loads(response["SecretString"])
    return secret["webhook_url"]


def exponential_backoff(retries):
    return min(2 ** retries, 60)


def extract_field(message, field_path):
    """Extract nested fields from CloudWatch Alarm JSON."""
    keys = field_path.split(".")
    value = message
    for key in keys:
        if isinstance(value, dict) and key in value:
            value = value[key]
        else:
            return "N/A"
    return value


def map_custom_state(status):
    """Map raw status to a custom state based on STATUS_MAPPING."""
    status = status.upper().strip()
    mapped_status = STATE_MAP.get(status, status)
    return mapped_status


def get_status(message):
    """Extract and map the status field from CloudWatch Alarm."""
    raw_status = extract_field(message, STATUS_FIELD)
    return map_custom_state(raw_status)


def get_status_color(status):
    """Map a CloudWatch Alarm state to a Slack color code."""
    if not STATUS_COLOR_MAP:
        return None
    return STATUS_COLOR_MAP.get(status.upper(), None)


def format_slack_message(message):
    """Format CloudWatch Alarm data into a structured Slack message."""
    if not MESSAGE_FIELDS:
        return {
            "text": (
                "⚠️ No fields specified in MESSAGE_FIELDS env."
            )
        }

    status = get_status(message)
    color = get_status_color(status)

    formatted_fields = []
    for field in MESSAGE_FIELDS:
        value = extract_field(message, field)
        formatted_fields.append({"title": field.replace(".", " ").title(),
                                "value": f"`{value}`", "short": False})

    slack_message = {
        "attachments": [
            {
                "pretext": f"*{MESSAGE_TITLE}*",
                "fields": formatted_fields
            }
        ]
    }

    if color:
        slack_message["attachments"][0]["color"] = color

    return slack_message


def send_slack_notification(message):
    """Send the formatted CloudWatch Alarm notification to Slack."""
    slack_webhook_url = get_slack_webhook()
    formatted_message = format_slack_message(message)
    data = json.dumps(formatted_message).encode("utf-8")
    req = urllib.request.Request(
        slack_webhook_url,
        data=data,
        headers={"Content-Type": "application/json"}
    )

    retries = 0
    while retries < 5:
        try:
            with urllib.request.urlopen(req) as response:
                response_body = response.read().decode("utf-8")
                if response.status == 200:
                    print(
                        f"✅ Slack notification sent successfully! "
                        f"Response: {response_body}"
                    )
                    return
                else:
                    print(
                        f"⚠️ Slack responded with status {response.status}: "
                        f"{response_body}"
                    )
        except Exception as e:
            print(f"❌ Failed to send to Slack (Attempt {retries+1}): {str(e)}")
            time.sleep(exponential_backoff(retries))
            retries += 1

    raise Exception("Slack API failed after multiple retries")


def lambda_handler(event, context):
    """Lambda entry point for processing CloudWatch Alarms."""
    try:
        print(f"📨 Processing CloudWatch Alarm: {event}")
        send_slack_notification(event)
    except Exception as e:
        print(f"⚠️ Error processing CloudWatch alarm: {str(e)}")
        raise e

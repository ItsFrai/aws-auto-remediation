\# Event-Driven AWS Auto-Remediation Engine



A serverless, event-driven cloud incident remediation pipeline built with Terraform, AWS Lambda (Python 3.12), Amazon EventBridge, and SNS. The pipeline ingests infrastructure state changes, executes remediation actions via `boto3`, and broadcasts incident reports.



\---



\## Architecture Overview



```text

&#x20;      \[ Incident Event Trigger ]

&#x20;                  │

&#x20;                  ▼

&#x20;      \[ Amazon EventBridge ]

&#x20;     (Pattern Matching Filter)

&#x20;                  │

&#x20;                  ▼

&#x20;         \[ AWS Lambda ]

&#x20;  (Python 3.12 / Boto3 Handler)

&#x20;        │               │

&#x20;        ▼               ▼

\[ EC2 API Action ]  \[ SNS Alert ]

(Restart Instance)  (Email Broadcast)


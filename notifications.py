import requests
import os
from dotenv import load_dotenv

load_dotenv()

SENDGRID_API_KEY = os.environ['SENDGRID_API_KEY']
SENDGRID_FROM_EMAIL = os.environ.get('SENDGRID_FROM_EMAIL', 'noreply@acmecorp.com')
SENDGRID_API_URL = "https://api.sendgrid.com/v3/mail/send"

def send_payment_confirmation(to_email, amount, transaction_id):
    headers = {
        "Authorization": f"Bearer {SENDGRID_API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "personalizations": [{"to": [{"email": to_email}]}],
        "from": {"email": SENDGRID_FROM_EMAIL},
        "subject": f"Payment Confirmation — {transaction_id}",
        "content": [{"type": "text/plain", "value": f"Your payment of ${amount} was processed."}]
    }
    response = requests.post(SENDGRID_API_URL, json=payload, headers=headers)
    return response.status_code == 202

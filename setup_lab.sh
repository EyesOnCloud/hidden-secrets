#!/bin/bash

set -e

echo "[*] Setting up Secrets in a Codebase"
echo "[*] Building fake repository with deliberate secrets buried in history..."

# Create the lab working directory
mkdir -p ~/secrets
cd ~/secrets

# Initialize git
git init
git config user.email "developer@acmecorp.internal"
git config user.name "Dev Bot"

echo "[*] Creating initial project structure..."

# ─────────────────────────────────────────────
# COMMIT 1 — Project scaffold (clean)
# ─────────────────────────────────────────────
mkdir -p src config tests

cat > README.md << 'EOF'
# AcmeCorp Payment API

Internal payment processing service for AcmeCorp.

## Setup
Copy .env.example to .env and fill in your credentials.
Run: pip install -r requirements.txt
Run: python src/app.py
EOF

cat > requirements.txt << 'EOF'
flask==3.0.3
boto3==1.34.0
psycopg2-binary==2.9.9
stripe==8.0.0
pyjwt==2.8.0
python-dotenv==1.0.1
requests==2.31.0
EOF

cat > .env.example << 'EOF'
# Copy this file to .env and fill in real values
# NEVER commit .env to git

DATABASE_URL=postgresql://user:password@localhost:5432/dbname
AWS_ACCESS_KEY_ID=your-access-key-here
AWS_SECRET_ACCESS_KEY=your-secret-key-here
STRIPE_SECRET_KEY=your-stripe-key-here
JWT_SECRET=your-jwt-secret-here
SENDGRID_API_KEY=your-sendgrid-key-here
EOF

git add .
git commit -m "Initial project scaffold and README"

echo "[*] Commit 1 done — Project scaffold"

# ─────────────────────────────────────────────
# COMMIT 2 — Developer hardcodes DB creds (SECRET 1)
# ─────────────────────────────────────────────
cat > src/database.py << 'EOF'
import psycopg2

# TODO: Move this to environment variables before prod deploy
DB_HOST = "db.acmecorp.internal"
DB_PORT = 5432
DB_NAME = "payments_prod"
DB_USER = "payments_app"
DB_PASSWORD = "Tr0ub4dor&3_prod_2023"

def get_connection():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

def run_query(query, params=None):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(query, params)
    conn.commit()
    cur.close()
    conn.close()
EOF

cat > src/app.py << 'EOF'
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "ok"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

git add .
git commit -m "Add database connection module"

echo "[*] Commit 2 done — SECRET 1 planted (DB password in source)"

# ─────────────────────────────────────────────
# COMMIT 3 — AWS integration with hardcoded keys (SECRET 2 + 3)
# ─────────────────────────────────────────────
cat > src/aws_helper.py << 'EOF'
import boto3

# AWS credentials — DO NOT SHARE
# These are for the payments-processor IAM user
AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLEKEY"
AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY123"
AWS_REGION = "us-east-1"
S3_BUCKET = "acmecorp-payment-receipts-prod"

def get_s3_client():
    return boto3.client(
        's3',
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
        region_name=AWS_REGION
    )

def upload_receipt(file_path, key):
    client = get_s3_client()
    client.upload_file(file_path, S3_BUCKET, key)
    return f"s3://{S3_BUCKET}/{key}"

def list_receipts(prefix=""):
    client = get_s3_client()
    response = client.list_objects_v2(Bucket=S3_BUCKET, Prefix=prefix)
    return [obj['Key'] for obj in response.get('Contents', [])]
EOF

git add .
git commit -m "Add AWS S3 integration for receipt storage"

echo "[*] Commit 3 done — SECRETS 2+3 planted (AWS keys in source)"

# ─────────────────────────────────────────────
# COMMIT 4 — Stripe and JWT secrets in config (SECRET 4 + 5)
# ─────────────────────────────────────────────
cat > config/settings.py << 'EOF'
# Application configuration
# Last updated: 2023-11-15 by dev-team

class ProductionConfig:
    DEBUG = False
    TESTING = False

    # Stripe payment processing
    STRIPE_PUBLIC_KEY = "pk_live_51H2kJKLmnOpQrStUvWxYz0123456789abcdefghijk"
    STRIPE_SECRET_KEY = "sk_live_51H2kJKLmnOpQrStUvWxYzABCDEFGHIJKLMNOPQRSTUVWXYZ01"
    STRIPE_WEBHOOK_SECRET = "whsec_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwx"

    # JWT signing — rotate every 90 days
    JWT_SECRET_KEY = "super_secret_jwt_key_acmecorp_payments_do_not_share_2023"
    JWT_ALGORITHM = "HS256"
    JWT_EXPIRY_HOURS = 24

class DevelopmentConfig:
    DEBUG = True
    STRIPE_SECRET_KEY = "sk_test_51H2kJKLmnOpQrStUvWxYzTESTKEYFORDEVONLY1234567890"
    JWT_SECRET_KEY = "dev_only_jwt_secret_not_for_prod"
EOF

git add .
git commit -m "Add application configuration for production and development"

echo "[*] Commit 4 done — SECRETS 4+5 planted (Stripe + JWT in config)"

# ─────────────────────────────────────────────
# COMMIT 5 — SendGrid key in notification service (SECRET 6)
# ─────────────────────────────────────────────
cat > src/notifications.py << 'EOF'
import requests

SENDGRID_API_KEY = "SG.ABCDEFGHIJKLMNOPQRSTUVWXabcdefghijklmnopqrstuvwx1234567890AB"
SENDGRID_FROM_EMAIL = "payments@acmecorp.com"
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
EOF

git add .
git commit -m "Add SendGrid notification service for payment confirmations"

echo "[*] Commit 5 done — SECRET 6 planted (SendGrid API key)"

# ─────────────────────────────────────────────
# COMMIT 6 — Developer "fixes" the issue — removes DB creds and AWS keys
# This is what participants will find in git history
# ─────────────────────────────────────────────
cat > src/database.py << 'EOF'
import psycopg2
import os

def get_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        port=os.environ.get('DB_PORT', 5432),
        dbname=os.environ['DB_NAME'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD']
    )

def run_query(query, params=None):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(query, params)
    conn.commit()
    cur.close()
    conn.close()
EOF

cat > src/aws_helper.py << 'EOF'
import boto3
import os

AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')
S3_BUCKET = os.environ.get('S3_BUCKET', 'acmecorp-payment-receipts-prod')

def get_s3_client():
    # Credentials loaded automatically from environment / IAM role
    return boto3.client('s3', region_name=AWS_REGION)

def upload_receipt(file_path, key):
    client = get_s3_client()
    client.upload_file(file_path, S3_BUCKET, key)
    return f"s3://{S3_BUCKET}/{key}"

def list_receipts(prefix=""):
    client = get_s3_client()
    response = client.list_objects_v2(Bucket=S3_BUCKET, Prefix=prefix)
    return [obj['Key'] for obj in response.get('Contents', [])]
EOF

git add .
git commit -m "Security fix: remove hardcoded credentials, use environment variables"

echo "[*] Commit 6 done — Developer 'fixed' DB and AWS (secrets still in history)"

# ─────────────────────────────────────────────
# COMMIT 7 — .env file accidentally committed (SECRET 7 + 8)
# Developer creates a real .env and forgets to gitignore it first
# ─────────────────────────────────────────────
cat > .env << 'EOF'
DATABASE_URL=postgresql://payments_app:Tr0ub4dor&3_prod_2023@db.acmecorp.internal:5432/payments_prod
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLEKEY
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY123
STRIPE_SECRET_KEY=sk_live_51H2kJKLmnOpQrStUvWxYzABCDEFGHIJKLMNOPQRSTUVWXYZ01
JWT_SECRET=super_secret_jwt_key_acmecorp_payments_do_not_share_2023
SENDGRID_API_KEY=SG.ABCDEFGHIJKLMNOPQRSTUVWXabcdefghijklmnopqrstuvwx1234567890AB
TWILIO_ACCOUNT_SID=ACabcdefghijklmnopqrstuvwxyz012345
TWILIO_AUTH_TOKEN=abcdef1234567890abcdef1234567890
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
EOF

git add .env
git commit -m "Add environment configuration"

echo "[*] Commit 7 done — SECRETS 7+8 planted (.env file committed)"

# ─────────────────────────────────────────────
# COMMIT 8 — Developer realizes .env was committed, removes it
# But the damage is done — it is in history
# ─────────────────────────────────────────────
echo ".env" > .gitignore
echo "*.pyc" >> .gitignore
echo "__pycache__/" >> .gitignore
echo ".DS_Store" >> .gitignore

git rm --cached .env
git add .gitignore
git commit -m "Remove .env from tracking, add .gitignore"

echo "[*] Commit 8 done — .env removed from tracking (still in history)"

# ─────────────────────────────────────────────
# COMMIT 9 — Add a test file with a secret in a comment (SECRET 9)
# ─────────────────────────────────────────────
cat > tests/test_payments.py << 'EOF'
import unittest

# Temporary test credentials — remove before merge
# DB: postgresql://payments_app:Tr0ub4dor&3_prod_2023@db.acmecorp.internal/payments_prod
# These were used for the load test on 2023-12-01, keeping for reference

class TestPaymentFlow(unittest.TestCase):

    def test_health_endpoint(self):
        # Basic smoke test
        self.assertTrue(True)

    def test_placeholder(self):
        # TODO: implement actual payment flow tests
        pass

if __name__ == '__main__':
    unittest.main()
EOF

git add .
git commit -m "Add placeholder test suite"

echo "[*] Commit 9 done — SECRET 9 planted (credentials in a comment)"

# ─────────────────────────────────────────────
# COMMIT 10 — Final state — current HEAD looks mostly clean
# ─────────────────────────────────────────────
cat > src/app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "ok", "version": "2.1.0"})

@app.route('/ready')
def ready():
    return jsonify({"ready": True})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
EOF

git add .
git commit -m "Finalize app entrypoint with readiness probe"

echo ""
echo "Repository created at ~/secrets"
echo "Git history has $(git rev-list --count HEAD) commits"
echo "$(git log --oneline | wc -l) commits in log"
echo ""
echo "Secrets deliberately planted:"
echo "  SECRET 1  — Hardcoded DB password in src/database.py (old commit)"
echo "  SECRET 2  — AWS Access Key ID in src/aws_helper.py (old commit)"
echo "  SECRET 3  — AWS Secret Access Key in src/aws_helper.py (old commit)"
echo "  SECRET 4  — Stripe live secret key in config/settings.py (current file)"
echo "  SECRET 5  — JWT signing key in config/settings.py (current file)"
echo "  SECRET 6  — SendGrid API key in src/notifications.py (current file)"
echo "  SECRET 7  — Full .env file committed (old commit, removed later)"
echo "  SECRET 8  — Twilio + Slack credentials in .env (old commit)"
echo "  SECRET 9  — DB credentials in a test file comment (current file)"
echo ""

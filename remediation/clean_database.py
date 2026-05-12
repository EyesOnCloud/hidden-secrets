import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

def get_connection():
    """
    Correct pattern: all credentials sourced from environment variables.
    Never hardcode credentials in source files.
    """
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        port=os.environ.get('DB_PORT', 5432),
        dbname=os.environ['DB_NAME'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD']
    )

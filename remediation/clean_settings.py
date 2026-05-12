import os
from dotenv import load_dotenv

load_dotenv()

class ProductionConfig:
    DEBUG = False

    STRIPE_PUBLIC_KEY = os.environ['STRIPE_PUBLIC_KEY']
    STRIPE_SECRET_KEY = os.environ['STRIPE_SECRET_KEY']
    STRIPE_WEBHOOK_SECRET = os.environ['STRIPE_WEBHOOK_SECRET']

    JWT_SECRET_KEY = os.environ['JWT_SECRET_KEY']
    JWT_ALGORITHM = os.environ.get('JWT_ALGORITHM', 'HS256')
    JWT_EXPIRY_HOURS = int(os.environ.get('JWT_EXPIRY_HOURS', 24))

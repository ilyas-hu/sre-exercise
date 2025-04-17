import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from dotenv import load_dotenv
import urllib.parse

import logging

load_dotenv()

logger = logging.getLogger(__name__)

db_url = os.getenv("DATABASE_URL")
db_port = os.getenv("DATABASE_PORT")
db_name= os.getenv("DATABASE_NAME")
db_user = os.getenv("DATABASE_USER")
db_password = os.getenv("DATABASE_PASSWORD")

if db_password:
    logger.info("Using Password Authentication for database connection.")
    # URL encode user and password in case they contain special characters
    encoded_user = urllib.parse.quote_plus(db_user)
    encoded_password = urllib.parse.quote_plus(db_password)
    SQLALCHEMY_DATABASE_URL = f"postgresql+psycopg2://{encoded_user}:{encoded_password}@{db_url}:{db_port}/{db_name}"

else:
    # === IAM Authentication (e.g., GKE via Proxy) ===
    logger.info("Using IAM Authentication (no password) for database connection.")
    # URL encode the GSA email (username) because it contains '@'
    encoded_user = urllib.parse.quote_plus(db_user)
    SQLALCHEMY_DATABASE_URL = f"postgresql+psycopg2://{encoded_user}@{db_url}:{db_port}/{db_name}"

logger.info(f"Database URL configured: postgresql+psycopg2://****:****@{db_url}:{db_port}/{db_name}") # Log without credentials

if not SQLALCHEMY_DATABASE_URL:
    raise ValueError("No DATABASE_URL environment variable set")

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
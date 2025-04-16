import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from dotenv import load_dotenv

load_dotenv()


db_url = os.getenv("DATABASE_URL")
db_port = os.getenv("DATABASE_PORT")
db_name= os.getenv("DATABASE_NAME")
db_user = os.getenv("DATABASE_USER")
db_password = os.getenv("DATABASE_PASSWORD")

SQLALCHEMY_DATABASE_URL = f'postgresql+psycopg2://{db_user}:{db_password}@{db_url}:{db_port}/{db_name}'

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
from sqlalchemy.orm import Session
from . import models, schemas
from datetime import date

def get_user(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first()

def create_or_update_user(db: Session, username: str, dob: date):
    db_user = get_user(db, username)
    if db_user:
        # Update existing user
        db_user.date_of_birth = dob
    else:
        # Create new user
        db_user = models.User(username=username, date_of_birth=dob)
        db.add(db_user)
    db.commit()
    return db_user 
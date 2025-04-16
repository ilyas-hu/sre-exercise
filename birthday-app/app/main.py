from fastapi import FastAPI, Depends, HTTPException, Path, Response, status
from sqlalchemy.orm import Session
from sqlalchemy import text # Needed for DB health check later
from datetime import date

import logging
import sys

logging.basicConfig(
    level=logging.INFO, 
    format='%(asctime)s %(levelname)-8s [%(name)s] %(message)s',
    datefmt='%Y-%m-%dT%H:%M:%S%z',
    stream=sys.stdout,
)

from . import crud, schemas, utils
from .database import get_db

logger = logging.getLogger("app")

app = FastAPI(
    title="Birthday Greeting API",
    description="API to store user birthdays and provide greetings.",
    version="0.1.0"
)

@app.get(
    "/",
    response_model=schemas.MessageResponse,
    summary="Welcome Endpoint",
    tags=["General"]
)
async def index():
    """Returns a simple welcome message."""
    return {"message": "Welcome to the Birthday App!"}


@app.get(
    "/health",
    response_model=schemas.HealthStatus,
    summary="Health Check",
    tags=["General"]
)
async def health_check(
    db: Session = Depends(get_db)
):
    """
    Basic health check. Returns OK if the app is running and can connect to database.
    """
    try:
        # Try a simple query to check DB connection
        db.execute(text("SELECT 1"))
        db_status = "ok"
    except Exception as e:
        db_status = "error"
        logger.error(f"Health check database connection error: {e}", exc_info=True)
        # return status 503 Service Unavailable if DB fails
        # raise HTTPException(status_code=503, detail="Database connection error")

    return {"status": "ok", "db_status": db_status}


@app.put(
    "/hello/{username}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Save or Update User Birthday",
    tags=["User"]
)
async def save_user_dob(
    *,
    db: Session = Depends(get_db),
    username: str = Path(..., pattern=r"^[a-zA-Z]+$", description="Username (letters only)"),
    user_dob: schemas.UserDOB
):
    """
    Saves or updates the user's date of birth.

    - **username**: Must contain only letters (a-z, A-Z).
    - **dateOfBirth**: Must be a date in YYYY-MM-DD format and be *before* today.

    Returns HTTP 204 No Content on success.
    """
    try:
        crud.create_or_update_user(db=db, username=username, dob=user_dob.dateOfBirth)
    except Exception as e:
        logger.error(f"Error saving user for {username}: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process request for user {username}."
        )

    return None


@app.get(
    "/hello/{username}",
    response_model=schemas.BirthdayMessage,
    summary="Get Birthday Greeting",
    tags=["User"]
)
async def get_birthday_message(
    *,
    db: Session = Depends(get_db),
    username: str = Path(..., pattern=r"^[a-zA-Z]+$", description="Username (letters only)")
):
    """
    Retrieves the user from the database and returns a birthday greeting message.

    - **username**: Must contain only letters (a-z, A-Z).

    Returns a personalized birthday message or 404 if the user is not found.
    """
    db_user = crud.get_user(db=db, username=username)
    if db_user is None:
        logger.warning(f"User not found: {username}")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    message = utils.calculate_birthday_message(db_user.username, db_user.date_of_birth)

    return schemas.BirthdayMessage(message=message)
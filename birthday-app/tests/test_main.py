import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport # <--- IMPORT ASGITransport
from fastapi import status
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from datetime import date, timedelta

# Use a separate in-memory SQLite DB for testing
# Or configure to use a separate test Postgres DB if needed
TEST_DATABASE_URL = "sqlite:///./test.db" # In-memory SQLite relative to current dir

engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False}, # Needed for SQLite
    poolclass=StaticPool, # Use static pool for in-memory DB consistency during tests
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Import Base from your models and create tables for the test DB
# Ensure this path is correct relative to where pytest is run (usually project root)
try:
    from app.models import Base
except ImportError:
    # Handle potential import errors if structure differs
    print("Error importing Base from app.models. Adjust import path if necessary.")
    raise

# Ensure tables are created *before* tests run
Base.metadata.create_all(bind=engine)

# Import the FastAPI app instance and the dependency getter
try:
    from app.main import app
    from app.database import get_db
except ImportError:
    print("Error importing app or get_db. Adjust import paths if necessary.")
    raise

# Override the get_db dependency for testing to use the test database
def override_get_db():
    database = TestingSessionLocal()
    try:
        yield database
    finally:
        database.close()

app.dependency_overrides[get_db] = override_get_db

# Fixture to clean up the database *before* each test
@pytest.fixture(scope="function", autouse=True)
def setup_database():
    # Ensures a clean state for every test function
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    # No yield needed here if only setup is required.
    # If teardown per test is needed, put code after yield.

# Test client fixture using pytest-asyncio
@pytest_asyncio.fixture(scope="function") # function scope aligns with event_loop
async def client():
    # Use ASGITransport to route requests directly to the app object
    transport = ASGITransport(app=app) # Pass the FastAPI app instance here
    async with AsyncClient(
        transport=transport, # Use the transport argument
        base_url="http://testserver" # A base URL is required
    ) as ac:
        yield ac # Yield the configured AsyncClient

# --- Test Cases ---
# (Your test cases remain unchanged from the previous version you posted)
# Example test case structure (rest are the same):

@pytest.mark.asyncio
async def test_put_user_success(client: AsyncClient):
    username = "testuser"
    dob = date.today() - timedelta(days=365 * 30) # 30 years ago
    response = await client.put(
        f"/hello/{username}",
        json={"dateOfBirth": dob.isoformat()}
    )
    assert response.status_code == status.HTTP_204_NO_CONTENT

    # Optionally: Verify in DB
    # Note: Using TestingSessionLocal directly creates a separate session
    # It might be cleaner to use the overridden dependency if possible,
    # but this direct check is also valid for verification.
    db = TestingSessionLocal()
    try:
        # Ensure the correct path to your crud functions
        from app.crud import get_user
        user = get_user(db, username=username)
        assert user is not None
        assert user.username == username
        assert user.date_of_birth == dob
    finally:
        db.close()

@pytest.mark.asyncio
async def test_put_user_update(client: AsyncClient):
    username = "updateuser"
    dob1 = date(1990, 5, 15)
    dob2 = date(1991, 6, 16)
    # First PUT
    resp1 = await client.put(f"/hello/{username}", json={"dateOfBirth": dob1.isoformat()})
    assert resp1.status_code == status.HTTP_204_NO_CONTENT # Check first PUT worked

    # Second PUT (update)
    response = await client.put(f"/hello/{username}", json={"dateOfBirth": dob2.isoformat()})
    assert response.status_code == status.HTTP_204_NO_CONTENT

    # Verify updated date
    db = TestingSessionLocal()
    try:
        from app.crud import get_user
        user = get_user(db, username=username)
        assert user is not None
        assert user.date_of_birth == dob2
    finally:
        db.close()


@pytest.mark.asyncio
async def test_put_user_invalid_username(client: AsyncClient):
    username = "testuser123" # Invalid characters
    dob = date(1990, 1, 1)
    response = await client.put(
        f"/hello/{username}",
        json={"dateOfBirth": dob.isoformat()}
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

@pytest.mark.asyncio
async def test_put_user_invalid_date_future(client: AsyncClient):
    username = "futuredatetest"
    dob = date.today() + timedelta(days=10) # Future date
    response = await client.put(
        f"/hello/{username}",
        json={"dateOfBirth": dob.isoformat()}
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    # Check the specific Pydantic/FastAPI error message if needed
    assert "date of birth must be a date before today" in response.text.lower()


@pytest.mark.asyncio
async def test_put_user_invalid_date_today(client: AsyncClient):
    username = "todaydatetest"
    dob = date.today() # Today's date
    response = await client.put(
        f"/hello/{username}",
        json={"dateOfBirth": dob.isoformat()}
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    # Check the specific Pydantic/FastAPI error message if needed
    assert "date of birth must be a date before today" in response.text.lower()


@pytest.mark.asyncio
async def test_get_user_not_found(client: AsyncClient):
    username = "nonexistent"
    response = await client.get(f"/hello/{username}")
    assert response.status_code == status.HTTP_404_NOT_FOUND

@pytest.mark.asyncio
async def test_get_user_birthday_today(client: AsyncClient):
    username = "birthboy"
    # Set DOB to exactly today's date but in a past year
    # Note: Current date is approx April 15, 2025
    dob = date.today().replace(year=date.today().year - 25) # e.g., 2000-04-15
    put_response = await client.put(f"/hello/{username}", json={"dateOfBirth": dob.isoformat()})
    assert put_response.status_code == status.HTTP_204_NO_CONTENT # Ensure user was created

    response = await client.get(f"/hello/{username}")
    assert response.status_code == status.HTTP_200_OK
    assert response.json() == {"message": f"Hello, {username}! Happy birthday!"}

@pytest.mark.asyncio
async def test_get_user_birthday_future(client: AsyncClient):
    username = "futurebirth"
    # Set DOB such that the next birthday is in 10 days (approx April 25)
    today = date.today() # approx 2025-04-15
    ten_days_from_now = today + timedelta(days=10) # approx 2025-04-25
    dob = ten_days_from_now.replace(year=today.year - 30) # e.g., 1995-04-25
    put_response = await client.put(f"/hello/{username}", json={"dateOfBirth": dob.isoformat()})
    assert put_response.status_code == status.HTTP_204_NO_CONTENT # Ensure user was created

    response = await client.get(f"/hello/{username}")
    assert response.status_code == status.HTTP_200_OK
    assert response.json() == {"message": f"Hello, {username}! Your birthday is in 10 days"}

@pytest.mark.asyncio
async def test_get_user_birthday_future_one_day(client: AsyncClient):
    username = "almostbirth"
    # Set DOB such that the next birthday is tomorrow (approx April 16)
    today = date.today() # approx 2025-04-15
    tomorrow = today + timedelta(days=1) # approx 2025-04-16
    dob = tomorrow.replace(year=today.year - 22) # e.g., 2003-04-16
    put_response = await client.put(f"/hello/{username}", json={"dateOfBirth": dob.isoformat()})
    assert put_response.status_code == status.HTTP_204_NO_CONTENT # Ensure user was created

    response = await client.get(f"/hello/{username}")
    assert response.status_code == status.HTTP_200_OK
    assert response.json() == {"message": f"Hello, {username}! Your birthday is in 1 day"}

@pytest.mark.asyncio
async def test_get_user_birthday_passed_this_year(client: AsyncClient):
    username = "birthpassed"
    # Set DOB such that the birthday already passed this year (e.g., 10 days ago - approx April 5)
    today = date.today() # approx 2025-04-15
    ten_days_ago = today - timedelta(days=10) # approx 2025-04-05
    dob = ten_days_ago.replace(year=today.year - 40) # e.g., 1985-04-05
    put_response = await client.put(f"/hello/{username}", json={"dateOfBirth": dob.isoformat()})
    assert put_response.status_code == status.HTTP_204_NO_CONTENT # Ensure user was created

    response = await client.get(f"/hello/{username}")
    assert response.status_code == status.HTTP_200_OK
    # Calculate expected days (days until 2026-04-05 from 2025-04-15)
    next_birthday_year = today.year + 1
    next_birthday = dob.replace(year=next_birthday_year)
    days_remaining = (next_birthday - today).days
    assert response.json() == {"message": f"Hello, {username}! Your birthday is in {days_remaining} days"}
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from fastapi import status
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from datetime import date, timedelta

# Use a separate in-memory SQLite DB for testing
TEST_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

try:
    from app.models import Base
except ImportError:
    print("Error importing Base from app.models")
    raise

Base.metadata.create_all(bind=engine)

try:
    from app.main import app
    from app.database import get_db
except ImportError:
    print("Error importing app or get_db")
    raise

def override_get_db():
    database = TestingSessionLocal()
    try:
        yield database
    finally:
        database.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture(scope="function", autouse=True)
def setup_database():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

@pytest_asyncio.fixture(scope="function")
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(
        transport=transport, 
        base_url="http://testserver" 
    ) as ac:
        yield ac

@pytest.mark.asyncio
async def test_put_user_success(client: AsyncClient):
    username = "testuser"
    dob = date.today() - timedelta(days=365 * 30)
    response = await client.put(
        f"/hello/{username}",
        json={"dateOfBirth": dob.isoformat()}
    )
    assert response.status_code == status.HTTP_204_NO_CONTENT

    db = TestingSessionLocal()
    try:
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

    resp1 = await client.put(f"/hello/{username}", json={"dateOfBirth": dob1.isoformat()})
    assert resp1.status_code == status.HTTP_204_NO_CONTENT

    response = await client.put(f"/hello/{username}", json={"dateOfBirth": dob2.isoformat()})
    assert response.status_code == status.HTTP_204_NO_CONTENT

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
    username = "testuser123"
    dob = date(1990, 1, 1)
    response = await client.put(
        f"/hello/{username}",
        json={"dateOfBirth": dob.isoformat()}
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

@pytest.mark.asyncio
async def test_put_user_invalid_date_future(client: AsyncClient):
    username = "futuredatetest"
    dob = date.today() + timedelta(days=10)
    response = await client.put(
        f"/hello/{username}",
        json={"dateOfBirth": dob.isoformat()}
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    assert "date of birth must be a date before today" in response.text.lower()


@pytest.mark.asyncio
async def test_put_user_invalid_date_today(client: AsyncClient):
    username = "todaydatetest"
    dob = date.today()
    response = await client.put(
        f"/hello/{username}",
        json={"dateOfBirth": dob.isoformat()}
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    assert "date of birth must be a date before today" in response.text.lower()


@pytest.mark.asyncio
async def test_get_user_not_found(client: AsyncClient):
    username = "nonexistent"
    response = await client.get(f"/hello/{username}")
    assert response.status_code == status.HTTP_404_NOT_FOUND

@pytest.mark.asyncio
async def test_get_user_birthday_today(client: AsyncClient):
    username = "birthboy"
    dob = date.today().replace(year=date.today().year - 25)
    put_response = await client.put(f"/hello/{username}", json={"dateOfBirth": dob.isoformat()})
    assert put_response.status_code == status.HTTP_204_NO_CONTENT 

    response = await client.get(f"/hello/{username}")
    assert response.status_code == status.HTTP_200_OK
    assert response.json() == {"message": f"Hello, {username}! Happy birthday!"}

@pytest.mark.asyncio
async def test_get_user_birthday_future(client: AsyncClient):
    username = "futurebirth"

    today = date.today()
    ten_days_from_now = today + timedelta(days=10) 
    dob = ten_days_from_now.replace(year=today.year - 30)
    put_response = await client.put(f"/hello/{username}", json={"dateOfBirth": dob.isoformat()})
    assert put_response.status_code == status.HTTP_204_NO_CONTENT

    response = await client.get(f"/hello/{username}")
    assert response.status_code == status.HTTP_200_OK
    assert response.json() == {"message": f"Hello, {username}! Your birthday is in 10 days"}

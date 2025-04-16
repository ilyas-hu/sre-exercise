from pydantic import BaseModel, Field, field_validator, ConfigDict
from datetime import date

# Schema for PUT request body
class UserDOB(BaseModel):
    dateOfBirth: date

    @field_validator('dateOfBirth')
    def date_must_be_in_past(cls, v):
        if v >= date.today():
            raise ValueError("Date of birth must be a date before today.")
        return v

# Schema for GET response
class BirthdayMessage(BaseModel):
    message: str

# Schema for User data
class UserBase(BaseModel):
    username: str = Field(..., pattern=r"^[a-zA-Z]+$")
    date_of_birth: date

class UserCreate(UserBase):
    pass

class User(UserBase):
    model_config = ConfigDict(
        from_attributes=True
    )

# Schema for index
class MessageResponse(BaseModel):
    message: str

# Schema for Health check
class HealthStatus(BaseModel):
    status: str
    db_status: str
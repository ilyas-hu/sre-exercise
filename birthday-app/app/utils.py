# File for general utility functions
from datetime import date

def calculate_birthday_message(username: str, date_of_birth: date) -> str:
    today = date.today()

    try:
        next_birthday = date_of_birth.replace(year=today.year)
    except ValueError: # Handles Feb 29th on non-leap years
        if date_of_birth.month == 2 and date_of_birth.day == 29:
             next_birthday = date(today.year, 3, 1)

    if next_birthday < today:
        try:
            next_birthday = next_birthday.replace(year=today.year + 1)
        except ValueError: # Handles Feb 29th again for the *next* year check
            if date_of_birth.month == 2 and date_of_birth.day == 29:
                 next_birthday = date(today.year + 1, 3, 1)

    # Check if birthday is today
    if date_of_birth.month == today.month and date_of_birth.day == today.day:
        message = f"Hello, {username}! Happy birthday!"
    else:
        # Calculate days remaining
        days_until_birthday = (next_birthday - today).days
        day_str = "day" if days_until_birthday == 1 else "days"
        message = f"Hello, {username}! Your birthday is in {days_until_birthday} {day_str}"

    return message
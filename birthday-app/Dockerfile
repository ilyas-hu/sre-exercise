FROM python:3.13-slim

WORKDIR /app

# Create a non-root user and group
RUN addgroup --system app && adduser --system --group app

# Add curl (remove procps if no longer needed)
RUN apt-get update && apt-get install -y --no-install-recommends curl && apt-get remove -y procps && rm -rf /var/lib/apt/lists/*

# Copy and Install requirements.txt
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code into the container
COPY . .

# Change ownership to the app user
RUN chown -R app:app /app

# Switch to the non-root user
USER app

# Expose the port the app runs on
EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
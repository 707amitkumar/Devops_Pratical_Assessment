# syntax=docker/dockerfile:1
########################
# Stage 1 — builder
########################
FROM python:3.11-slim as builder
WORKDIR /app

# Install build deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install pip requirements into /install for copying to final
COPY app/requirements.txt .
RUN python -m pip install --upgrade pip
RUN python -m pip install --prefix=/install -r requirements.txt

########################
# Stage 2 — final runtime
########################
FROM python:3.11-slim
WORKDIR /app

# Create non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy app source
COPY app/src ./app
# Set environment
ENV PYTHONUNBUFFERED=1
ENV PORT=5000
ENV PATH=/usr/local/bin:$PATH

# Allow non-root user to own app
RUN chown -R appuser:appgroup /app
USER appuser

# Expose port
EXPOSE 5000

# Use gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app.app:app", "--workers", "2", "--threads", "4", "--timeout", "30"]

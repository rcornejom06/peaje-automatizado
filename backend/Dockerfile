FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y build-essential libpq-dev netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY requirements/base.txt /app/requirements/base.txt
COPY requirements/dev.txt /app/requirements/dev.txt
COPY requirements/prod.txt /app/requirements/prod.txt

RUN pip install --upgrade pip \
    && pip install -r /app/requirements/dev.txt

COPY . /app/

EXPOSE 8000
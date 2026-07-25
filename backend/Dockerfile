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
    && pip install -r /app/requirements/prod.txt

COPY . /app/

# Por defecto usa settings de produccion. Render puede sobreescribir esto
# con su propia variable de entorno DJANGO_SETTINGS_MODULE si hiciera falta.
ENV DJANGO_SETTINGS_MODULE=config.settings.prod

EXPOSE 8000

CMD python manage.py migrate --noinput \
    && python manage.py collectstatic --noinput \
    && gunicorn config.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 3
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# tesseract-ocr: el binario real de OCR (en Windows lo tenías instalado aparte).
# libglib2.0-0: dependencia mínima que pide opencv-python-headless en Debian.
RUN apt-get update \
    && apt-get install -y --no-install-recommends tesseract-ocr libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . /app/

EXPOSE 5001

# --workers 1 es OBLIGATORIO (no opcional): este servidor guarda el estado de
# detecciones en variables globales de Python (ultima_deteccion,
# historial_detecciones, tokens JWT). Con más de un worker, gunicorn crea
# procesos separados que NO comparten esa memoria, y /last_detection podría
# responder con datos de un proceso distinto al que registró la detección.
# --threads permite atender varias peticiones a la vez dentro del mismo
# proceso, sin ese problema.
CMD gunicorn app:app --bind 0.0.0.0:${PORT:-5001} --workers 1 --threads 4 --worker-class gthread --timeout 60

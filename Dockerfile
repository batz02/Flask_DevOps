FROM python:3.9-slim

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV FLASK_APP=app.py

WORKDIR /app

# Install dependencies including netcat (nc) for healthcheck if needed
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Copia l'entrypoint e rendilo eseguibile
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 8080

# Usa lo script come entrypoint
ENTRYPOINT ["./entrypoint.sh"]
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8080", "wsgi:app"]
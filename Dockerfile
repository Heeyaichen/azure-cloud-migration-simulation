FROM python:3.9-slim

WORKDIR /app

# Copy SSL certificate
COPY DigiCertGlobalRootCA.crt.pem .

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Production settings comes only from App Service settings
RUN rm -f .env

EXPOSE 5000

CMD ["python", "app.py"]
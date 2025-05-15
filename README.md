# Cloud Migration Simulation

This project simulates migrating an on-premises application to the cloud with public facing services: Azure App Service and Azure Database for MySQL . It includes a Python Flask app that connects to a MySQL database and runs in containers. The application is deployed to Azure using infrastructure-as-code (Terraform) and continuous integration/deployment (GitHub Actions).

![Image](https://github.com/user-attachments/assets/a608919d-2fb1-4317-bf22-5aaa2dcf876d)

## Key Features:

- **Containerized Flask App:**  
  Docker is used to package the Flask application.

- **Azure Container Registry (ACR):**  
  ACR serves as the central repository for storing and managing container images. Azure App Service pulls the Docker image from ACR to deploy your application.
  
- **Managed MySQL Database:**  
  The migration involves moving data from a local MySQL instance to Azure Database for MySQL flexible server with enforced SSL.

- **Azure App Service:**  
  The containerized application is hosted on Azure App Service,providing a scalable, secure and publicly accessible endpoint over HTTPS.

- **Infrastructure as Code:**  
  Terraform automates the provisioning of all required Azure services, ensuring consistent and repeatable deployment.

- **CI/CD Pipeline:**  
  GitHub Actions orchestrates the workflows to automate infrastructure provisioning, container image build & deployment, and database migration.
  
## Project Architecture

```
Local Machine (Docker Containers)
       │      (One-time migration over public internet)
       ▼ 
Azure Database for MySQL (Public endpoint with SSL)
       ▲      (SSL/TLS)
       │  
Azure App Service (Running containerized Flask App)
       │      (SSL/TLS)
       ▼ 
End Users (Access via https://<app-name>.azurewebsites.net)
```

## Project Setup for On-Prem / Local Environment

### 1. Flask App and Python Setup

- **Create a Python Web App:**  
  Use Flask to build your web application[`app.py`](./app.py).

- **Install Dependencies:**  
  Create and activate a virtual environment then run:
  
  ```bash
  pip install -r requirements.txt
  ```

- **Create a .env File:**  
  Place a `.env` file in the project root with your database connection details. Example:
  
  ```dotenv
  MYSQL_HOST=localhost
  MYSQL_USER=your_username
  MYSQL_PASSWORD=your_password
  MYSQL_DB=your_database_name
  SSL_CA=path/to/ssl/cert  # Optional for local development
  ```

### 2. MySQL Database Setup

- **Create a Local Database:**  
  Connect to MySQL and create your database:
  
  ```sql
  mysql -u your_username -p
  
  CREATE DATABASE your_database_name;
  ```

- **Initialize Database Schema:**  
  Import the initial schema and sample data:
  
  ```bash
  mysql -u your_username -p your_database_name < init.sql
  ```

- **Optional – Backup Schema:**  
  Export the database schema for future migration:
  
  ```bash
  mysqldump -u your_username -p --no-data your_database_name > schema.sql
  ```

- **Run the Application:**  
  Start your Flask app locally:
  
  ```bash
  python app.py
  ```
  
  The server should be available at `http://localhost:5000`.

### 3. Docker Support

- **Dockerfile:**  
  Use the provided [Dockerfile](./Dockerfile) to containerize your Flask application.
  
- **Docker Compose:**  
  You may also include a [docker-compose](./docker-compose.yaml) file for local testing/development.

- **Certificates:**  
  Download the [DigiCertGlobalRootCA](./DigiCertGlobalRootCA.crt.pem) certificate and place it in the project root if required.
  ```bash
    curl -o DigiCertGlobalRootCA.crt.pem https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem
  ```

## Cloud Migration Steps

### 1. Azure Provider Authentication

- Log in with Azure CLI:
  
  ```bash
  az login
  ```
  ```powershell
  # pwsh
  $env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)
  ```
  ```bash
  # bash
  export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
  ```

### 2. Provision Infrastructure with Terraform

- **Bootstrap and Main Infrastructure:**
  - Terraform scripts are provided to deploy all required Azure services (App Service, MySQL, ACR, etc.). The Terraform backend is self-managed using Azure Blob Storage. 
  - Refer to [Terraform Bootstrap Module Documentation](./terraform/bootstrap/README.md) & [Terraform Root Module Documentation](./terraform/bootstrap/README.md) for comprehensive guide.

- **Terraform Workflow:**  
  [GitHub Actions workflow](.github\workflows\terraform-infrastructure.yaml) handles:
  - Checkout and Terraform setup.
  - Logging in to Azure using stored credentials.
  - Initializing and applying Terraform configurations.

### 3. Containerize and Push Docker Image

- **Log in to ACR and Build Image:**
  
  ```bash
  az acr login --name <acr-name>
  docker build -t <image-name> .
  docker tag <image-name> <acr-name>.azurecr.io/<image-name>:v1
  docker push <acr-name>.azurecr.io/<image-name>:v1
  ```
- **Assign ACR Pull Role:**  
  Create a new role assignment in the portal or use the following Azure CLI command to assign the AcrPull role to the App Service’s managed identity:
  
  ```bash
  az role assignment create \
    --assignee <APP_SERVICE_PRINCIPAL_ID> \
    --role AcrPull \
    --scope $(az acr show --name <acr-name> --query id --output tsv)
  ```
### 4. Deploy to Azure App Service

- **Configure Deployment:**  
  Set the Deployment Center on Azure App Service to pull images from ACR using a system-assigned managed identity.

- **Update App Settings:**  
  Add the required environment variables (database connection info, etc.) in the App Service configuration.

### 5. Azure Database for MySQL Migration

- **Provision an Azure MySQL Instance:**  
  Create an Azure Database for MySQL – Flexible Server via the Azure CLI or Portal.
  
- **Configure SSL & Firewall Rules:**
  - Azure enforces SSL by default. Ensure your Flask app uses SSL when connecting.
  - Add your local machine’s public IP and restrict access as needed.

### 6. Data Migration

- **Export Local Database Data:**  
  Dump the local MySQL database:
  
  ```bash
  docker exec onprem_mysql mysqldump -u onprem_user -p onprem_password onprem_db > onprem_db.sql
  ```
  
  Or using your local MySQL installation:
  
  ```bash
  mysqldump -u your_username -p onprem_db > onprem_db.sql
  ```
  
- **Import Data into Azure MySQL:**
  
  ```bash
  mysql -h <your-mysql-server-name>.mysql.database.azure.com \
        -u <admin-username> \
        -p \
        --ssl-mode=VERIFY_CA \
        --ssl-ca=DigiCertGlobalRootCA.crt.pem \
        onprem_db < onprem_db.sql
  ```

### 7. CI/CD with GitHub Actions

- **GitHub Workflows:**  
  Workflows are set up to provision infrastructure with Terraform, Docker Build the container image for the application, pushes it to Azure Container Registry (ACR),
  and Migrate the local MySQL Database to Azure Database for MySQL Flexible Server.

- Refer to this [GitHub Actions Workflows Documentation](./.github/workflows/README.md) for the comprehensive guide.

- **Restart App Service:**  
  After deployment, restart the App Service and verify via `https://<app-name>.azurewebsites.net/users`.

## Summary

This project demonstrates a complete migration from a local Python Flask application using MySQL to a fully containerized, cloud-deployed solution on Azure. With Terraform for infrastructure, GitHub Actions for CI/CD, and secure connection configurations, the solution shows modern cloud migration practices.

For any questions or improvements, please refer to the inline comments in the configuration files and scripts.

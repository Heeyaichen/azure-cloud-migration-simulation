# Cloud Migration Infrastructure Module

This Terraform module provisions all the core Azure resources required for this cloud migration project. It sets up a complete environment including a remote backend for Terraform state, container registry for Docker images, a MySQL Flexible Server and database, an App Service Plan and Linux Web App to run our containerized Flask application, firewall rules for secure connectivity, and Application Insights for monitoring.

## Overview

This module is designed to migrate an on-premises Dockerized Flask application with a MySQL database to Azure. The key components include:

- **Remote State Backend**: Stores Terraform state in an Azure Storage Account (configured separately in your bootstrap module).
- **Resource Group**: A logical container for all resources.
- **Container Registry (ACR)**: A private registry (with admin disabled and default network action set to "Allow") to store our Docker images.
- **MySQL Flexible Server & Database**: Provides a managed MySQL service along with a specific database for our application.
- **App Service Plan & Linux Web App**: Hosts our containerized Flask application. The web app is configured with environment variables for database connectivity and a system-assigned managed identity.
- **Firewall Rule for MySQL**: Allows Azure services (such as our App Service) to connect to the MySQL server.
- **Application Insights**: Enables monitoring and diagnostics for the web application.

## Resources Provisioned

1. **Resource Group (`azurerm_resource_group.main`)**  
   - Groups all resources under a common name and location.
   - Uses local variables for naming and tagging.

2. **Container Registry (`azurerm_container_registry.main`)**  
   - Provides a secure, private repository for Docker images.
   - Uses a "Premium" SKU with data endpoint enabled.
   - Configured with `default_action = "Allow"` for network rules.

3. **MySQL Flexible Server (`azurerm_mysql_flexible_server.main`)**  
   - A fully managed MySQL server for cloud database services.
   - Configured with specified SKU, version, and storage settings.
   - Uses admin credentials for authentication (managed via variables).

4. **MySQL Flexible Database (`azurerm_mysql_flexible_database.main`)**  
   - Creates the target database (e.g., `onprem_db`) on the MySQL Flexible Server.
   - Configured with proper charset and collation.

5. **App Service Plan (`azurerm_service_plan.main`)**  
   - Provides the hosting plan for the Linux Web App.
   - Configured with a Basic (B1) tier.

6. **Linux Web App for Containers (`azurerm_linux_web_app.main`)**  
   - Deploys the containerized Flask application.
   - Configured to pull the image from the ACR.
   - Uses environment variables for database connectivity and SSL certificate location.
   - Has a system-assigned managed identity enabled for secure ACR access.

7. **MySQL Flexible Server Firewall Rule (`azurerm_mysql_flexible_server_firewall_rule.app_service`)**  
   - Allows access from Azure services by setting both start and end IP addresses to `0.0.0.0`.

8. **Application Insights (`azurerm_application_insights.main`)**  
   - Provides monitoring and logging for the deployed web application.

## How to Use This Module

1. **Pre-requisites:**
   - Install [Terraform](https://www.terraform.io/downloads.html).
   - Set up an Azure account.
   - Ensure you have created (or bootstrapped) a remote backend for your Terraform state.

2. **Configure Variables:**
   - Update the `terraform.tfvars` file with your environment-specific values such as:
     - `environment` (e.g., "dev")
     - `location` (e.g., "eastus")
     - `mysql_admin_username`
     - `mysql_admin_password`
     - `mysql_database_name`
   - Review `variables.tf` for a full list of required variables.
3. **State Migration Process:**
   - After you have successfully run the bootstrap module to provision the remote backend resources (the storage account, container, and resource group for Terraform state), you need to migrate your local Terraform state to this remote backend. This ensures that your state is stored securely, supports locking, and can be shared across team members and CI/CD pipelines.

- **Steps to Migrate State**

     - After provisioning the remote backend using the bootstrap module, navigate back to the root of your Terraform configuration:
       ```bash
       cd ../
       ```
     - **Initialize and Apply:**
       -  In your module's root directory, run the following command to initialize Terraform in your main configuration and migrate the local state to the remote backend:
       ```bash
         terraform init -migrate-state
         terraform plan
         terraform apply -auto-approve
         ```
       - This will provision all resources in Azure according to your configuration.
     -   **Purpose:**
    
         - **Initialization:** This command downloads the required providers, configures the backend specified in your configuration, and prepares your working directory for further Terraform operations.
        
         - **State Migration:** The `-migrate-state` flag tells Terraform to automatically move your existing local state file to the remote backend (Azure Blob Storage in this case). This process ensures that any resources already managed by Terraform are tracked in the centralized state, enabling state locking and safe concurrent operations.
        
         -  Once initialization and state migration are complete, the `terraform apply`, command reads your configuration files, compares them to the state stored in the remote backend, and provisions or updates resources as necessary. The `-auto-approve` flag bypasses manual confirmation, streamlining the deployment process.


4. **Post-Provisioning:**
   - The Linux Web App is configured to pull the container image from ACR.
   - Verify that your ACR contains the correct Docker image (e.g., `mysql_flask_app:v1`).
   - Ensure that your App Service Application Settings include the necessary connection strings (e.g., `MYSQL_HOST`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DB`, and `SSL_CA`).

5. **Monitoring and Diagnostics:**
   - Use Application Insights to monitor your application.
   - Check the App Service log stream for any runtime issues.

## Additional Notes

- **Remote Backend:**  
  The Terraform state is stored remotely (configured in a separate bootstrap module) to enable state locking and collaboration.

- **Managed Identity:**  
  The Linux Web App uses a system-assigned managed identity to securely pull images from ACR. Ensure you have granted the `AcrPull` role to this identity.

- **Security Considerations:**  
  - For a proof-of-concept, admin credentials may be acceptable; however, for production, consider leveraging Azure AD and Managed Identity for better security.
  - Firewall rules and network settings are configured to allow access from trusted Azure services.

## Conclusion

This module automates the provisioning of essential infrastructure components for migrating an on-premises Flask/MySQL application to Azure. It uses Terraform for infrastructure as code, remote state management, and secure resource provisioning.

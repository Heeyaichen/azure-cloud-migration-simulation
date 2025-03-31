# Terraform Bootstrap Module for Remote State Backend

This module provisions the Azure resources required to host Terraform's remote state. Using Remote backend centralizes and secures the Terraform state file while providing state locking and versioning capabilities.

## Purpose and Use Case

The main goal of this bootstrap module is to set up a secure, centralized storage for the Terraform state file in Azure. By using a remote backend (Azure Blob Storage), you gain several benefits:
  
- **State Centralization:**  
  The Terraform state file is stored in one place, allowing multiple team members or CI/CD pipelines to work on the same infrastructure without conflicts.

- **State Locking:**  
  Remote backends typically support state locking to prevent concurrent modifications, reducing the risk of state corruption.

- **Versioning and Change Tracking:**  
  Using Azure Blob Storage, you can enable versioning and change feed for the state file, which is helpful for auditing and rollback.

- **Security:**  
  The state file can contain sensitive information. Storing it remotely with proper access controls and encryption (e.g., TLS 1.2 minimum) increases security.

## Resources Provisioned

This module provisions the following Azure resources:

1. **Resource Group (`azurerm_resource_group.state`):**  
   A dedicated resource group for Terraform state management.

2. **Storage Account (`azurerm_storage_account.state`):**  
   - Configured with Standard tier and GRS replication.
   - Minimum TLS version is set to TLS1_2 for security.
   - Blob properties enable versioning and change feed to track changes.

3. **Storage Container (`azurerm_storage_container.state`):**  
   - A private container where the Terraform state file (and any state locking data) will be stored.

## How to Use This Module

1. **Configure Variables:**  
   - Update the `terraform.tfvars` file in the root terraform module with appropriate values for your environment (e.g., `environment`, `location`, etc.).
   - Check the `variables.tf` for a list of available variables.

2. **Initialize Terraform:**  
   Run the following command in the `terraform/bootstrap` directory to initialize the backend and providers:
   ```bash
   cd terraform/bootstrap
   terraform init -upgrade

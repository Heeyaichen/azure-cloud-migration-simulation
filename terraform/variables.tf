variable "environment" {
  description = "Deployment environment (Dev/Stage/Prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "centralindia"
}

variable "mysql_admin_password" {
  description = "MySQL administrator password"
  type        = string
  sensitive   = true
}

variable "mysql_admin_username" {
  description = "MySQL administrator username"
  type        = string
}

variable "mysql_database_name" {
  description = "MySQL Database Name"
  type        = string
  default     = "onprem_db"
}


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

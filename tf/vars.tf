################################
# Common
################################

# environment stage
variable "stage" {
  description = "Name of the environment. Supported are dev and prod."
  type        = string
  default     = "demo"
}

# environment number
variable "prefix" {
  description = "Naming prefix"
  type        = string
  default     = "aso-gitops"
}

################################
# Azure Kubernetes Service
################################

variable "kubernetes_version" {
  description = "Specify which Kubernetes release to use. The default used is the latest Kubernetes version available in the region"
  type        = string
  default     = "1.24.6"
}

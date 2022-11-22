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

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Subnet ID for Manager node"
  type        = string
}

variable "private_subnet_ids" {
  description = "Subnet IDs for Worker nodes"
  type        = list(string)
}

variable "manager_key_pair" {
  description = "Key pair for EC2 SSH login"
  type        = string
}


variable "vpc_id" {
  description = "VPC ID for NAT Gateway dependency"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID to associate the NAT Gateway"
  type        = string
}

variable "eip_id" {
  description = "Elastic IP allocation ID"
  type        = string
}

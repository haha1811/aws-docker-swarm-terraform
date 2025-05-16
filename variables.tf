variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  default = "docker-swarm-demo"
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair to use"
}


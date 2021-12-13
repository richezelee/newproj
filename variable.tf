variable "name" {
  description = "the name of stack"
  default     = "terraform"
}

variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "availability_zones" {
  description = " AZs"
  default     = ["us-east-1a","us-east-1b","us-east-1b"]
}

variable "cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "private subnets cidr"
  default     = ["10.0.0.0/20", "10.0.32.0/20", "10.0.64.0/20"]
}

variable "public_subnets" {
  description = "public subnet cidrs"
  default     = ["10.0.16.0/20", "10.0.48.0/20", "10.0.80.0/20"]
}

variable "vpc" {
  description = "vpc Id"
  default     = "vpc-07af23b3ced23b24b"
}

variable "ami" {
  description = "ami Id"
  default     = "ami-0b0af3577fe5e3532"
}

variable "keypair" {
  description = "key pair"
  default     = "terraform-ec2"
}


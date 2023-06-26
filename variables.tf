# variables.tf - Input variable definitions

variable "aws_region" {
  description = "The aws region for this workload"
  type        = string
}

variable "environment" {
  description = "The environment this S3 bucket is for"
  type        = string
}

variable "service_name" {
  description = "The name of the service this S3 bucket is for"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to provision the service in"
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "private_rt_ids" {
  description = "The private route table IDs of the VPC"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "The ids of the private subnets of the VPC"
  type        = list(string)
  default     = []
}

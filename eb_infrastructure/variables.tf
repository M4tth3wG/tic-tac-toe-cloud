variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "min_instance_count" {
  type        = number
  description = "Min instance count in auto scaling group"
  default     = 1
}

variable "max_instance_count" {
  type        = number
  description = "Max instance count in auto scaling group"
  default     = 2
}

variable "environment_variables_map" {
  type        = map(any)
  description = "Map of environment variables"
  default     = {}
}

variable "app_version" {
  type        = string
  description = "Application version name"
  default     = "1.0"
}

variable "vpc_id" {
  type        = string
  description = "VPC id"
  default     = "vpc-0dbd4f4f44612fdd3"
}

variable "public_subnet" {
  type        = string
  description = "Public subnet ids"
  default     = "subnet-0adb645be318502fc"
}

variable "security_group" {
  type        = string
  description = "Security group id"
  default     = "sg-097fbea2f3c838a55"
}

variable "cname_prefix" {
  type = string
  description = "Elastic beanstalk app cname"
  default = "tic-tac-toe-app"
}
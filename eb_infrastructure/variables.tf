variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"
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
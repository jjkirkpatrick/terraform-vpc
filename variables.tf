variable "vpc_name" {
  description = "The name of the VPC to create"
  default     = "terraform-vpc"
}


variable "vpc_cidr" {
  description = "The Cidr range to use for the VPC "
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "list of abailability zones to use"
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "public_subnets" {
  description = "List of public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "List of private subnets"
  type        = list(string)
  default     = []
}

variable "data_subnets" {
  description = "List of private subnets"
  type        = list(string)
  default     = []
}

variable "public_subnet_prefix" {
  description = "prefix to prepend to subnet name"
  default     = "public-"
}

variable "private_subnet_prefix" {
  description = "prefix to prepend to subnet name"
  default     = "private-"
}


variable "data_subnet_prefix" {
  description = "prefix to prepend to subnet name"
  default     = "data-"
}


variable "enable_nat_gateway_private" {
  description = "bool value to toggle natgateway for private subnet"
  default     = "true"
}

variable "enable_nat_gateway_data" {
  description = "bool value to toggle natgateway for data subnet"
  default     = "true"
}


variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}


variable "enable_nat_gateway" {
  description = "bool to create nat gateway"
  default     = true
}

variable "enable_flow_log" {
  description = "bool to enable flow logging"
  default     = true
}

variable "log_retention_period" {
  description = "log_retention_period"
  default     = 60
}

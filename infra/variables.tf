variable "project" {
  type    = string
  default = "devops-e2e"
}

variable "region" {
  type    = string
  default = "eu-west-1" # Ireland
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "cluster_version" {
  type    = string
  default = "1.37"
}

# Free-plan accounts may only launch free-tier-eligible types (2 vCPU / 8 GiB)
variable "node_instance_types" {
  type    = list(string)
  default = ["m7i-flex.large"]
}

variable "node_capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT (SPOT is cheaper on paid accounts)"
  default     = "ON_DEMAND"
}

variable "node_desired" {
  type    = number
  default = 2
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

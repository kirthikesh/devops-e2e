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
  default = "1.31"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired" {
  type    = number
  default = 2
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

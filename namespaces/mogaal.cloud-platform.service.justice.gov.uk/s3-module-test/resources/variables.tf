variable "team_name" {
  default = "cloud-platform"
}

variable "environment-name" {
  default = "module-test"
}

variable "is-production" {
  default = "false"
}

variable "infrastructure-support" {
  default = "cloud-platform"
}

variable "business-unit" {
  default = "cloud-platform"
}

variable "application" {
  default = "module test"
}

variable "namespace" {
  default = "cloud-platform-module-tests"
}

variable "repo_name" {
  default = "cp-module-tests"
}

// The following two variables are provided at runtime by the pipeline.
variable "cluster_name" {
}

variable "cluster_state_bucket" {
}


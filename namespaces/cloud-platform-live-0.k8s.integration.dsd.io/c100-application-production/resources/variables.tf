variable "team_name" {
  default = "family-justice"
}

variable "db_backup_retention_period" {
  default = "2"
}

variable "environment-name" {
  default = "production"
}

variable "is-production" {
  default = "true"
}

variable "infrastructure-support" {
  default = "Family Justice: family-justice-team@digital.justice.gov.uk"
}

variable "application" {
  default = "Apply to court about child arrangements"
}

variable "namespace" {
  default = "c100-application-production"
}

variable "repo_name" {
  default = "c100-application"
}

variable "aws_region" {
  default = "eu-west-1"
}

// The following two variables are provided at runtime by the pipeline.
variable "cluster_name" {}

variable "cluster_state_bucket" {}

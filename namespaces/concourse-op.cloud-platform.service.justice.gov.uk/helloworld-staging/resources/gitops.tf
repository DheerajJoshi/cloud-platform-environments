module "concourse-gitops" {
  source_code_url               = "https://github.com/ministryofjustice/cloud-platform-helloworld-ruby-app"
  github_team                   = "webops"
  namespace                     = "helloworld-staging"
  branch                        = "master"
  concourse_basic_auth_username = "${var.concourse_basic_auth_username}"
  concourse_url                 = "${var.concourse_url}"
  concourse_basic_auth_password = "${var.concourse_basic_auth_password}"
}

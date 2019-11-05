module "concourse-gitops" {
  source                        = "github.com/ministryofjustice/cloud-platform-terraform-gitops"
  github_team                   = "webops"
  namespace                     = "helloworld-dev"
  concourse_basic_auth_username = "${var.concourse_basic_auth_username}"
  concourse_url                 = "${var.concourse_url}"
  concourse_basic_auth_password = "${var.concourse_basic_auth_password}"
}

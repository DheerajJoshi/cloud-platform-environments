resource "aws_route53_zone" "test" {
  name = "test.cloud-platform.service.justice.gov.uk"

  tags = {
    business-unit          = "webops"
    application            = "shared-zone"
    is-production          = "false"
    environment-name       = "dev"
    owner                  = "webops"
    infrastructure-support = "platforms@digital.service.justice.gov.uk"
  }
}



resource "kubernetes_secret" "test" {
  metadata {
    name      = "route53-test"
    namespace = "shared-test-zone"
  }

  data = {
    zone_id = aws_route53_zone.shared.zone_id
  }
}

##

resource "aws_route53_zone" "shared" {
  name = "shared.service.justice.gov.uk"

  tags = {
    business-unit          = "webops"
    application            = "shared-zone"
    is-production          = "false"
    environment-name       = "dev"
    owner                  = "webops"
    infrastructure-support = "platforms@digital.service.justice.gov.uk"
  }
}



resource "kubernetes_secret" "shared" {
  metadata {
    name      = "route53-shared"
    namespace = "shared-test-zone"
  }

  data = {
    zone_id = aws_route53_zone.shared.zone_id
  }
}


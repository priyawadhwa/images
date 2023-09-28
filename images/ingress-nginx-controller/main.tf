terraform {
  required_providers {
    apko = { source = "chainguard-dev/apko" }
  }
}

variable "target_repository" {
  description = "The docker repo into which the image and attestations should be published."
}

module "latest-config" { source = "./config" }

module "latest" {
  source = "../../tflib/publisher"

  name = basename(path.module)

  target_repository = var.target_repository
  config            = module.latest-config.config
}

module "dev" { source = "../../tflib/dev-subvariant" }

module "latest-dev" {
  source = "../../tflib/publisher"

  name = basename(path.module)

  target_repository = var.target_repository
  config            = module.latest-config.config
  extra_packages    = module.dev.extra_packages
}

module "version-tags" {
  source  = "../../tflib/version-tags"
  package = "ingress-nginx-controller"
  config  = module.latest.config
}

# module "test-latest" {
#   source = "./tests"
#   digest = module.latest.image_ref
# }

module "tagger" {
  source = "../../tflib/tagger"

  # depends_on = [
  #   module.test-latest,
  # ]

  tags = merge(
    { for t in toset(concat(["latest"], module.version-tags.tag_list)) : t => module.latest.image_ref },
    { for t in toset(concat(["latest"], module.version-tags.tag_list)) : "${t}-dev" => module.latest-dev.image_ref },
  )
}
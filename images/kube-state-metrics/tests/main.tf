terraform {
  required_providers {
    oci  = { source = "chainguard-dev/oci" }
    helm = { source = "hashicorp/helm" }
  }
}

variable "digest" {
  description = "The image digests to run tests over."
  type        = string
}

data "oci_string" "ref" { input = var.digest }

resource "helm_release" "kube-state-metrics" {
  name = "kube-state-metrics"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-state-metrics"

  namespace        = "kube-state-metrics"
  create_namespace = true

  values = [
    jsonencode({
      image = {
        registry   = data.oci_string.ref.registry
        repository = data.oci_string.ref.repo
        tag        = data.oci_string.ref.pseudo_tag
      }
    }),
  ]
}

data "oci_exec_test" "check-kube-state-metrics" {
  digest      = var.digest
  script      = "./check-ksm.sh"
  working_dir = path.module
  depends_on  = [helm_release.kube-state-metrics]

  env {
    name  = "KSM_NAME"
    value = helm_release.kube-state-metrics.name
  }
}

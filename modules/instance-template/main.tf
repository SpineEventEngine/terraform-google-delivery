#
# Copyright 2026 CodeMatters, Lda.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.
#

locals {
  container_image_project = var.image_project != "" ? var.image_project : var.project

  # The registry host of the container image, for example `europe-docker.pkg.dev`.
  container_registry = split("/", var.container)[0]

  # The registry host when it is a Google one, Artifact Registry or Container Registry,
  # so that the startup script configures the Docker credential helper for it.
  # Empty for images hosted elsewhere.
  google_registry = can(regex("(^|\\.)(pkg\\.dev|gcr\\.io)$", local.container_registry)) ? local.container_registry : ""
}

data "google_compute_default_service_account" "default" {
  # The default service account of GCE instances.
  project = var.project
}

# Generates Instance Template for the Delivery server VMs.
#
# For details about all inputs, see the module docs:
# https://registry.terraform.io/modules/terraform-google-modules/vm/google/latest/submodules/instance_template
module "vm_instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "~> 15.2"

  project_id          = var.project
  region              = var.region
  name_prefix         = "delivery-${var.region}"
  preemptible         = false
  on_host_maintenance = "MIGRATE"
  service_account = {
    email = data.google_compute_default_service_account.default.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  # Hardware config
  machine_type = var.machine_type

  # Boot disk config
  disk_size_gb         = 20
  source_image_project = local.container_image_project
  source_image_family  = var.image_family
  metadata = merge(var.additional_metadata, tomap({
    "google-logging-enabled" = "true"
  }))
  startup_script = templatefile("${path.module}/startup.sh.tftpl", {
    container_name  = "delivery-server"
    container_image = var.container
    google_registry = local.google_registry
    environment     = var.env
  })

  # See https://cloud.google.com/security/shielded-cloud/shielded-vm for details.
  enable_shielded_vm = true
  shielded_instance_config = {
    "enable_integrity_monitoring" : true,
    # Enabling this option causes failures during the application start.
    "enable_secure_boot" : false,
    "enable_vtpm" : true
  }

  # Network interface.
  network    = var.network
  subnetwork = var.subnetwork
  tags       = ["grpc"]
}

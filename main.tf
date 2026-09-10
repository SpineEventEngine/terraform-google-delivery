#
# Copyright 2026 CodeMatters, Lda.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific language governing permissions
# and limitations under the License.
#

# This module declares no provider configuration of its own. It uses the `google` and
# `google-beta` configurations of the calling configuration, which lets callers use it
# with `count`, `for_each`, and `depends_on`, and destroy it cleanly. Every resource
# names its project explicitly, so the callers' configurations need not set one.

# Init VPC network for the Delivery server instances.
module "delivery_network" {
  source = "./modules/network"

  project = var.project
  regions = tolist([
    var.region
  ])
  vpc_name  = "delivery"
  grpc_port = var.port
  # The Admin server port is opened only when the Admin server is enabled.
  allow_ingres_tcp_ports = local.adminEnabled ? [local.adminServerPort] : []
}

locals {
  # The server reads the port of its gRPC endpoint from the `PORT` environment variable:
  # https://github.com/SpineEventEngine/delivery/blob/master/server/README.md
  portEnv = [
    { name = "PORT", value = var.port }
  ]

  # The `admin` input is sensitive because of the password. Its `enabled` flag and `port`
  # decide which firewall rules exist, and Terraform requires such values to be non-sensitive.
  adminEnabled = nonsensitive(var.admin.enabled)
  adminPort    = try(nonsensitive(var.admin.port), null)
  # The port the Admin server listens on: the configured one, or the Micronaut default.
  adminServerPort = coalesce(local.adminPort, 8080)
  # The TCP ports the VM listens on: SSH, the Delivery server, and the Admin server when enabled.
  vmPorts = concat([22, var.port], local.adminEnabled ? [local.adminServerPort] : [])
  adminSettings = [
    { name = "ADMIN_SERVER", value = var.admin.enabled },
    { name = "ADMIN_USERNAME", value = var.admin.login },
    { name = "ADMIN_PASSWORD", value = var.admin.password },
    { name = "MICRONAUT_SERVER_PORT", value = var.admin.port },
  ]

  adminEnv = [for item in local.adminSettings : item if item.value != null]
}

module "instance_template" {
  source = "./modules/instance-template"

  project             = var.project
  region              = var.region
  network             = module.delivery_network.network
  subnetwork          = module.delivery_network.subnets[var.region]
  container           = var.container
  machine_type        = var.vm_machine_type
  env                 = concat(var.env, local.portEnv, local.adminEnv)
  additional_metadata = var.metadata
}

resource "google_compute_instance_from_template" "delivery-server" {
  name    = "delivery-server"
  project = var.project
  zone    = var.zone

  source_instance_template = module.instance_template.template.self_link

  network_interface {
    subnetwork = module.delivery_network.subnets[var.region]
    access_config {
      nat_ip = var.vm_address
    }
  }

  # The container runs with `--network host`, and the launcher runs the Delivery server and
  # the Admin server as two threads of one JVM, so the two share the port space of the VM
  # with each other and with the SSH daemon. A port taken twice fails to bind at boot, and
  # nothing reports it to Terraform: the VM stays up without the Admin interface, or keeps
  # restarting the container when it is the Delivery server that lost the port.
  #
  # The check is a precondition rather than a `validation` of `var.port` or `var.admin`,
  # because validation across variables needs Terraform 1.9, while this module supports 1.3.
  lifecycle {
    precondition {
      condition     = length(distinct(local.vmPorts)) == length(local.vmPorts)
      error_message = "The `port`, the port of the Admin server, and the SSH port (22) must differ from each other."
    }
  }
}

# Deployments created with the `SpineEventEngine/spine-liquor/google` module keep their
# state mapped to the renamed addresses when they switch to this module. The VM and
# the network are still replaced, because their names changed, but Terraform then
# orders the replacement so that the old VM releases the static address before
# the new one claims it.
moved {
  from = module.liquor_network
  to   = module.delivery_network
}

moved {
  from = google_compute_instance_from_template.liquor-server
  to   = google_compute_instance_from_template.delivery-server
}

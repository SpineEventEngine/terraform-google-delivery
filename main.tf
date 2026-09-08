#
# Copyright 2023, TeamDev. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Redistribution and use in source and/or binary forms, with or without
# modification, must retain the above copyright notice and the following
# disclaimer.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
  vpc_name = "delivery"
  # The Admin server port is opened only when the Admin server is enabled.
  allow_ingres_tcp_ports = local.adminEnabled ? [coalesce(local.adminPort, 8080)] : []
}

locals {
  # The `admin` input is sensitive because of the password. Its `enabled` flag and `port`
  # decide which firewall rules exist, and Terraform requires such values to be non-sensitive.
  adminEnabled = nonsensitive(var.admin.enabled)
  adminPort    = try(nonsensitive(var.admin.port), null)
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
  env                 = concat(var.env, local.adminEnv)
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

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

# Configures the Google Compute Engine Default Network Tier for a project.
resource "google_compute_project_default_network_tier" "project-tier" {
  project      = var.project
  network_tier = "PREMIUM"
}

locals {
  # The list of GCP regions. `var.regions` has a `set` type and cannot be used for ordered
  # iteration with `for` expression. Ordered iteration is needed to use an index of every GCP region in this
  # list for calculation of a subnetwork IP range. See the details below in `local.subnets` docs.
  region_list = tolist(var.regions)

  # An object mapping GCP regions
  region_to_subnet_name = { for region in var.regions : region => "${var.vpc_name}-${region}" }

  # The list of subnets in a VPC network. The subnet is represented as an object accepted by
  # "terraform-google-network" module. See the form of a subnet input
  # <a href="https://github.com/terraform-google-modules/terraform-google-network#subnet-inputs">here</a>.
  #
  # To determine a range of IP addresses for every subnet, we use
  # <a href="https://www.terraform.io/docs/language/functions/cidrsubnet.html">cidrsubnet</a> utility. It allows
  # to calculate a subnet address within given IP network address prefix of VPC. The index of a GCP region in
  # a list of `local.region_list` is used as a subnet number.
  subnets = toset([
    for i, region in local.region_list : {
      subnet_name   = local.region_to_subnet_name[region]
      subnet_ip     = cidrsubnet(var.cidrsubnet_ip_range, var.cidrsubnet_new_bits, i)
      subnet_region = region
    }
  ])
}

# Generates a custom VPC network with a set of subnetworks for each GCP region in `var.regions`.
#
# See <a href="https://github.com/terraform-google-modules/terraform-google-network#terraform-network-module">docs</a>
# of this module for details.
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 3.4"

  project_id   = var.project
  network_name = var.vpc_name
  routing_mode = "REGIONAL"

  subnets = local.subnets
}

# Generates a set of firewall rules for the custom VPC.
#
# See <a href="https://github.com/terraform-google-modules/terraform-google-network/tree/v3.4.0/modules/firewall-rules">docs</a>
# of this module for details.
module "firewall_rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version      = "~> 3.4"
  project_id   = var.project
  network_name = module.vpc.network_name

  rules = concat([
    {
      name                    = "${module.vpc.network_name}-allow-ssh-ingress"
      description             = "Allow SSH from anywhere."
      direction               = "INGRESS"
      priority                = null
      ranges                  = ["0.0.0.0/0"]
      source_tags             = null
      source_service_accounts = null
      target_tags             = null
      target_service_accounts = null
      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
      deny       = []
      log_config = null
    },
    {
      name                    = "${module.vpc.network_name}-allow-grpc"
      description             = "Allow gRPC ingress."
      direction               = "INGRESS"
      priority                = null
      ranges                  = null
      source_tags             = null
      source_service_accounts = null
      target_tags             = ["grpc"]
      target_service_accounts = null
      allow = [
        {
          protocol = "tcp"
          ports    = ["8484"]
        }
      ]
      deny       = []
      log_config = null
    }
    ], length(var.allow_ingres_tcp_ports) > 0 ?
    [
      {
        name                    = "${module.vpc.network_name}-allow-custom"
        description             = "Allow custom"
        direction               = "INGRESS"
        priority                = null
        ranges                  = null
        source_tags             = null
        source_service_accounts = null
        target_tags             = null
        target_service_accounts = null
        allow = [
          {
            protocol = "tcp"
            ports    = var.allow_ingres_tcp_ports
          }
        ]
        deny       = []
        log_config = null
      }
  ] : [])
}

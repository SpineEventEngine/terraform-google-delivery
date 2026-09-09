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
  version = "~> 18.2"

  project_id   = var.project
  network_name = var.vpc_name
  routing_mode = "REGIONAL"

  subnets = local.subnets
}

# Generates a set of firewall rules for the custom VPC.
#
# See <a href="https://github.com/terraform-google-modules/terraform-google-network/tree/v18.2.0/modules/firewall-rules">docs</a>
# of this module for details.
module "firewall_rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version      = "~> 18.2"
  project_id   = var.project
  network_name = module.vpc.network_name

  # The rule names are derived from `var.vpc_name` rather than from the module output above:
  # the output is unknown until the network is created, and Terraform needs the rule names,
  # which key the firewall resources, to be known at plan time.
  ingress_rules = concat([
    {
      name          = "${var.vpc_name}-allow-ssh-ingress"
      description   = "Allow SSH from anywhere."
      source_ranges = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
    },
    {
      name        = "${var.vpc_name}-allow-grpc"
      description = "Allow gRPC ingress."
      target_tags = ["grpc"]
      allow = [
        {
          protocol = "tcp"
          ports    = [var.grpc_port]
        }
      ]
    }
    ], length(var.allow_ingres_tcp_ports) > 0 ?
    [
      {
        name        = "${var.vpc_name}-allow-custom"
        description = "Allow custom"
        allow = [
          {
            protocol = "tcp"
            ports    = var.allow_ingres_tcp_ports
          }
        ]
      }
  ] : [])
}

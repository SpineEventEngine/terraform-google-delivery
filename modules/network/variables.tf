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

variable "project" {
  description = "The Google Cloud Project ID."
  type        = string
}

variable "regions" {
  description = "The set of GCP regions in which to configure subnetworks for GCE VMs."
  type        = set(string)
}

variable "vpc_name" {
  description = "The name of VPC to create."
  type        = string
}

variable "cidrsubnet_ip_range" {
  description = "IP network address prefix for subnets within VPC. Must be given in CIDR notation."
  type        = string
  default     = "10.128.0.0/16"
}

variable "cidrsubnet_new_bits" {
  description = "The number of additional bits with which every subnet IP range will extend the prefix."
  type        = number
  default     = 4
}

variable "allow_ingres_tcp_ports" {
  description = "Ports that will be added to the firewall exceptions to allow connection over TCP protocol."
  type        = list(number)
  default     = []
}

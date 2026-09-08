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
  description = "The ID of the Google Cloud project where the Delivery server will be deployed."
  type        = string
}

variable "region" {
  description = "The GCP region to place the Delivery server resources in."
  type        = string
}

variable "zone" {
  description = "The GCP zone where the Delivery server VM must be placed."
  type        = string
}

variable "container" {
  description = "The full name of the Delivery server container image to run on the VM."
  type        = string
}

variable "vm_address" {
  description = "The GCE VM static IP address to be assigned to the VM."
  type        = string
}

variable "vm_machine_type" {
  description = "The GCE VM machine type to be used for the Delivery server."
  type        = string
  default     = "e2-highcpu-2"
}

variable "env" {
  description = <<EOT
    Environment variables to set for the Delivery server.

    The variables the server reads, such as `MAX_INBOUND_MESSAGE_SIZE`, `SHARD_PROCESSING_TIMEOUT`,
    `USE_REDIS`, and `REDIS_HOST`, are described in the server documentation:
    https://github.com/SpineEventEngine/delivery/blob/master/server/README.md
  EOT
  type        = list(object({ name = string, value = string }))
  default     = []
}

variable "metadata" {
  type        = map(any)
  description = "Metadata to attach to the instance."
  default     = {}
}

variable "admin" {
  description = <<EOT
    Configuration for the Admin Server of the Delivery server image.
    The guide on how to provide sensitive data to the template and avoid passing it to the VCS:
    https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables#set-values-with-a-tfvars-file
  EOT
  sensitive   = true
  type = object({
    enabled  = bool
    port     = optional(number)
    login    = optional(string)
    password = optional(string)
  })
  validation {
    condition     = (var.admin.login != null && var.admin.password != null) || (var.admin.login == null && var.admin.password == null)
    error_message = "Impossible to set only `login` or `password`, both should be set."
  }
  default = {
    enabled = false
  }
}

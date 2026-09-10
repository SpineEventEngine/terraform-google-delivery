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

variable "port" {
  description = <<EOT
    The TCP port on which the Delivery server accepts gRPC connections.

    The module opens the port in the firewall and passes it to the server as the `PORT`
    environment variable.
  EOT
  type        = number
  default     = 8484
  validation {
    condition     = var.port == floor(var.port) && var.port >= 1 && var.port <= 65535
    error_message = "The `port` must be a TCP port number: a whole number from 1 to 65535."
  }
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

    The variables set by the module from the `port` and `admin` inputs cannot be listed here.
  EOT
  type        = list(object({ name = string, value = string }))
  default     = []
  validation {
    condition = alltrue([
      for item in var.env :
      !contains(["PORT", "ADMIN_SERVER", "ADMIN_USERNAME", "ADMIN_PASSWORD", "MICRONAUT_SERVER_PORT"], item.name)
    ])
    error_message = "The `PORT`, `ADMIN_SERVER`, `ADMIN_USERNAME`, `ADMIN_PASSWORD`, and `MICRONAUT_SERVER_PORT` variables are set by the module from the `port` and `admin` inputs, and cannot be listed in `env`."
  }
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

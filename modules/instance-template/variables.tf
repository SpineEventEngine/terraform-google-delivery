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

variable "region" {
  description = "The GCP region associated with the instance template."
  type        = string
}

variable "network" {
  description = "The name of VPC network to assign to an instance template."
  type        = string
}

variable "subnetwork" {
  description = "The name of a subnetwork to assign to an instance template."
  type        = string
}

variable "container" {
  description = "The container that is going to be running inside the instance."
  type        = string
}

variable "env" {
  description = "Environment variables to set to a VM that runs container."
  type        = list(object({ name = string, value = string }))
  default     = []
}

variable "additional_metadata" {
  type        = map(any)
  description = "Additional metadata to attach to the instance."
  default     = {}
}

variable "image_project" {
  description = "The project of the GCE image."
  type        = string
  default     = "cos-cloud"
}

variable "image_family" {
  description = "The GCE image family to initialize instance template from. The last not-deprecated image is taken."
  type        = string
  default     = "cos-stable"
}

variable "machine_type" {
  description = "The GCE machine type for this instance template."
  type        = string
  default     = "e2-highcpu-2"
}

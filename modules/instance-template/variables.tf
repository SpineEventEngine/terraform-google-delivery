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

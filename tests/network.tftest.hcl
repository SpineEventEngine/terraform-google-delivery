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

# The tests plan the network module with mocked providers, so they need no Google Cloud project.
# The provider mocks need Terraform 1.7 or newer, while the module itself supports 1.3.

mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project  = "example-project"
  regions  = ["europe-west1"]
  vpc_name = "delivery"
}

run "default_grpc_port" {
  command = plan
  module {
    source = "./modules/network"
  }
  assert {
    condition     = output.subnets["europe-west1"] == "delivery-europe-west1"
    error_message = "The subnetwork must be named after the VPC and the region."
  }
}

run "fractional_grpc_port_rejected" {
  command = plan
  module {
    source = "./modules/network"
  }
  variables {
    grpc_port = 8484.5
  }
  expect_failures = [var.grpc_port]
}

run "grpc_port_out_of_range_rejected" {
  command = plan
  module {
    source = "./modules/network"
  }
  variables {
    grpc_port = 0
  }
  expect_failures = [var.grpc_port]
}

run "custom_ports_accepted" {
  command = plan
  module {
    source = "./modules/network"
  }
  variables {
    allow_ingres_tcp_ports = [8080, 8181]
  }
  assert {
    condition     = output.subnets["europe-west1"] == "delivery-europe-west1"
    error_message = "Valid custom ports must be accepted."
  }
}

run "fractional_custom_port_rejected" {
  command = plan
  module {
    source = "./modules/network"
  }
  variables {
    allow_ingres_tcp_ports = [8080, 8181.5]
  }
  expect_failures = [var.allow_ingres_tcp_ports]
}

run "custom_port_out_of_range_rejected" {
  command = plan
  module {
    source = "./modules/network"
  }
  variables {
    allow_ingres_tcp_ports = [70000]
  }
  expect_failures = [var.allow_ingres_tcp_ports]
}

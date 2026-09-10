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

# The tests plan the module with mocked providers, so they need no Google Cloud project.
# The provider mocks need Terraform 1.7 or newer, while the module itself supports 1.3.

mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project    = "example-project"
  region     = "europe-west1"
  zone       = "europe-west1-b"
  container  = "europe-docker.pkg.dev/spine-event-engine/containers/delivery-server:v0.19.0"
  vm_address = "203.0.113.10"
}

run "default_port" {
  command = plan
  assert {
    condition     = output.port == 8484
    error_message = "The default `port` must be 8484."
  }
  assert {
    condition     = output.ip_address == "203.0.113.10"
    error_message = "The `ip_address` output must carry the address of the VM."
  }
}

run "custom_port" {
  command = plan
  variables {
    port = 9090
  }
  assert {
    condition     = output.port == 9090
    error_message = "The `port` output must follow the input."
  }
}

run "port_in_env_rejected" {
  command = plan
  variables {
    env = [{ name = "PORT", value = "9090" }]
  }
  expect_failures = [var.env]
}

run "admin_variable_in_env_rejected" {
  command = plan
  variables {
    env = [{ name = "MICRONAUT_SERVER_PORT", value = "8181" }]
  }
  expect_failures = [var.env]
}

run "port_out_of_range_rejected" {
  command = plan
  variables {
    port = 70000
  }
  expect_failures = [var.port]
}

run "fractional_port_rejected" {
  command = plan
  variables {
    port = 8484.5
  }
  expect_failures = [var.port]
}

run "ssh_port_rejected" {
  command = plan
  variables {
    port = 22
  }
  expect_failures = [google_compute_instance_from_template.delivery-server]
}

run "admin_port_collision_rejected" {
  command = plan
  variables {
    port  = 8080
    admin = { enabled = true }
  }
  expect_failures = [google_compute_instance_from_template.delivery-server]
}

run "admin_port_on_ssh_rejected" {
  command = plan
  variables {
    admin = { enabled = true, port = 22 }
  }
  expect_failures = [google_compute_instance_from_template.delivery-server]
}

run "admin_port_ignored_while_disabled" {
  command = plan
  variables {
    admin = { enabled = false, port = 22 }
  }
  assert {
    condition     = output.port == 8484
    error_message = "The port of a disabled Admin server must not be checked."
  }
}

run "distinct_admin_port_accepted" {
  command = plan
  variables {
    port  = 8080
    admin = { enabled = true, port = 8181 }
  }
  assert {
    condition     = output.port == 8080
    error_message = "A `port` distinct from the Admin server port must be accepted."
  }
}

run "admin_disabled_accepted" {
  command = plan
  variables {
    port = 8080
  }
  assert {
    condition     = output.port == 8080
    error_message = "The Admin server port is free while the Admin server is disabled."
  }
}

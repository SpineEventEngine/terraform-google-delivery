Spine Delivery Terraform module
----------

This repository holds a reusable Terraform module which creates the Delivery Server infrastructure.

The module is configured with the GCE environment details alongside the Delivery Server container image 
and the VM IP address.

Following the best practices, the Delivery server will reside in its own VPC and region.

When working with App Engine applications, consider picking up a region closed to the App Engine
apps location.

Deployment configuration
----------

The Delivery module has the following inputs available for configuring the deployment and the server itself:

Below you will find a complete configuration example.

Some values that are used several times in the main configuration are declared as Terraform variables in a separate
`variables.tf` file.

`variables.tf`:
```terraform
variable "project" {
  type = string
  description = "Identifier of the GCP project where Terraform should perform the deployment."
  default = ""   # Should be set to your project in which the Delivery server will be deployed.
}

variable "region" {
  type = string
  description = "GCP region to place resources in."
  default = ""   # Should be set to the region in which the Delivery server will be deployed [1].
}

variable "zone" {
  type = string
  description = "GCP zone to place resources in."
  default = ""   # Should be set to the zone in which the Delivery server will be deployed [1].
}
```
**[1]** To get more info about GCP zones and regions please refer to the [docs][regions-zones].

`delivery.tf`:
```terraform
terraform { 
}

provider "google" {   # Enables the “google” provider.
  project = var.project   # Refers to the “project” variable in the `variables.tf` file.
}

provider "google-beta" {   # Enables “google-beta” provider to allow required submodules.
  project = var.project   # Refers to the “project” variable in the `variables.tf` file.
}

resource "google_compute_address" "delivery-ip" {   # IP the main application will use to connect to the Delivery server. 
  name        = "my-delivery-ip"   # Choose the name you'd like.
  description = "The public static IP address of the Delivery server."
  region      = var.region   # Refers to the “region” variable in the `variables.tf` file.

  lifecycle {   # Configures the address not to be destroyed and recreated in the future deployments.
    prevent_destroy = true
  }
}

module "delivery" {
  source     = "SpineEventEngine/delivery/google"
  version    = "0.11.0"   # Version of the `delivery` Terraform module.
  project    = var.project   # Refers to the “project” variable in the `variables.tf` file.
  region     = var.region   # Refers to the “region” variable in the `variables.tf` file.
  zone       = var.zone   # Refers to the “zone” variable in the `variables.tf` file.
  container  = "gcr.io/spine-dev/simple-message-delivery-server:v0.9.0"   # A container to be deployed [2].
  vm_address = google_compute_address.delivery-ip.address   # Refers to the `delivery-ip` resource that 
                                                          # we've configured in this file above.
  vm_machine_type = "e2-highcpu-2"   # Type of the GCE instance [3]. Optional parameter.
  metadata = {}   # Metadata to set to the GCE instance running the Delivery server [4]. Optional parameter.
  env        = [   # Environment variables to set to the container [5]. Optional parameter.
    {
      name  = "MAX_INBOUND_MESSAGE_SIZE"   # [6].
      value = "33554432" // 32 MiB
    },
    {
      name  = "SHARD_PROCESSING_TIMEOUT"   # [7].
      value = "30" // 30 seconds
    }
  ]
  admin = {   # Configuration of the Admin server [8].
    enabled = true
    port = 8181   # Port on which the Admin server web interface will be available. Optional parameter. Default is `8181`.
    login = "admin"   # Login to the Delivery Admin web interface [9]. Optional parameter.
    password = "admin"   # Password to the Delivery Admin web interface [9]. Optional parameter.
  }
}
```
**[2]** There are 2 possible containers to choose from: “simple-server” and “server”. The “simple-server” 
is the recommended choice, as it supports all latest features and shows better performance in general. 
The “server” is experimental solution that may undergo a significant changes lately.

**[3]** This parameter allows to set the machine type that will be running the Delivery server. By default, the value
is set to `e2-highcpu-2`([machine description][e2-machine]) so this parameter may be safely deleted if you don't want 
to modify it. To get more info on available machine types for GCE instances please refer 
to the [docs][gce-machine-resource].

**[4]** To get more info on the metadata for GCE instances please refer to the [google platform docs][instance-metadata].

**[5]** The parameter allows to set environment variables to the container (not to the instance running the container),
those environment variables will be available for the JVM running the Delivery server and to the Delivery server application itself.
Tne parameter is optional and can be safely removed if you don't need to set any environment variables.

**[6]** This environment variable is checked by the Delivery server to modify the `gRPC` inbound message size parameter. 
By default, gRPC allows 4 MB of the max inbound message size. If your payload may exceed this default value
it's recommended to set a custom value using this parameter. **Pay attention that this feature is only available on 
the “simple-server” containers starting from the `0.7.3` version.** Setting this environment variable for the container
that doesn't support this functionality will take no effects.

**[7]** This environment variable is checked by the Delivery server and configures the stale shards auto release procedure.
This procedure allows picking up already occupied shard if one is considered stale. If a gap between a time when
the shard was picked last time and current time is equal to or more than `SHARD_PROCESSING_TIMEOUT`, the session 
is considered stale and can be picked up again. The check is performed when a session is asked for picking up. **Pay 
attention that this feature is only available on the “simple-server” containers starting from the `0.8.3` version.** 
Setting this environment variable for the container that doesn't support this functionality will take no effects.

**[8]** This block configures the Admin server web interface that allows real-time monitoring of the shard processing
on the server. By default, this option is disabled. **This feature is available for both “simple-server”  and “server” 
containers starting from the version `0.8.8`.** Using this setting with containers of lower versions will 
take no effect.

**[9]** By default, the `login` and `password` parameters are determined by the deployed container, so please refer 
to the corresponding container documentation to check what is this values for your container. Even though these 
parameters are optional and have default values we recommend to set your own `login` and `password`. The instruction 
of how to set sensitive values to the Terraform configuration is available in the [docs][tfvars].

[e2-machine]: https://cloud.google.com/compute/docs/general-purpose-machines#e2_machine_types_table
[gce-machine-resource]: https://cloud.google.com/compute/docs/machine-resource
[instance-metadata]: https://cloud.google.com/compute/docs/metadata/overview
[regions-zones]: https://cloud.google.com/compute/docs/regions-zones
[tfvars]: https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables#set-values-with-a-tfvars-file

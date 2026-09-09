Delivery VPC
-----------

This module is responsible for preparing a VPC network and subnetworks for the provided
list of GCP regions.

The created VPC is pre-configured with SSH and gRPC firewall rules. The gRPC rule opens
`var.grpc_port` on the instances tagged `grpc`.

terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }

  backend "http" {
  }
}

provider "aci" {
}

module "aci" {
  source  = "netascode/nac-aci/aci"
  version = "1.1.0"

  yaml_directories = ["data"]

  # Multi-domain ACI scope (Option B):
  #   - manage_node_policies      : register border leaf 403
  #   - manage_interface_policies : bind eth1/1 to 10G-ROUTED policy group
  #
  # Tenants (PROD, SVCS) and their L3Outs are owned entirely by aci/. The
  # L3Outs reference node 403 via soft references; APIC resolves those once
  # this overlay registers the node.
  manage_access_policies    = false
  manage_fabric_policies    = false
  manage_pod_policies       = false
  manage_node_policies      = true
  manage_interface_policies = true
  manage_tenants            = false

  write_default_values_file = "defaults.yaml"
}

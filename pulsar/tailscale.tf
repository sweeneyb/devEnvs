terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
    }
  }
}

provider "tailscale" {
  api_key = var.ts_api_key
  tailnet = var.tailnet
}

data "tailscale_devices" "all_devices" {
}

resource "tailscale_tailnet_key" "vm_keys" {
  count = var.cluster_size
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  description   = "terraform generated auth key for ${var.host_prefix}${format("-%03s", count.index+1)}"
  # tags          = ["${var.host_prefix}${format("-%03s", count.index+1)}"]

}

data "tailscale_device" "provisioned_device" {
  count    = var.cluster_size
  hostname     = "${var.host_prefix}${format("-%03s", count.index+1)}"
  wait_for = "20s"
}

#output "devices" {
#    value = data.tailscale_devices.sample_devices.devices
#}

output "key" {
    value = tailscale_tailnet_key.vm_keys.*.key
    sensitive = true
}

output "tailscale_ips" {
    value = data.tailscale_device.provisioned_device.*.addresses
}
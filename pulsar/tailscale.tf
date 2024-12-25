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

data "tailscale_devices" "sample_devices" {
  
}

output "devices" {
    value = data.tailscale_devices.sample_devices.devices
}
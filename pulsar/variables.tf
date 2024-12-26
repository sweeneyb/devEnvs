variable "proj_id" {
  type    = string
}

variable "boot_disk_size" {
    type = number
    default = "40"
}

variable "username" {
    type = string
    default = "user"
}

variable ts_api_key {
  type = string
  sensitive = true
  ephemeral = true
}

variable tailnet {
  type = string
  sensitive = true
  ephemeral = true
}

variable host_prefix {
  type = string
}

variable cluster_size {
  type = number
  default = 1
}

variable notification_gchat_space_id {
  type = string
}
variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_username" {
  type    = string
  default = "root@pam"
}

variable "proxmox_password" {
  type = string
}

variable "proxmox_insecure" {
  type    = string
  default = false
}

variable "proxmox_ssh_private_key" {
  type = string
}

variable "proxmox_ssh_public_key" {
  type = string
}

variable "proxmox_node_name" {
  type    = string
  default = "pve"
}

variable "agent_memory" {
  type    = number
  default = 8*1024
}

variable "agent_cores" {
  type    = number
  default = 8
}

variable "debian_image" {
  type    = string
  default = "local:iso/debian-12-genericcloud-amd64.qcow2.img"
}

variable "snippets_datastore" {
  type    = string
  default = "local"
}

variable "disksize" {
  type    = number
  default = 20
}
variable "bridge" {
  type    = string
  default = "vmbr0"
}
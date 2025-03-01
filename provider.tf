terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.72.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint

  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure
  ssh {
    agent = false
    private_key = data.local_file.ssh_private_key.content
  }
}

data "local_file" "ssh_private_key" {
  filename = var.proxmox_ssh_private_key
}

data "local_file" "ssh_public_key" {
  filename = var.proxmox_ssh_public_key
}
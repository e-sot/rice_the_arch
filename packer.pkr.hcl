packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source = "github.com/hashicorp/qemu"
    }
    vagrant = {
      version = "~> 1"
      source = "github.com/hashicorp/vagrant"
    }
  }
}

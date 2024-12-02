# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.box = "packer-arch"
    config.vm.define 'test'
  
    # Network configuration
    config.vm.network "public_network"
  
    # VirtualBox specific configuration
    config.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = "2"
      vb.gui = false
      vb.customize ["modifyvm", :id, "--vram", "128"]
      vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
    end
  end
  
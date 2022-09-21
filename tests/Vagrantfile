# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "ubuntu" do |ubuntu|
    ubuntu.vm.box = "ubuntu/focal64"
    ubuntu.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
    end
    ubuntu.vm.provision "shell", inline: <<-SHELL
      cp /vagrant/terraformer.sh /usr/local/bin/terraformer
      bash terraformer
      bash terraformeraws
      bash terraformer azure
      bash terraformer gcp
    SHELL
  end
  config.vm.define "centos" do |centos|
    centos.vm.box = "centos/7"
    centos.vm.provider "virtual box" do |vb|
      vb.memory = "2048"
    end
    centos.vm.provision "shell", inline: <<-SHELL
      cp /vagrant/terraformer.sh /usr/local/bin/terraformer
      bash terraformer
      bash terraformeraws
      bash terraformer azure
      bash terraformer gcp
    SHELL
  end
  config.vm.define "fedora" do |fedora|
    fedora.vm.box = "fedora/32-cloud-base"
    fedora.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
    end
    fedora.vm.provision "shell", inline: <<-SHELL
      cp /vagrant/terraformer.sh /usr/local/bin/terraformer
      bash terraformer
      bash terraformeraws
      bash terraformer azure
      bash terraformer gcp
    SHELL
  end
end

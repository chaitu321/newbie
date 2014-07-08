# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don"t touch unless you know what you"re doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # copied directly from vagrant init chef/centos-6.5
  config.vm.box = "chef/centos-6.5"

  # vm nodes
  config.vm.define :node2 do |node2|
    node2.vm.hostname = "node2"
    node2.vm.network :private_network, ip: "192.168.103.12"
    node2.vm.network :private_network, ip: "192.168.104.12"
    node2.vm.provider :virtualbox do |vb|
      vb.memory = 2048
      vb.customize ["modifyvm", :id, "--groups", "/rac11gR2"]
      vb.customize ["createhd", "--filename", "shared.vdi", "--size", 10*1024, "--variant", "fixed"]
      vb.customize ["modifyhd", "shared.vdi", "--type", "shareable"]
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", 1, "--device", 0, "--type", "hdd", "--medium", "shared.vdi"]
    end
  end
  config.vm.define :node1 do |node1|
    node1.vm.hostname = "node1"
    node1.vm.network :private_network, ip: "192.168.103.11"
    node1.vm.network :private_network, ip: "192.168.104.11"
    node1.vm.provider :virtualbox do |vb|
      vb.memory = 2048
      vb.customize ["modifyvm", :id, "--groups", "/rac11gR2"]
      vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", 1, "--device", 0, "--type", "hdd", "--medium", "shared.vdi"]
    end
  end

  # run setup.sh
  config.vm.provision "shell", path: "setup.sh"

  # proxy
  #config.proxy.http     = "http://proxy:port"
  #config.proxy.https    = "http://proxy:port"
  #config.proxy.no_proxy = "localhost,127.0.0.1"
end

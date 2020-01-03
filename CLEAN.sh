# Step 1: Remove Analysis VMs
cd ~/cuckoo_windows7 && vagrant destroy --force
cd ~/cuckoo_ubuntu && vagrant destroy --force

# Step 2: Remove Vagrant plugins and boxes
cd ~
vagrant box remove datacastle/windows7
vagrant box remove ubuntu/bionic64
vagrant plugin uninstall vagrant-disksize

# Step 3: Remove Vagrant
sudo dpkg --remove vagrant
sudo rm -rf ~/.vagrant.d vagrant_2.2.6_x86_64.deb

# Step 4: Remove Cuckoo
reset
sudo rm -rf ~/cuckoo_env ~/.cuckoo

# Step 5: Remove Cuckoo Dependencies
sudo deluser --remove-home cuckoo
sudo groupdel cuckoo

sudo apt-get -y --purge remove libguac-client-rdp0 libguac-client-vnc0 libguac-client-ssh0 guacd
sudo apt-get -y --purge remove volatility
sudo apt-get -y --purge remove tcpdump apparmor-utils
sudo apt-get -y --purge remove postgresql postgresql-contrib libpq-dev
sudo apt-get -y --purge remove mongodb
sudo apt-get -y --purge remove libjpeg-dev zlib1g-dev swig
sudo apt-get -y --purge remove python-virtualenv python-setuptools
sudo apt-get -y --purge remove python python-pip python-dev libffi-dev libssl-dev

# Step 6: Remove VirtualBox
sudo apt-get -y --purge remove virtualbox-ext-pack virtualbox
echo PURGE | sudo debconf-communicate virtualbox-ext-pack
sudo apt-get -y --purge remove debconf-utils

# Step 7: Clean-up
sudo apt-get -y autoremove

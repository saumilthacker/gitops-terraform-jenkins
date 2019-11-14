#!/bin/bash
sudo sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
yes | cp /home/centos/.ssh/authorized_keys /root/.ssh/authorized_keys
sudo service sshd restart

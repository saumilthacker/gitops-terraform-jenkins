#!/bin/bash
echo '[nginx]' > /etc/yum.repos.d/nginx.repo
echo 'name=nginx repo' >> /etc/yum.repos.d/nginx.repo
echo 'baseurl=http://nginx.org/packages/OS/OSRELEASE/$basearch/' >> /etc/yum.repos.d/nginx.repo
echo 'gpgcheck=0' >> /etc/yum.repos.d/nginx.repo
echo 'enabled=1' >> /etc/yum.repos.d/nginx.repo 
OS_VERSION=$(cat /etc/system-release)
case "$OS_VERSION" in        
    CentOS*release\ 7* )                        
        sed -i -e 's/OS/centos/' -e 's/OSRELEASE/7/' /etc/yum.repos.d/nginx.repo;;        
    Red\ Hat*release\ 7* )                        
        sed -i -e 's/OS/rhel/' -e 's/OSRELEASE/7/' /etc/yum.repos.d/nginx.repo;;
esac
# # Define some functions
# f_usage() {
#   echo "   -h|--help                Displays this help informationi"
#     echo "   -v|--version             Version of the aiops to be installed"
#     echo "   -u|--jumpcloud-user      Jumpcloud user"
#     echo "   -p|--jumpcloud-password  Jumpcloud password"
#     echo "   -i|--host-name            Hostname that will be set"
#     echo
# }
# # read the options
# args=`getopt -o v:u:p:i:h --long version:,jumpcloud-user:,jumpcloud-password:,host-name:,help -- "$@"`
# # Exit if getopt returns non-zero
# if [[ $? != 0 ]] ;
# then
#   echo "Invalid"; exit 1;
# fi
# eval set -- "$args"
#Initialise the variable for further use
VERSION="7.3"
# JUMP_CLOUD_USER=""
# JUMP_CLOUD_PASSWORD=""
HOSTNAME=`hostname`
# #
# # Process cmd-line switches
# #
# while true ; do
#     case "$1" in
#         -v|--version)
#           if [[ ! $2 ]];
#           then
#               echo "ERROR: Version must be specified"
#               f_usage
#               exit 1
#           fi
#           VERSION=$2
#           echo "Version: $VERSION"
#           shift 2 
#           ;;
#         -u|--jumpcloud-user)
#           if [[ ! $2 ]];
#           then
#               echo "ERROR: Jumpcloud user must be specified"
#               f_usage
#               exit 1
#           fi
#           JUMPCLOUD_USER=$2
#           echo "Jumpcloud user: $JUMPCLOUD_USER"
#           shift 2 
#           ;;
#         -p|--jumpcloud-password)
#           if [[ ! $2 ]];
#           then
#               echo "ERROR: Jumpcloud password must be specified"
#               f_usage
#               exit 1
#           fi
#           JUMPCLOUD_PASSWORD=$2
#           echo "Jumpcloud password: $JUMPCLOUD_PASSWORD"
#             shift 2
#             ;;
#         -i|--host-name)
#           if [[ ! $2 ]];
#           then
#               echo "ERROR: Hostname must be specified"
#               f_usage
#               exit 1
#           fi
#           HOSTNAME=$2
#           echo "Hostname: $HOSTNAME"
#             shift 2
#             ;;
#         -h|--help)
#           f_usage
#           exit 2
#             ;;
#         --) 
#           shift
#           break 
#           ;;
#         *) 
#           echo "Invalid Arguments!!!" ; 
#           exit 1 
#           ;;
#     esac
# done
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tStopping Firewall Service"
echo "+-------------------------------------------------------------------+"
echo ""
service firewalld stop 
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tCreating Yum Repository for Moogsoft"
echo "+-------------------------------------------------------------------+"
echo ""
cat > /etc/yum.repos.d/aiops.repo << _EOF_
[moogsoft-released-esr]
name=moogsoft-aiops-latest
baseurl=https://moogcrest:gDaJRrua_8_k@speedy.moogsoft.com/repo/aiops/esr
enabled=1
gpgcheck=0
sslverify=0
[moogsoft-released-edge]
name=moogsoft-aiops-latest
baseurl=https://moogcrest:gDaJRrua_8_k@speedy.moogsoft.com/repo/aiops/edge
enabled=1
gpgcheck=0
sslverify=0 
_EOF_
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tCreating Yum Repository for Elasticsearch"
echo "+-------------------------------------------------------------------+"
echo ""
cat > /etc/yum.repos.d/elasticsearch.repo << _EOF_
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
_EOF_
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tInstalling RabbitMQ Erlang e17 Package"
echo "+-------------------------------------------------------------------+"
echo ""
yum -y install https://github.com/rabbitmq/erlang-rpm/releases/download/v20.1.7/erlang-20.1.7-1.el7.centos.x86_64.rpm
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tInstalling RabbitMQ yum Repository"
echo "+-------------------------------------------------------------------+"
echo ""
curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | sudo bash
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tInstalling Elasticsearch Public Key"
echo "+-------------------------------------------------------------------+"
echo ""
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tExecuting the create_nginx_repo.sh"
echo "+-------------------------------------------------------------------+"
echo ""
bash create_nginx_repo.sh
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tRefreshing yum repositories and verify NSS and OpenSSL packages"
echo "+-------------------------------------------------------------------+"
echo ""
yum clean all
yum -y update nss openssl
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tInstalling Java 11"
echo "+-------------------------------------------------------------------+"
echo ""
yum -y install java-11-openjdk-headless-11.0.2.7 java-11-openjdk-11.0.2.7 java-11-openjdk-devel-11.0.2.7
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tInstalling extra packages for enterprise Linux"
echo "+-------------------------------------------------------------------+"
echo ""
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tInstalling percona"
echo "+-------------------------------------------------------------------+"
echo ""
cat > aiops_repo.sh << _EOF_
#!/bin/bash
clear
curl -L -O https://moogcrest:gDaJRrua_8_k@speedy.moogsoft.com/repo/aiops/install_percona_nodes.sh 2>/dev/null
echo
_EOF_
bash aiops_repo.sh;
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tExecuting install_percona_nodes.sh"
echo "+-------------------------------------------------------------------+"
echo ""
bash install_percona_nodes.sh -p -i $HOSTNAME
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tSetting SELinux permission to disable"
echo "+-------------------------------------------------------------------+"
echo ""
setenforce 0
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tInstalling MoogsoftAIops"
echo "+-------------------------------------------------------------------+"
echo ""
yum -y install moogsoft-*$VERSION* --exclude moogsoft-ccsm --exclude moogsoft-debug
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tSetting up the environment varaible"
echo "+-------------------------------------------------------------------+"
echo ""
echo "export MOOGSOFT_HOME=/usr/share/moogsoft" >> ~/.bashrc
echo "export APPSERVER_HOME=/usr/share/apache-tomcat" >> ~/.bashrc
echo "export JAVA_HOME=/usr/java/latest" >> ~/.bashrc
echo "export PATH=$PATH:$MOOGSOFT_HOME/bin:$MOOGSOFT_HOME/bin/utils" >> ~/.bashrc
source ~/.bashrc
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tInitialsing Moogsoft"
echo "+-------------------------------------------------------------------+"
echo ""
# sed -i 's|MY_HOSTNAME=$(hostname)|MY_HOSTNAME='$HOSTNAME'|' $MOOGSOFT_HOME/bin/utils/moog_init_functions.sh
$MOOGSOFT_HOME/bin/utils/moog_init.sh -qI MoogsoftAIOps -u root --accept-eula <<-EOF
EOF
sleep 30 
./$MOOGSOFT_HOME/bin/utils/moog_init.sh -qI MoogsoftAIOps -u root --accept-eula <<-EOF
EOF
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tInserting Dev License"
echo "+-------------------------------------------------------------------+"
echo ""
mysql -e "use moogdb; DELETE FROM licence_info; INSERT INTO licence_info VALUES ('# Moogsoft AIOPs Incident.MOOG Enterprise License (id: 1454614032999)35db26cbe12080ecc10d63006e2285234a1e6a59fea744ece931ec6c56c7ce5984d0eb58b4e1a35e13683bd800a8720011972a0166ada4a2b058b351c2161210c668dfb1ceaf09fdc8739df887fdbe738223ea9a33ff925601e73b29a598e64ceecd914b8210214e315986505c91bc15515012fa8855c08f27148286d4a1504524b670a089be9b189fede6b2fb665f99ea7a71b268c5c4ee20f1ac13a9cd0b50cae57c898d9e0ecbebf8befbcd9657cd5b103f67ea06fddd8f9c21234fa2688e11b26c090bfb58ab0e25815da32142e8b68d3b9422d79c07bb3b592623b039443b1a7d6ed922787ffd8b1699f37b58539f9fa054d0e6b2a1b27080cf8ebd6fb008626444e3a872f7d0e357399694daa001c8ccc51575aebed0c4fac67bebfe3eea29ae211ccf465c45892cf832f6f15edb2581f7cb0fb703f63a7dea7e926ad0fa1940d4a619c40a2d93e9c60731c7114b6803c467f0c12f57f7377c80f9c6cd53a40818d67675b543127a9fd00dc5721fe7198ba77a82a8bb685fd1d8d3527d12509215b6fd8e2580ff72f3ca6e6fa026fe58956e6e605cb37f23142f9dac6da7df855bfddba9e6023733170844ce7e41207b54000c9f50796bf650e0a27922dae5cf26cea2639ed38b9ae4e5fb675afbb249c9b99d7882bff19a2f19996bc2a32be310770982590bea3e3e43d985fba8d409cc882f13d4');"
echo ""
echo "+-------------------------------------------------------------------+"
echo -e "\tExdecuting Validation Script"
echo "+-------------------------------------------------------------------+"
echo ""
#$MOOGSOFT_HOME/bin/utils/moog_install_validator.sh
#$MOOGSOFT_HOME/bin/utils/moog_db_validator.sh 
#$MOOGSOFT_HOME/bin/utils/tomcat_install_validator.sh 

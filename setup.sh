#!/bin/sh

# convert into Oracle Linux 6
curl -O https://linux.oracle.com/switch/centos2ol.sh
sh centos2ol.sh
yum upgrade -y

# fix locale warning
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

# install Oracle Database prereq packages
yum install -y oracle-rdbms-server-11gR2-preinstall

# install UEK kernel
yum install -y kernel-uek-devel
grubby --set-default=/boot/vmlinuz-2.6.39*

# fix /etc/hosts
HOST=`hostname`
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain $HOST
192.168.103.11  node1
192.168.103.12  node2
192.168.103.21  node1-vip
192.168.103.22  node2-vip
192.168.103.100 scan
192.168.104.11  node1-priv
192.168.104.12  node2-priv
EOF

# add user/groups
groupadd -g 54318 asmdba
groupadd -g 54319 asmoper
groupadd -g 54320 asmadmin
# 54321 oinstall
# 54322 dba
groupadd -g 54323 oper

useradd -u 54320 -g oinstall -G asmdba,asmoper,asmadmin,dba grid
usermod -a -g oinstall -G dba,oper,asmdba oracle

echo oracle | passwd --stdin grid
echo oracle | passwd --stdin oracle

# setup users
cat >> /home/grid/.bash_profile << 'EOF'
export ORACLE_BASE=/u01/grid
export ORACLE_HOME=/u01/11.2.0.4/grid
export ORACLE_SID=`hostname | sed "s/node/+ASM/g"`
export PATH=$PATH:$ORACLE_HOME/bin
EOF

cat >> /home/oracle/.bash_profile << 'EOF'
export ORACLE_BASE=/u01/oracle
export ORACLE_HOME=/u01/oracle/product/11.2.0.4/dbhome_1
export ORACLE_SID=`hostname | sed "s/node/orcl/g"`
export PATH=$PATH:$ORACLE_HOME/bin
EOF

cat >> /etc/security/limits.conf << EOF
grid     soft   nofile   1024
grid     hard   nofile   65536
grid     soft   nproc    16384
grid     hard   nproc    16384
grid     soft   stack    10240
grid     hard   stack    32768
EOF

# add directories, setup permissions
mkdir -p /u01/grid /u01/oraInventory /u01/11.2.0.4/grid /u01/oracle/product/11.2.0.4/dbhome_1
chown -R oracle:oinstall /u01
chown -R grid:oinstall /u01/grid
chown -R grid:oinstall /u01/oraInventory
chown -R grid:oinstall /u01/11.2.0.4
chmod -R ug+rw /u01

# set shared disk permission
chown grid:asmadmin /dev/sdb
cat > /etc/udev/rules.d/99-sdb.rules << EOF
KERNEL=="sdb", OWNER="grid", GROUP="asmadmin", MODE="0666"
EOF

# setup ssh equivalence (node1 only)
if [ `hostname` == "node1" ]
then
  yum install -y expect
  expect /vagrant/ssh.expect grid oracle
  expect /vagrant/ssh.expect oracle oracle
fi

# install cvuqdisk to avoid NullPointerException in OUI (BUG#17238586)
rpm -ivh /vagrant/grid/rpm/cvuqdisk*.rpm

# confirm
cat /etc/oracle-release

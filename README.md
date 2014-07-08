vagrant-oracle11g-rac
=====================

[Japanese version here](README_ja.md)

11gR2 version of [this](https://github.com/yasushiyy/vagrant-oracle12c-rac)

Directy installs 11.2.0.4 (PSR) so you need a My Oracle Support account.  The steps should also work with 11.2.0.1(media).

as of 7/8/2014

## Setup

* node1, node2
  * Oracle Linux 6.5 (converted from CentOS6.5)
  * oracle-rdbms-server-11gR2-preinstall
  * Unbreakable Enterprise Kernel
  * Memory: 2GB each
  * Shared Disk: 10GB (uses ASM)

```
192.168.103.11  node1
192.168.103.12  node2
192.168.103.21  node1-vip
192.168.103.22  node2-vip
192.168.103.100 scan
192.168.104.11  node1-priv
192.168.104.12  node2-priv
```

## Prepare

If you are behing a proxy, install vagrant-proxyconf.

```
(MacOSX)
$ export http_proxy=proxy:port
$ export https_proxy=proty:port

(Windows)
$ set http_proxy=proxy:port
$ set https_proxy=proxy:port

$ vagrant plugin install vagrant-proxyconf
```

Install VirtualBox plugin.

```
$ vagrant plugin install vagrant-vbguest
```

Clone this repository to the local directory.

```
$ git clone https://github.com/yasushiyy/vagrant-oracle11g-rac
$ cd vagrant-oracle11g-rac
```

If you are behind a proxy, add follwing to Vagrantfile:

```
config.proxy.http     = "http://proxy:port"
config.proxy.https    = "http://proxy:port"
config.proxy.no_proxy = "localhost,127.0.0.1"
```

Download the Grid Infrastructure / Database binary form below.  Unzip to the same directory as above.  It should have the subdirectory name "grid" and "database".

https://updates.oracle.com/download/13390677.html

Platform or Language -> Linux x86-64

* into "database" subdirectory
  * p13390677_112040_LINUX_1of7.zip
  * p13390677_112040_LINUX_2of7.zip

* into "grid" subdirectory
  * p13390677_112040_LINUX_3of7.zip

Boot.  This might take a long time.

```
$ vagrant up
```

Restart to use the UEK kernel.

```
$ vagrant reload
```

## Install Clusterware (as grid)

Install Clusterware.

```
[vagrant@node1 ~]$ sudo su - grid

[grid@node1 ~]$ /vagrant/grid/runInstaller -silent -responseFile /vagrant/grid_install.rsp

the follwing WARNING can be ignored:
[WARNING] [INS-30011] The SYS password entered does not conform to the Oracle recommended standards.
[WARNING] [INS-30011] The ASMSNMP password entered does not conform to the Oracle recommended standards.
[WARNING] [INS-13014] Target environment do not meet some optional requirements.
  -> INFO: Swap Size: This is a prerequisite condition to test whether sufficient total swap space is available on the system.
  -> INFO: Device Checks for ASM: This is a pre-check to verify if the specified devices meet the requirements for configuration through the Oracle Universal Storage Manager Configuration Assistant.

   :
Successfully Setup Software.
```

Run root scripts.  When asked for a root password, enter "vagrant".

```
[grid@node1 ~]$ ssh root@node1 /u01/oraInventory/orainstRoot.sh
[grid@node1 ~]$ ssh root@node2 /u01/oraInventory/orainstRoot.sh
[grid@node1 ~]$ ssh root@node1 /u01/11.2.0.4/grid/root.sh
[grid@node1 ~]$ ssh root@node2 /u01/11.2.0.4/grid/root.sh
[grid@node1 ~]$ /u01/11.2.0.4/grid/cfgtoollogs/configToolAllCommands RESPONSE_FILE=/vagrant/grid_install.rsp
```

Check status.

```
[grid@node1 ~]$ crsctl stat res -t
--------------------------------------------------------------------------------
NAME           TARGET  STATE        SERVER                   STATE_DETAILS
--------------------------------------------------------------------------------
Local Resources
--------------------------------------------------------------------------------
ora.DATA.dg
               ONLINE  ONLINE       node1
               ONLINE  ONLINE       node2
ora.LISTENER.lsnr
               ONLINE  ONLINE       node1
               ONLINE  ONLINE       node2
ora.asm
               ONLINE  ONLINE       node1                    Started
               ONLINE  ONLINE       node2                    Started
ora.gsd
               OFFLINE OFFLINE      node1
               OFFLINE OFFLINE      node2
ora.net1.network
               ONLINE  ONLINE       node1
               ONLINE  ONLINE       node2
ora.ons
               ONLINE  ONLINE       node1
               ONLINE  ONLINE       node2
ora.registry.acfs
               ONLINE  ONLINE       node1
               ONLINE  ONLINE       node2
--------------------------------------------------------------------------------
Cluster Resources
--------------------------------------------------------------------------------
ora.LISTENER_SCAN1.lsnr
      1        ONLINE  ONLINE       node1
ora.cvu
      1        ONLINE  ONLINE       node1
ora.node1.vip
      1        ONLINE  ONLINE       node1
ora.node2.vip
      1        ONLINE  ONLINE       node2
ora.oc4j
      1        ONLINE  ONLINE       node1
ora.scan1.vip
      1        ONLINE  ONLINE       node1

[grid@node1 ~]$ asmcmd lsdg
State    Type    Rebal  Sector  Block       AU  Total_MB  Free_MB  Req_mir_free_MB  Usable_file_MB  Offline_disks  Voting_files  Name
MOUNTED  EXTERN  N         512   4096  1048576     10240     9844                0            9844              0             Y  DATA/
```

## Install DB (as oracle)

Install Database binary.

```
[grid@node1 ~]$ exit

[vagrant@node1 ~]$ sudo su - oracle

[oracle@node1 ~]$ /vagrant/database/runInstaller -silent -ignorePrereq -responseFile /vagrant/db_install.rsp

the follwing WARNING can be ignored:
[WARNING] - My Oracle Support Username/Email Address Not Specified
[SEVERE] - The product will be registered anonymously using the specified email address.

  :
Successfully Setup Software.
```

Run root scripts.  When asked for a root password, enter "vagrant".

```
[oracle@node1 ~]$ ssh root@node1 /u01/oracle/product/11.2.0.4/dbhome_1/root.sh
[oracle@node1 ~]$ ssh root@node2 /u01/oracle/product/11.2.0.4/dbhome_1/root.sh
```

Check status.

```
[oracle@node1 ~]$ which sqlplus
/u01/oracle/product/11.2.0.4/dbhome_1/bin/sqlplus
```

## Create DB (as oracle)

Create Database.

```
[oracle@node1 ~]$ dbca -silent -createDatabase -responseFile /vagrant/dbca.rsp
  :
100% complete
Look at the log file "/u01/oracle/cfgtoollogs/dbca/orcl/orcl.log" for further details.
```

Check status.

```
[oracle@node1 ~]$ /u01/11.2.0.4/grid/bin/crsctl stat res ora.orcl.db -t
--------------------------------------------------------------------------------
NAME           TARGET  STATE        SERVER                   STATE_DETAILS
--------------------------------------------------------------------------------
Cluster Resources
--------------------------------------------------------------------------------
ora.orcl.db
      1        ONLINE  ONLINE       node1                    Open
      2        ONLINE  ONLINE       node2                    Open
```

Check connection.

```
[oracle@node1 ~]$ sqlplus system/oracle@node2-vip:1521/orcl

SQL*Plus: Release 11.2.0.4.0 Production on Tue Jul 8 07:20:37 2014

Copyright (c) 1982, 2013, Oracle.  All rights reserved.


Connected to:
Oracle Database 11g Enterprise Edition Release 11.2.0.4.0 - 64bit Production
With the Partitioning, Real Application Clusters and Automatic Storage Management options

SQL> select * from dual;

D
-
X

SQL> exit
Disconnected from Oracle Database 11g Enterprise Edition Release 11.2.0.4.0 - 64bit Production
With the Partitioning, Real Application Clusters and Automatic Storage Management options
```

## FYI

VKTM background process consumes extra CPU under Virtualbox, because it executes `gettimeofday()` frequently.
You can execute below to disable this.  But NEVER do this in the production system.

```
(DB and ASM)
SQL> alter system set "_high_priority_processes"='' scope=spfile;
```

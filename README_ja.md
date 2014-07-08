vagrant-oracle11g-rac
=====================

[English version here](README.md)

[これ](https://github.com/yasushiyy/vagrant-oracle12c-rac) の11gR2版。

11.2.0.4(PSR)を直接インストールするので、My Oracle Supportのアカウントが必要。11.2.0.1(DVD)でも手順は大差無いはず。

as of 7/8/2014

## 概要

* node1, node2
  * Oracle Linux 6.5 (CentOS6.5から変換している)
  * oracle-rdbms-server-11gR2-preinstall
  * Unbreakable Enterprise Kernel
  * Memory: 2GBずつ
  * Shared Disk: 10GB (ASM用)

```
192.168.103.11  node1
192.168.103.12  node2
192.168.103.21  node1-vip
192.168.103.22  node2-vip
192.168.103.100 scan
192.168.104.11  node1-priv
192.168.104.12  node2-priv
```

## ダウンロード

Grid Infrastructure / Database のバイナリを以下からダウンロード。"grid"と"database"というサブディレクトリになるはず。

https://updates.oracle.com/download/13390677.html

Platform or Language → Linux x86-64

* "database" サブディレクトリ
  * p13390677_112040_LINUX_1of7.zip
  * p13390677_112040_LINUX_2of7.zip

* "grid" サブディレクトリ
  * p13390677_112040_LINUX_3of7.zip

## OSインストール

プロキシを利用する必要がある場合、まず vagrant-proxyconf をインストールする。

```
(MacOSX)
$ export http_proxy=proxy:port
$ export https_proxy=proty:port

(Windows)
$ set http_proxy=proxy:port
$ set https_proxy=proxy:port

$ vagrant plugin install vagrant-proxyconf
```

VirtualBox plugin をインストールする。

```
$ vagrant plugin install vagrant-vbguest
```

本レポジトリをローカルディスク上にcloneする。先ほどの"grid"と"oracle"サブディレクトリを本ディレクトリ内にMOVEする。

```
$ git clone https://github.com/yasushiyy/vagrant-oracle11g-rac
$ cd vagrant-oracle11g-rac
```

プロキシを利用する必要がある場合、追加で Vagrantfile の編集が必要。

```
config.proxy.http     = "http://proxy:port"
config.proxy.https    = "http://proxy:port"
config.proxy.no_proxy = "localhost,127.0.0.1"
```

起動する。Vagrantfile, setup.shの内容が実行されるので、そこそこ時間がかかる。

```
$ vagrant up
```

リブートする。UEK kernelに置き換わる。（現時点ではUEKR2を利用しており、UEKR3ではない）

```
$ vagrant reload
```

## GIインストール（gridユーザ）

クラスタウェアをインストールする。

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

root系のシェルを実行する。パスワードを聞かれた場合は、"vagrant"と入力する。

```
[grid@node1 ~]$ ssh root@node1 /u01/oraInventory/orainstRoot.sh
[grid@node1 ~]$ ssh root@node2 /u01/oraInventory/orainstRoot.sh
[grid@node1 ~]$ ssh root@node1 /u01/11.2.0.4/grid/root.sh
[grid@node1 ~]$ ssh root@node2 /u01/11.2.0.4/grid/root.sh
[grid@node1 ~]$ /u01/11.2.0.4/grid/cfgtoollogs/configToolAllCommands RESPONSE_FILE=/vagrant/grid_install.rsp
```

セットアップ状況を確認する。

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

## DBインストール（oracleユーザ）

データベースのバイナリをインストールする。

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

root系のシェルを実行する。パスワードを聞かれた場合は、"vagrant"と入力する。

```
[oracle@node1 ~]$ ssh root@node1 /u01/oracle/product/11.2.0.4/dbhome_1/root.sh
[oracle@node1 ~]$ ssh root@node2 /u01/oracle/product/11.2.0.4/dbhome_1/root.sh
```

セットアップ状況を確認する。

```
[oracle@node1 ~]$ which sqlplus
/u01/oracle/product/11.2.0.4/dbhome_1/bin/sqlplus
```

## DB作成（oracleユーザ）

DBを作成する。

```
[oracle@node1 ~]$ dbca -silent -createDatabase -responseFile /vagrant/dbca.rsp
  :
100% complete
Look at the log file "/u01/oracle/cfgtoollogs/dbca/orcl/orcl.log" for further details.
```

確認する。

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

接続テスト。

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

Virtualbox環境だとVKTMバックグラウンド・プロセスが`gettimeofday()`を連発してしまい、平常時でもCPU負荷が高騰する。
これを抑制するには以下を実行してリブート。
本番環境では絶対にやってはいけない。

```
(DB and ASM)
SQL> alter system set "_high_priority_processes"='' scope=spfile;
```

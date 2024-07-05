select @@maxpagesize
go
-- 16384


sp_dropdevice SPECTRUM__log_01, dropfile
go
sp_dropdevice SPECTRUM_data_01, dropfile
go
sp_dropdevice my_db_dat, dropfile
go
sp_dropdevice my_db_log, dropfile
go
sp_dropdevice pubs2_dat, dropfile
go
sp_dropdevice pubs2_log, dropfile
go
sp_dropdevice pubtune_data, dropfile
go
sp_dropdevice pubtune_log, dropfile
go


use master
go
disk init name = 'demodb_01_dat', physname = '/opt/sap/data/ase/SPEC_DS_demodb_01_dev.dat', size = '1024M'
go
disk init name = 'demodb_02_dat', physname = '/opt/sap/data/ase/SPEC_DS_demodb_02_dev.dat', size = '1024M'
go
disk init name = 'demodb_03_dat', physname = '/opt/sap/data/ase/SPEC_DS_demodb_03_dev.dat', size = '1024M'
go
disk init name = 'demodb_04_dat', physname = '/opt/sap/data/ase/SPEC_DS_demodb_04_dev.dat', size = '1024M'
go
disk init name = 'demodb_05_dat', physname = '/opt/sap/data/ase/SPEC_DS_demodb_05_dev.dat', size = '1024M'
go
disk init name = 'demodb_06_dat', physname = '/opt/sap/data/ase/SPEC_DS_demodb_06_dev.dat', size = '1024M'
go
disk init name = 'demodb_07_dat', physname = '/opt/sap/data/ase/SPEC_DS_demodb_07_dev.dat', size = '1024M'
go
disk init name = 'demodb_08_dat', physname = '/opt/sap/data/ase/SPEC_DS_demodb_08_dev.dat', size = '1024M'
go
disk init name = 'demodb_01_log', physname = '/opt/sap/data/ase/SPEC_DS_demodb_01_dev.log', size = '512M'
go
disk init name = 'demodb_02_log', physname = '/opt/sap/data/ase/SPEC_DS_demodb_02_dev.log', size = '512M'
go

cd /
mkdir opt_sap_data_ase
chown sapase.sapase opt_sap_data_ase/ -R

disk init name = 'demodb_09_dat', physname = '/opt_sap_data_ase/SPEC_DS_demodb_09_dev.dat', size = '1024M'
go
disk init name = 'demodb_10_dat', physname = '/opt_sap_data_ase/SPEC_DS_demodb_10_dev.dat', size = '1024M'
go
disk init name = 'demodb_11_dat', physname = '/opt_sap_data_ase/SPEC_DS_demodb_11_dev.dat', size = '1024M'
go
disk init name = 'demodb_12_dat', physname = '/opt_sap_data_ase/SPEC_DS_demodb_12_dev.dat', size = '1024M'
go



-- drop
use master
go
drop database demodb
go

-- create
create database demodb
on demodb_01_dat = '1024M', demodb_02_dat = '1024M', demodb_03_dat = '1024M', demodb_04_dat = '1024M',
demodb_05_dat = '1024M', demodb_06_dat = '1024M', demodb_07_dat = '1024M', demodb_08_dat = '1024M',
demodb_09_dat = '1024M', demodb_10_dat = '1024M', demodb_11_dat = '1024M', demodb_12_dat = '1024M'
log on demodb_01_log = '512M', demodb_02_log = '512M'
go
sp_dboption demodb, 'select into/bulkcopy/pllsort', true
go
sp_dboption demodb, 'trunc log on chkpt', true
go
sp_dboption demodb, 'abort tran on log full', true
go
sp_dboption demodb, 'ddl in tran', true
go
sp_dboption demodb, 'allow nulls by default', true
go
sp_dboption demodb, 'no free space acctg', true -- do testu
go
use demodb
go
sp_logiosize "64"   -- ustawiam na zgodne z domyslna wielkoscia 'user log cache size' czyli 64
go
use tempdb
go
sp_logiosize "64"   
go



-- set server configuration
sp_configure 'enable functionality group', 1
go

-- configure max memory on SAP ASE for 13G
sp_configure 'max memory', 6815744
go
sp_cacheconfig 'default data cache', '10G'
go
sp_cacheconfig "default data cache", "cache_partition=8"
go
sp_poolconfig 'default data cache', "1G", "64K"
go

-- configure 4 threads for SAP ASE
sp_configure 'max online engines', 16
go
alter thread pool syb_default_pool with thread count = 8
go
sp_configure "lock scheme", 0, datarows
go
sp_configure "number of locks", 1000000
go
sp_configure "user connections",512
go
sp_configure "statement cache size", 102400
go
sp_configure "literal autoparam", 1
go
sp_configure "number of open objects",2000 -- max resue 2484
go
sp_configure "procedure cache size",164000
go
sp_configure "number of network tasks", 8
go
sp_configure 'user log cache size' --> jest domyslnie na 8k (mimo ze pagesize 2k)
go
sp_configure 'session tempdb log cache size', 65536
go
sp_configure 'heap memory per user', 16384
go
sp_configure 'disk i/o structures',2048
go
sp_configure 'number of disk tasks',4
go
sp_configure 'max network packet size',16384
go
sp_configure 'default network packet size',16384
go
sp_configure 'additional network memory',50331648
go

-- 1.1
sp_configure 'default network packet size',16384 -- z 4k
go
sp_configure 'cpu accounting flush interval',5000000
go
sp_configure 'i/o accounting flush interval',5000000
go
sp_configure 'sysstatistics flush interval',5
go
sp_configure 'number of large i/o buffers',32
go
sp_configure 'enable housekeeper GC',5
go
sp_configure 'user log cache spinlock ratio',5
go
sp_configure 'housekeeper free write percent',10
go
-- 1.2

sp_configure 'sysstatistics flush interval',0
go
sp_configure 'enable housekeeper GC',1
go
sp_configure 'housekeeper free write percent',1
go

-- 1.3
sp_configure 'default network packet size',4096
go

-- 1.4

sp_configure 'sysstatistics flush interval',5
go
sp_configure 'enable housekeeper GC',5
go
sp_configure 'housekeeper free write percent',10
go



 Parameter Name                                           Default                Memory Used                Config Value                 Run Value                Unit         Type
 -------------------------------------------------------- ---------------------- -------------------------- ---------------------------- ------------------------ ------------ --------------
 additional network memory                                          0                      0                           0                            0             bytes        dynamic
 default network packet size                                     2048                  #3726                        2048                         2048             bytes        static
 max network packet size                                         2048                      0                        2048                         2048             bytes        static
 max network peek depth                                             0                      0                           0                            0             bytes        dynamic
 max number network listeners                                       5                   4390                           5                            5             number       dynamic
 network polling mode                                        threaded                      0                    threaded                     threaded             name         static
 number of network tasks                                            1                      0                           8                            8             number       dynamic




!!! disable firewall
systemctl stop firewalld
systemctl disable firewalld

#######################################
############# TESTY AZURE ############# 
#######################################


#####Size Standard D4s v3 = vCPUs 4 RAM 16 GiB max IOPS 6400, 2 x premium SSD (Max 120 IOPS)
## 4 threads

### ASE i JAVA na jednym hoscie
# 32 conections
-> 1 load: 1 minute(s), 48 second(s) (1.800 minutes)
-> 1 run: 14541.459 TpmC
-> 2 run: 14840.827 TpmC
-> 3 run: 14500.059 TpmC
-> 4 run: 14808.141 TpmC
-> 2 load:  1 minute(s), 11 second(s) (1.183 minutes)
-> 5 run: 13725.249 TpmC
-> 6 run: 13590.768 TpmC
# 128 connections
-> 7 run: 13978.215 TpmC

### ASE i JAVA na odzielnych hostach
# 32 conections
-> 1 load: 1 minute(s), 12 second(s) (1.200 minutes)
-> 1 run: 14316.659 TpmC
-> 2 run: 13885.066 TpmC
-> 3 run: 15432.656 TpmC
-> 4 run: 15340.421 TpmC
-> 2 load: 1 minute(s), 14 second(s) (1.233 minutes)
-> 5 run: 14354.97 TpmC
-> 6 run: 15214.182 TpmC
# 128 connections
-> 7 run: 13033.176 TpmC
-> 8 run: 14865.045 TpmC


#####Size Standard D8ds v4 vCPUs 8 RAM 32 GiB  max IOPS 12800, 2 x premium SSD (Max 120 IOPS)
## 4 threads

### ASE i JAVA na odzielnych hostach
# 32 conections
-> 1 load: 1 minute(s), 11 second(s) (1.183 minutes)
-> 1 run: 14098.71 TpmC
-> 2 run: 14381.166 TpmC
-> 3 run: 14452.628 TpmC
# 128 connections
-> 7 run: 14269.909 TpmC
-> 8 run: 13315.005 TpmC

## 8 threads
sp_helpthread
go
alter thread pool syb_default_pool with thread count = 8
go

# 32 conections
-> 1 load:  1 minute(s), 9 second(s) (1.150 minutes)
-> 1 run:  9295.057 TpmC
-> 2 run:  4500.949 TpmC              --> duze waity
-> 3 run: 12816.796 TpmC
-> 4 run: 12747.176 TpmC
-> 5 run: 12706.036 TpmC              -->  Committed Xacts=1241.1
# 128 connections
-> 7 run: 12291.542 TpmC
-> 8 run: 12469.468 TpmC

# 256 connections
12728.241 TpmC



################  zmiana na 16 warehouse

(gdy dane tylko na /opt/sap /dev/sdc2) przy tworzeniu bazy IOTOP 161.63 M/s -- D8ds v4 vCPUs 8 RAM 32 GiB  max IOPS 12800, premium SSD
potem load do max 25 M/s
(gdy dane w dwóch device na /dev/sda2 i /dev/sdc2) przy tworzeniu bazy IOTOP 300 M/s

!!!! trzeba maksymalnie porozdzielać na dyski

udało się dopiero po dołożeniu miesca lącznie 12GB
Po załadowaniu jest 8 888 032 KB
Po utworzeniu indeksow 8 974 208 KB
Total execution time: 16 minute(s), 10 second(s) (16.167 minutes)

# 32 connections
-> 1 run: 24120.371 TpmC ok 390% CPU i zapisu około 37 M/s
-> 2 run: 24065.785 TpmC
-> 3 run: 23856.83 TpmC

# 256 connections
-> 4 run: 52136.277 TpmC 660% CPU (prawie wysycona maszyna 2core z JAVA) i zapis około 24 M/s
-> 5 run: 47242.9 TpmC  --> sysmon Committed Xacts 4673.5

-- restart -- uwaga po restarcie pobiera do cache tylko losowe strony wiec wciąż jest też i odczyt
-- zmiana ustawien disk task =4 + tuning network

-> 1 run (czyta dane z dysku): 38084.95 TpmC
-> 2 run: 39893.934 TpmC  550% CPU (prawie wysycona maszyna 2core z JAVA) i zapis około 60 M/s i odczyt do 20%
-> 3 run: 39033.81 TpmC 550% CPU (prawie wysycona maszyna 2core z JAVA) i zapis około 60 M/s i odczyt do 20%
-> 4 run: 39702.844 TpmC 550% CPU (prawie wysycona maszyna 2core z JAVA) i zapis około 60 M/s i odczyt do 20%

-- odtwarzam baze na nowo aby byl pelny cache
Total execution time: 15 minute(s), 23 second(s) (15.383 minutes)
> 1 run (nie czyta danych z dysku): 42669.73 TpmC 600% CPU (prawie wysycona maszyna 2core z JAVA) i zapis około 30 M/s
> 2 run 42164.312 TpmC
-- zmiana ustawien 1.1
-- restart
Total execution time: 15 minute(s), 36 second(s) (15.600 minutes)
> 1 run (nie czyta danych z dysku): 28531.992 TpmC 450% CPU (prawie wysycona maszyna 2core z JAVA)
> 2 run: 28538.012 TpmC 450% CPU (prawie wysycona maszyna 2core z JAVA)
-- zmiana ustawien 1.2
> 3 run: 28315.43 TpmC TpmC 430% CPU (prawie wysycona maszyna 2core z JAVA)

-- zmiana 1.3 !!! czyli musi być mniejszy pakiet 4k
-- restart
> 1 run: 39365.17 TpmC 550% CPU (prawie wysycona maszyna 2core z JAVA)
> 2 run: 40743.598 TpmC 570% CPU (prawie wysycona maszyna 2core z JAVA)

-- zmiana 1.4 -- brak wiekszego zysku czyli zostawiamy
> 3 run: 41793.043 TpmC  540% CPU (prawie wysycona maszyna 2core z JAVA)
> 4 run: 41529.176 TpmC 550% CPU (prawie wysycona maszyna 2core z JAVA)

-- zwiekszam maszyne z JAVA z 2 core do 4 core
> 5 run: 22062.88 TpmC  duze wachania CPU, niestabilnie
> 6 run: 45917.99 TpmC 600% (240% cpu maszyna 4core z JAVA)
> 7 run: 22905.93 TpmC
> 8 run: 46223.43 TpmC z sysmon
> 9 run: 45795.03 TpmC
> 10 run: 47906.82 TpmC z mds_sysmon

!!!! jest ok trzeba podsumować
- dla 256 polaczen trzeba klienta 4core 16 warehouse i aktualnej konfiguracji

use demodb
go
sp_spaceused syslogs
go
dump tran demodb with truncate_only
go

1> exec tempdb..sp_mda_sysmon "00:00:30"
2> go
### DATE ###
 current_time
 ----------------------------------
 24/06/26 14:46:29

(1 row affected)
### STATE ###
 InstanceID Transactions  LogicalReads  Selects       Inserts       Updates       Deletes
 ---------- ------------- ------------- ------------- ------------- ------------- -------------
          0        139503       8622088        716971        306842        391963         23672

(1 row affected)
### monSysExecutionTime ###
 InstanceID OperationID OperationName                                                ExecutionTime        ExecutionCnt         Time_per_Cnt
 ---------- ----------- ------------------------------------------------------------ -------------------- -------------------- --------------------
          0           0 Unknown                                                                  34532970                    0                    0
          0           1 Execution                                                                99716763              1809570                   55
          0           2 Sorting                                                                       146                    2                   73
          0           3 Compilation                                                               8330798               394889                   21
          0           4 NetworkIO                                                                26771299              8530962                    3
          0           5 DeviceIO                                                                 69891262                30948                 2258

(6 rows affected)
### Statement cache ###
 InstanceID TotalSizeKB UsedSizeKB  NumStatements NumSearches   HitCount      NumInserts    NumRemovals
 ---------- ----------- ----------- ------------- ------------- ------------- ------------- -------------
          0      204800        8216             0         85291         85291             0             0

(1 row affected)
### Engines ###
 InstanceID EngineNumber SystemTime      UserTime        IOTime          IdleTime
 ---------- ------------ --------------- --------------- --------------- ---------------
          0            0           13.33           86.66            0.00            3.33
          0            1           13.33           86.66            0.00            3.33
          0            2           13.33           86.66            0.00            0.00
          0            3            6.66           90.00            0.00            3.33
          0            4           33.33           66.66            0.00            3.33
          0            5           16.66           86.66            0.00            0.00
          0            6           23.33           76.66            0.00            0.00
          0            7           13.33           83.33            0.00            0.00

(8 rows affected)
### Spinlocks ###
 InstanceID SpinlockName                                                                                                                     Grabs                Spins                Waits                Contention
 ---------- -------------------------------------------------------------------------------------------------------------------------------- -------------------- -------------------- -------------------- --------------------
          0 default data cache                                                                                                                           10264374             54489379               405564                    3
          0 default data cache                                                                                                                            6586623             29194538               212146                    3
          0 fglockspins                                                                                                                                   6157321             91356785               122724                    1
          0 default data cache                                                                                                                            4490802             33216890               105320                    2
          0 tablockspins                                                                                                                                  3494411             36132555                71410                    2
          0 default data cache                                                                                                                            3296734             32258756                54080                    1
          0 default data cache                                                                                                                            3101613             42099193                48719                    1
          0 default data cache                                                                                                                            3086356             21532637                47251                    1
          0 default data cache                                                                                                                            2722665             44235827                37719                    1
          0 default data cache                                                                                                                            2287836             13723975                29626                    1
          0 Des Upd Spinlocks                                                                                                                             4490605             29880445                18944                    0
          0 Resource->rdesmgr_spin                                                                                                                        2388383             16736488                17811                    0
          0 Pdes Spinlocks                                                                                                                                8191660              1777564                16864                    0
          0 Resource->rprocmgr_spin                                                                                                                       1440264              1281964                10800                    0
          0 Dbtable->dbt_xdesqueue_spin                                                                                                                    605125             36587081                 8361                    1
          0 bufspin default data cache                                                                                                                    8699064              7114421                 4117                    0
          0 DES Name Hash Bucket Spin                                                                                                                     1440061              9673700                 2823                    0
          0 SSQLCACHE_SPIN[i]                                                                                                                              373228               424599                 2409                    0
          0 User Log Cache Spinlocks                                                                                                                     20973115               142204                 1836                    0
          0 Dbtable->dbt_plcblock_queue_spin                                                                                                               872656               168045                 1796                    0
          0 bufspin default data cache                                                                                                                    5743245              1175664                 1522                    0
          0 Kernel->kpsleepqspinlock[i]                                                                                                                   4414449               134002                 1086                    0
          0 Resource->rqueryplan_spin[i]                                                                                                                  4272404               684881                  817                    0
          0 Sched Q                                                                                                                                        549680                60341                  738                    0
          0 Sched Q                                                                                                                                        517902             18213871                  734                    0
          0 Sched Q                                                                                                                                        520805             21746308                  720                    0
          0 Sched Q                                                                                                                                        529092                73826                  710                    0
          0 Sched Q                                                                                                                                        510926             26859761                  688                    0
          0 Sched Q                                                                                                                                        525056                60460                  671                    0
          0 Kernel->kpprocspin[i]                                                                                                                        10416749              9917243                  653                    0

(30 rows affected)
### IO stats ###
 LogicalName                                                  IOType                   Reads                APFReads             Writes               IOs                  IOTime               AVG_ms_per_IO
 ------------------------------------------------------------ ------------------------ -------------------- -------------------- -------------------- -------------------- -------------------- --------------------
 tempdbdev                                                    Tempdb Log                                  0                    0                    1                    1                    2                    2
 tempdbdev                                                    System                                      0                    0                    1                    0                    0                    0
 systemdbdev                                                  System                                      0                    0                    0                    0                    0                    0
 sysprocsdev                                                  User Log                                    0                    0                    6                    3                   12                    4
 sysprocsdev                                                  User Data                                   0                    0                    6                    0                    0                    0
 sysprocsdev                                                  System                                      0                    0                    6                    3                    8                    2
 master                                                       User Log                                    6                    0                    9                    0                    0                    0
 master                                                       User Data                                   6                    0                    9                    0                    0                    0
 master                                                       Tempdb Log                                  6                    0                    9                    0                    0                    0
 master                                                       Tempdb Data                                 6                    0                    9                    1                    1                    1
 master                                                       System                                      6                    0                    9                   14                   30                    2
 demodb_12_dat                                                System                                      0                    0                    0                    0                    0                    0
 demodb_11_dat                                                System                                      0                    0                    0                    0                    0                    0
 demodb_10_dat                                                User Data                                   7                    0                 1278                 1240                 2206                    1
 demodb_10_dat                                                System                                      7                    0                 1278                   45                   59                    1
 demodb_09_dat                                                User Data                                 646                    0                 1284                 1925                 2502                    1
 demodb_09_dat                                                System                                    646                    0                 1284                    5                    7                    1
 demodb_08_dat                                                User Data                                1030                    0                 1632                 2662                 5512                    2
 demodb_08_dat                                                System                                   1030                    0                 1632                    0                    0                    0
 demodb_07_dat                                                User Data                                1004                    0                 1592                 2596                 5450                    2
 demodb_07_dat                                                System                                   1004                    0                 1592                    0                    0                    0
 demodb_06_dat                                                User Data                                1022                    0                 1647                 2669                 5526                    2
 demodb_06_dat                                                System                                   1022                    0                 1647                    0                    0                    0
 demodb_05_dat                                                User Data                                1047                    0                 1699                 2745                 5329                    1
 demodb_05_dat                                                System                                   1047                    0                 1699                    0                    0                    0
 demodb_04_dat                                                User Data                                 992                    0                 1644                 2636                 5526                    2
 demodb_04_dat                                                System                                    992                    0                 1644                    0                    0                    0
 demodb_03_dat                                                User Data                                1005                    0                 1620                 2625                 5545                    2
 demodb_03_dat                                                System                                   1005                    0                 1620                    0                    0                    0
 demodb_02_log                                                User Log                                   21                    0                    0                   21                   62                    2
 demodb_02_log                                                System                                     21                    0                    0                    0                    0                    0
 demodb_02_dat                                                User Data                                1005                    0                 1686                 2691                 5397                    2
 demodb_02_dat                                                System                                   1005                    0                 1686                    0                    0                    0
 demodb_01_log                                                User Log                                    9                    0                 7151                 7155                13170                    1
 demodb_01_log                                                System                                      9                    0                 7151                    6                    5                    0
 demodb_01_dat                                                User Data                                 410                    0                 1499                 1906                 4057                    2
 demodb_01_dat                                                System                                    410                    0                 1499                    4                    4                    1

(37 rows affected)
### IO controllers stats ###
 InstanceID ControllerID Type                                                         BlockingPolls        NonBlockingPolls     EventPolls           NonBlockingEventPolls FullPolls            Events               Pending_after Pending              Completed            Reads                Writes               Deferred
 ---------- ------------ ------------------------------------------------------------ -------------------- -------------------- -------------------- --------------------- -------------------- -------------------- ------------- -------------------- -------------------- -------------------- -------------------- --------------------
          0            1 CtlibController                                                                 0                    0                    0                     0                    0                    0             1                    0                    0                    0                    0                    0
          0            2 NetController                                                              120116               499505               134091                 13975                    0               222063            32                    0                    0               221593               221743                    0
          0            3 NetController                                                              122709               510516               136966                 14257                    0               226831            33                    0                    0               226347               226472                    0
          0            4 NetController                                                              121277               504852               135675                 14398                    0               223757            33                    0                    0               223317               223463                    0
          0            5 NetController                                                              116373               484151               130087                 13714                    0               218026            32                    0                    0               217623               217746                    0
          0            6 NetController                                                              121571               506171               136217                 14646                    0               225210            32                    0                    0               224798               224944                    0
          0            7 NetController                                                              117544               489499               131688                 14144                    0               221630            33                    0                    0               221151               221283                    0
          0            8 NetController                                                              120410               501561               135011                 14601                    0               224431            32                    0                    0               223956               224087                    0
          0            9 NetController                                                              121175               504520               135717                 14542                    0               225598            32                    0                    0               225140               225273                    0
          0           10 DiskController                                                                  0                    0                    0                     0                    0                    0             1                    0                 7737                 2041                 5696                    0
          0           11 DiskController                                                                  0                    0                    0                     0                    0                    0             0                    0                 7737                 2039                 5698                    0
          0           12 DiskController                                                                  0                    0                    0                     0                    0                    0             1                    0                 7738                 2085                 5653                    0
          0           13 DiskController                                                                  0                    0                    0                     0                    0                    0             1                    0                 7738                 2037                 5701                    0

(13 rows affected)
### Waits stats ###
 InstanceID WaitEventID ClassDescription                                                                                                                 EventDescription                                                                                                                 WaitTime             Waits
 ---------- ----------- -------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------- --------------------
          0         215 waiting to be scheduled                                                                                                          waiting on run queue after sleep                                                                                                                 3919              2058226
          0         250 waiting for input from the network                                                                                               waiting for incoming network data                                                                                                                2369              1782541
          0         150 waiting to take a lock                                                                                                           waiting for a lock                                                                                                                                406                29791
          0         902 waiting on another thread                                                                                                        waiting for PLCBLOCK that is queued or being flushed                                                                                              273                72105
          0          19 waiting for internal system event                                                                                                xact coord: pause during idle loop                                                                                                                240                    4
          0          54 waiting for a disk write to complete                                                                                             waiting for write of the last log page to complete                                                                                                219                57959
          0          52 waiting for a disk write to complete                                                                                             waiting for i/o on MASS initated by another task                                                                                                  181                85419
          0          61 waiting for internal system event                                                                                                hk: pause for some time                                                                                                                            98                   10
          0          41 waiting for internal system event                                                                                                wait to acquire latch                                                                                                                              59                 6717
          0         260 waiting for internal system event                                                                                                waiting for date or time in waitfor command                                                                                                        30                    1
          0         104 waiting for internal system event                                                                                                wait until an engine has been offlined                                                                                                             30                    1
          0          36 waiting for memory or a buffer                                                                                                   waiting for MASS to finish writing before changing                                                                                                 28                 4222
          0         214 waiting to be scheduled                                                                                                          waiting on run queue after yield                                                                                                                   16                 6466
          0         272 waiting for internal system event                                                                                                waiting for lock on ULC                                                                                                                             6                 1657
          0         251 waiting to output to the network                                                                                                 waiting for network send to complete                                                                                                                1                 1178
          0          29 waiting for a disk read to complete                                                                                              waiting for regular buffer read to complete                                                                                                         0                 8129
          0          55 waiting for a disk write to complete                                                                                             wait for i/o to finish after writing last log page                                                                                                  0                 3730
          0          51 waiting for a disk write to complete                                                                                             waiting for last i/o on MASS to complete                                                                                                            0                 3072
          0          53 waiting for memory or a buffer                                                                                                   waiting for MASS to finish changing to start i/o                                                                                                    0                  937
          0          31 waiting for a disk write to complete                                                                                             waiting for buf write to complete before writing                                                                                                    0                  549
          0         876 waiting for internal system event                                                                                                wait if buffer is changed in smp_bufpredirty                                                                                                        0                   46
          0         704 waiting for internal system event                                                                                                waiting for lock on PLCBLOCK                                                                                                                        0                   27
          0          38 waiting for memory or a buffer                                                                                                   wait for mass to be validated or finish changing                                                                                                    0                    1

(23 rows affected)
### Cache stats (datacache) ###
 InstanceID CacheID     CacheSearches_d PhysicalReads_d APFReads_d  LogicalReads_d PhysicalWrites_d Stalls_d    Stalls      CacheName                                                    ReplacementStrategy
 ---------- ----------- --------------- --------------- ----------- -------------- ---------------- ----------- ----------- ------------------------------------------------------------ ------------------------------------------------------------
          0           0        13444652            8202           0       13444652            22745           0           0 default data cache                                           strict LRU

(1 row affected)
### Cache stats (pools) ###
 InstanceID CacheID     Wielkosc_MB PRCT_FULL   IOBufferSize PhysicalReads_d APFReads_d  LogicalReads_d PhysicalWrites_d Stalls_d    Stalls      PoolName
 ---------- ----------- ----------- ----------- ------------ --------------- ----------- -------------- ---------------- ----------- ----------- ----------------------------------------------------------------------
          0           0        2384          24        16384             813           0       13324703             7397           0           0 default data cache 16
          0           0         240          47        65536            7389           0         120157            15347           0           0 default data cache 64

(2 rows affected)




1> sp_sysmon "00:00:45"
2> go
===============================================================================
      Sybase Adaptive Server Enterprise System Performance Report
===============================================================================

Server Version:        Adaptive Server Enterprise/16.0 SP04 PL03/EBF 30399 SMP/
                       P/x86_64/SLES 12.4/ase160sp04pl03x/3587/64-bit/FBO/Wed A
                       ug 24 01:39:32 2022
Run Date:              Jun 26, 2024
Sampling Started at:   Jun 26, 2024 14:26:20
Sampling Ended at:     Jun 26, 2024 14:27:05
Sample Interval:       00:00:45
Sample Mode:           No Clear
Counters Last Cleared: Jun 26, 2024 13:58:42
Server Name:           SPEC
===============================================================================

Kernel Utilization
------------------


  Engine Utilization (Tick %)   User Busy   System Busy    I/O Busy        Idle
  -------------------------  ------------  ------------  ----------  ----------
  ThreadPool : syb_default_pool
   Engine 0                        86.4 %        12.2 %       0.0 %       1.3 %
   Engine 1                        30.0 %        69.6 %       0.0 %       0.4 %
   Engine 2                        66.7 %        32.4 %       0.0 %       0.9 %
   Engine 3                        83.3 %        15.1 %       0.0 %       1.6 %
   Engine 4                        90.4 %         8.2 %       0.0 %       1.3 %
   Engine 5                        89.1 %         9.3 %       0.0 %       1.6 %
   Engine 6                        91.3 %         7.1 %       0.0 %       1.6 %
   Engine 7                        84.7 %        14.2 %       0.0 %       1.1 %
  -------------------------  ------------  ------------  ----------  ----------
  Pool Summary        Total       622.0 %       168.2 %       0.0 %       9.8 %
                    Average        77.8 %        21.0 %       0.0 %       1.2 %

  -------------------------  ------------  ------------  ----------  ----------
  Server Summary      Total       622.0 %       168.2 %       0.0 %       9.8 %
                    Average        77.8 %        21.0 %       0.0 %       1.2 %


  Average Runnable Tasks            1 min         5 min      15 min  % of total
  -------------------------  ------------  ------------  ----------  ----------
  ThreadPool : syb_default_pool
   Global Queue                       0.2           0.1         0.1       0.1 %
   Engine 0                          13.9           8.8         6.1      11.4 %
   Engine 1                           5.7           4.6         4.3       4.7 %
   Engine 2                          15.1           8.8         6.3      12.4 %
   Engine 3                          20.3          10.3         6.6      16.7 %
   Engine 4                          15.5           9.2         6.2      12.8 %
   Engine 5                          21.3          11.9         7.7      17.5 %
   Engine 6                          15.0           9.6         6.7      12.3 %
   Engine 7                          14.6           8.8         6.0      12.0 %
  -------------------------  ------------  ------------  ----------
  Pool Summary        Total         121.6          72.0        49.9
                    Average          13.5           8.0         5.5

  -------------------------  ------------  ------------  ----------
  Server Summary      Total         121.6          72.0        49.9
                    Average          13.5           8.0         5.5


  CPU Yields by Engine            per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  ThreadPool : syb_default_pool
   Engine 0
      Full Sleeps                     1.5           0.0          66       3.5 %
      Interrupted Sleeps              3.6           0.0         163       8.7 %
   Engine 1
      Full Sleeps                     0.6           0.0          27       1.4 %
      Interrupted Sleeps              2.2           0.0         100       5.4 %
   Engine 2
      Full Sleeps                     1.0           0.0          43       2.3 %
      Interrupted Sleeps              4.2           0.0         189      10.1 %
   Engine 3
      Full Sleeps                     1.6           0.0          74       4.0 %
      Interrupted Sleeps              3.7           0.0         166       8.9 %
   Engine 4
      Full Sleeps                     1.5           0.0          69       3.7 %
      Interrupted Sleeps              4.1           0.0         184       9.9 %
   Engine 5
      Full Sleeps                     1.7           0.0          76       4.1 %
      Interrupted Sleeps              4.4           0.0         199      10.7 %
   Engine 6
      Full Sleeps                     1.6           0.0          72       3.9 %
      Interrupted Sleeps              3.4           0.0         154       8.3 %
   Engine 7
      Full Sleeps                     1.5           0.0          68       3.7 %
      Interrupted Sleeps              4.7           0.0         213      11.4 %
  -------------------------  ------------  ------------  ----------
  Pool Summary                       41.4           0.0        1863

  -------------------------  ------------  ------------  ----------
  Total CPU Yields                   41.4           0.0        1863


  Thread Utilization (OS %)     User Busy   System Busy        Idle
  -------------------------  ------------  ------------  ----------
  ThreadPool : syb_blocking_pool : no activity during sample

  ThreadPool : syb_default_pool
   Thread 2    (Engine 0)          53.5 %        16.7 %      29.8 %
   Thread 3    (Engine 1)          19.6 %         6.8 %      73.6 %
   Thread 4    (Engine 2)          43.0 %        13.9 %      43.2 %
   Thread 5    (Engine 3)          51.5 %        16.7 %      31.8 %
   Thread 6    (Engine 4)          56.5 %        17.7 %      25.8 %
   Thread 7    (Engine 5)          55.1 %        18.0 %      26.9 %
   Thread 8    (Engine 6)          57.1 %        18.0 %      24.8 %
   Thread 9    (Engine 7)          51.9 %        15.7 %      32.3 %
  -------------------------  ------------  ------------  ----------
  Pool Summary      Total         388.2 %       123.5 %     288.2 %
                  Average          48.5 %        15.4 %      36.0 %

  ThreadPool : syb_system_pool
   Thread 1    (Signal Handler)     0.0 %         0.0 %     100.0 %
   Thread 14   (NetController)      3.3 %         5.5 %      91.2 %
   Thread 15   (NetController)      3.4 %         5.6 %      91.0 %
   Thread 16   (NetController)      3.4 %         5.6 %      91.0 %
   Thread 17   (NetController)      3.5 %         5.5 %      91.0 %
   Thread 18   (NetController)      3.3 %         5.6 %      91.1 %
   Thread 19   (NetController)      3.5 %         5.6 %      91.0 %
   Thread 20   (NetController)      3.5 %         5.6 %      90.9 %
   Thread 21   (NetController)      3.2 %         5.6 %      91.2 %
  -------------------------  ------------  ------------  ----------
  Pool Summary      Total          27.2 %        44.5 %     828.3 %
                  Average           3.0 %         4.9 %      92.0 %

  -------------------------  ------------  ------------  ----------
  Server Summary    Total         415.4 %       168.0 %    1516.6 %
                  Average          19.8 %         8.0 %      72.2 %

  Adaptive Server threads are consuming 5.8 CPU units.
  Throughput (committed xacts per CPU unit) : 768.5


  Page Faults at OS               per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
   Minor Faults                     368.4           0.1       16577     100.0 %
   Major Faults                       0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
   Total Page Faults                368.4           0.1       16577     100.0 %


  Context Switches at OS          per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  ThreadPool : syb_blocking_pool
   Voluntary                          0.0           0.0           0       0.0 %
   Non-Voluntary                      0.0           0.0           0       0.0 %
  ThreadPool : syb_default_pool
   Voluntary                       1502.0           0.3       67590       4.2 %
   Non-Voluntary                    149.2           0.0        6715       0.4 %
  ThreadPool : syb_system_pool
   Voluntary                      33715.4           7.5     1517191      95.3 %
   Non-Voluntary                      5.3           0.0         238       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
   Total Context Switches         35371.9           7.9     1591734     100.0 %


  CtlibController Activity        per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
   Polls                             0.0           0.0           0       0.0 %

  DiskController Activity         per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
   Polls                             0.0           0.0           0       0.0 %

  NetController Activity          per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
   Polls                         174123.0          38.8     7835534       n/a
   Polls Returning Events         37184.9           8.3     1673321      21.4 %
   Polls Returning Max Events         0.0           0.0           0       0.0 %
   Total Events                   57528.7          12.8     2588793       n/a
   Events Per Poll                    n/a           n/a       0.330       n/a


  Blocking Call Activity          per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total Requests                      0.0           0.0           0       n/a


Bucketpool Activity
-------------------

  Bucketpool Name             BucketSize   Allocs     Frees    Found empty
  -------------------------  ----------- ---------- ---------- ----------
  Encrypted Columns Frag             0          0          0          0
  Encrypted Columns Frag            32          0          0          0
  Encrypted Columns Frag            64          0          0          0
  Encrypted Columns Frag            96          0          0          0
  Encrypted Columns Frag           128          0          0          0
  Encrypted Columns Frag           160          0          0          0
  Encrypted Columns Frag           192          0          0          0
  Encrypted Columns Frag           224          0          0          0
  Encrypted Columns Frag           256          0          0          0
  Encrypted Columns Frag           288          0          0          0
  Encrypted Columns Frag           320          0          0          0
  Encrypted Columns Frag           352          0          0          0
  LFB memory pool                    0          0          0          0
  LFB memory pool                   32          0          0          0
  LFB memory pool                   64          0          0          0
  LFB memory pool                   96          0          0          0
  LFB memory pool                  128          0          0          0
  LFB memory pool                  160          0          0          0
  LFB memory pool                  192          0          0          0
  LFB memory pool                  224          0          0          0
  LFB memory pool                  256          0          0          0
  LFB memory pool                  288          0          0          0
  LFB memory pool                  320          0          0          0
  LFB memory pool                  352          0          0          0
  LFB memory pool                  384          0          0          0
  LFB memory pool                  416          0          0          0
  LFB memory pool                  448          0          0          0
  LFB memory pool                  480          0          0          0
  LFB memory pool                  512          0          0          0
  LFB memory pool                  544          0          0          0
  LFB memory pool                  576          0          0          0
  LFB memory pool                  608          0          0          0
  LFB memory pool                  640          0          0          0
  Network Buffers                    0          0          0          0
  Network Buffers                   32          0          0          0
  Network Buffers                   64          0          0          0
  Network Buffers                   96          0          0          0
  Network Buffers                  128          0          0          0
  Network Buffers                  160          0          0          0
  Network Buffers                  192          0          0          0
  Network Buffers                  224          0          0          0
  Network Buffers                  256          0          0          0
  Network Buffers                  288          0          0          0
  Network Buffers                  320          0          0          0
  Network Buffers                  352          0          0          0
  Worker Thread Memory               0          0          0          0
  Worker Thread Memory              32          0          0          0
  Worker Thread Memory              64          0          0          0
  Worker Thread Memory              96          0          0          0
  Worker Thread Memory             128          0          0          0

===============================================================================

Worker Process Management
-------------------------
                                  per sec      per xact       count  % of total
                             ------------  ------------  ----------  ----------
 Worker Process Requests
   Total Requests                     0.0           0.0           0       n/a

 Worker Process Usage
   Total Used                         0.0           0.0           0       n/a
   Max Ever Used During Sample        0.0           0.0           0       n/a

 Memory Requests for Worker Processes
   Total Requests                     0.0           0.0           0       n/a

 Tuning Recommendations for Worker Processes
 -------------------------------------------
  - Consider decreasing the 'number of worker processes'
    configuration parameter.


===============================================================================

Parallel Query Management
-------------------------

  Parallel Query Usage            per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total Parallel Queries              0.0           0.0           0       n/a

  Merge Lock Requests             per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total # of Requests                 0.0           0.0           0       n/a

  Sort Buffer Waits               per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total # of Waits                    0.0           0.0           0       n/a

===============================================================================

Task Management                   per sec      per xact       count  % of total
---------------------------  ------------  ------------  ----------  ----------

  Connections Opened                  0.0           0.0           0       n/a

  Task Context Switches by Engine

  ThreadPool : syb_default_pool
    Engine 0                       9164.3           2.0      412392      13.9 %
    Engine 1                       3203.8           0.7      144169       4.8 %
    Engine 2                       7308.5           1.6      328882      11.0 %
    Engine 3                       8818.1           2.0      396816      13.3 %
    Engine 4                       9621.0           2.1      432945      14.5 %
    Engine 5                       9463.2           2.1      425843      14.3 %
    Engine 6                       9754.9           2.2      438972      14.7 %
    Engine 7                       8808.3           2.0      396372      13.3 %
  -------------------------  ------------  ------------  ----------
  Pool Summary        Total       66142.0          14.8     2976391
                    Average        8267.7           1.8      372048

  -------------------------  ------------  ------------  ----------
    Total Task Switches:          66142.0          14.8     2976391

  Task Context Switches Due To:
    Voluntary Yields                205.4           0.0        9242       0.3 %
    Cache Search Misses             284.9           0.1       12819       0.4 %
    Exceeding I/O batch size          5.3           0.0         237       0.0 %
    System Disk Writes              121.1           0.0        5449       0.2 %
    Logical Lock Contention         689.0           0.2       31005       1.0 %
    Address Lock Contention           0.2           0.0           7       0.0 %
    Latch Contention                194.5           0.0        8751       0.3 %
    Physical Lock Transition          0.0           0.0           0       0.0 %
    Logical Lock Transition           0.0           0.0           0       0.0 %
    Object Lock Transition            0.0           0.0           0       0.0 %
    Log Semaphore Contention        233.2           0.1       10493       0.4 %
    IMRSLog Semaphore Contention      0.0           0.0           0       0.0 %
    PLCBLOCK flush                 2142.8           0.5       96424       3.2 %
    PLC Lock Contention              52.2           0.0        2350       0.1 %
    Group Commit Sleeps            4420.6           1.0      198928       6.7 %
    Last Log Page Writes            109.7           0.0        4935       0.2 %
    Modify Conflicts                154.4           0.0        6946       0.2 %
    I/O Device Contention             0.0           0.0           0       0.0 %
    Network Packet Received       57491.9          12.8     2587137      86.9 %
    Network Packet Sent              37.5           0.0        1688       0.1 %
    Interconnect Message Sleeps       0.0           0.0           0       0.0 %
    Network services                  0.0           0.0           0       0.0 %
    Other Causes                      0.0           0.0           0       0.0 %

  Tuning Recommendations for Task Management
  ------------------------------------------
  - Consider tuning your Network I/O sub-system.


===============================================================================

Application Management
----------------------

  Application Statistics Summary (All Applications)
  -------------------------------------------------
  Priority Changes                per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    To High Priority               1149.9           0.3       51747      48.9 %
    To Medium Priority             1174.8           0.3       52864      49.9 %
    To Low Priority                  27.2           0.0        1224       1.2 %
  -------------------------  ------------  ------------  ----------
  Total Priority Changes           2351.9           0.5      105835

  Allotted Slices Exhausted       per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    High Priority                     0.2           0.0          11       0.3 %
    Medium Priority                  71.0           0.0        3196      99.7 %
    Low Priority                      0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------
  Total Slices Exhausted             71.3           0.0        3207

  Skipped Tasks By Engine         per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Engine 0                          0.2           0.0           8      17.4 %
    Engine 1                          0.2           0.0           7      15.2 %
    Engine 2                          0.1           0.0           3       6.5 %
    Engine 3                          0.1           0.0           4       8.7 %
    Engine 4                          0.2           0.0           8      17.4 %
    Engine 5                          0.0           0.0           2       4.3 %
    Engine 6                          0.1           0.0           3       6.5 %
    Engine 7                          0.2           0.0          11      23.9 %
  -------------------------  ------------  ------------  ----------
  Total Engine Skips                  1.0           0.0          46

  Engine Scope Changes                0.0           0.0           0       n/a

===============================================================================

ESP Management                    per sec      per xact       count  % of total
---------------------------  ------------  ------------  ----------  ----------
  ESP Requests                        0.0           0.0           0       n/a
===============================================================================

Housekeeper Task Activity
-------------------------
                                  per sec      per xact       count  % of total
                             ------------  ------------  ----------
Buffer Cache Washes
  Clean                            213.0           0.0        9587      38.5 %
  Dirty                            340.4           0.1       15318      61.5 %
                             ------------  ------------  ----------
Total Washes                       553.4           0.1       24905

Garbage Collections                  1.4           0.0          64       n/a
Pages Processed in GC              275.4           0.1       12392       n/a

Statistics Updates                   0.2           0.0           8       n/a

===============================================================================

Monitor Access to Executing SQL
-------------------------------
                                  per sec      per xact       count  % of total
                             ------------  ------------  ----------  ----------
 Waits on Execution Plans            0.0           0.0           0       n/a
 Number of SQL Text Overflows        0.0           0.0           0       n/a
 Maximum SQL Text Requested          n/a           n/a         136       n/a
  (since beginning of sample)


 Tuning Recommendations for Monitor Access to Executing SQL
 ----------------------------------------------------------
 - Consider decreasing the 'max SQL text monitored' parameter
   to 1092 (i.e., half way from its current value to Maximum
   SQL Text Requested).

===============================================================================

Transaction Profile
-------------------

  Transaction Summary             per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Committed Xacts                4483.4           n/a      201752     n/a

  Transaction Detail              per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Inserts
    Fully Logged
      APL Heap Table                  0.0           0.0           0       0.0 %
      APL Clustered Table             0.0           0.0           0       0.0 %
      Data Only Lock Table        11617.2           2.6      522775     100.0 %
      Fast Bulk Insert                0.0           0.0           0       0.0 %
      Fast Log Bulk Insert            0.0           0.0           0       0.0 %
    Minimally Logged
      APL Heap Table                  0.0           0.0           0       0.0 %
      APL Clustered Table             0.0           0.0           0       0.0 %
      Data Only Lock Table            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total Rows Inserted             11617.2           2.6      522775      36.5 %

  Updates
    Fully Logged
      APL Deferred                    0.0           0.0           0       0.0 %
      APL Direct In-place             0.0           0.0           0       0.0 %
      APL Direct Cheap                0.0           0.0           0       0.0 %
      APL Direct Expensive            0.0           0.0           0       0.0 %
      DOL Deferred                    0.0           0.0           0       0.0 %
      DOL Direct                  19485.9           4.3      876866     100.0 %
    Minimally Logged
      APL Direct In-place             0.0           0.0           0       0.0 %
      APL Direct Cheap                0.0           0.0           0       0.0 %
      APL Direct Expensive            0.0           0.0           0       0.0 %
      DOL Direct                      0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total Rows Updated              19485.9           4.3      876866      61.2 %

  Data Only Locked Updates
    Fully Logged
      DOL Replace                 11192.1           2.5      503646      69.7 %
      DOL Shrink                      0.0           0.0           0       0.0 %
      DOL Cheap Expand             4620.5           1.0      207921      28.8 %
      DOL Expensive Expand         2089.7           0.5       94036      13.0 %
      DOL Expand & Forward         1581.4           0.4       71165       9.8 %
      DOL Fwd Row Returned            2.2           0.0          98       0.0 %
    Minimally Logged
      DOL Replace                     0.0           0.0           0       0.0 %
      DOL Shrink                      0.0           0.0           0       0.0 %
      DOL Cheap Expand                0.0           0.0           0       0.0 %
      DOL Expensive Expand            0.0           0.0           0       0.0 %
      DOL Expand & Forward            0.0           0.0           0       0.0 %
      DOL Fwd Row Returned            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total DOL Rows Updated          16055.7           3.6      722506      50.4 %

  Deletes
    Fully Logged
      APL Deferred                    0.0           0.0           0       0.0 %
      APL Direct                      0.0           0.0           0       0.0 %
      DOL                           753.1           0.2       33889     100.0 %
    Minimally Logged
      APL Direct                      0.0           0.0           0       0.0 %
      DOL                             0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total Rows Deleted                753.1           0.2       33889       2.4 %

  Selects
    Total Rows Selected           22351.5           5.0     1005817     100.0 %

  =========================  ============  ============  ==========
  Total Rows Affected             31856.2           7.1     1433530
  =========================  ============  ============  ==========

===============================================================================

Transaction Management
----------------------

  ULC Flushes to Xact Log         per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Any Logging Mode DMLs
    by End Transaction             4343.4           1.0      195453      98.9 %
    by Change of Database             0.0           0.0           1       0.0 %
    by Unpin                          0.3           0.0          12       0.0 %
    by Log markers                    1.7           0.0          78       0.0 %
    by No Free Plcblock              22.5           0.0        1011       0.5 %

  Fully Logged DMLs
    by Full ULC                       0.2           0.0          11       0.0 %
    by Single Log Record             22.0           0.0         991       0.5 %

  Minimally Logged DMLs
    by Full ULC                       0.0           0.0           0       0.0 %
    by Single Log Record              0.0           0.0           0       0.0 %
    by Start of Sub-Command           0.0           0.0           0       0.0 %
    by End of Sub-Command             0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------
  Total ULC Flushes                4390.2           1.0      197559

  ULC Flushes Skipped             per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Fully Logged DMLs
    by ULC Discards                 153.3           0.0        6898     100.0 %
  Minimally Logged DMLs
    by ULC Discards                   0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------
  Total ULC Flushes Skips           153.3           0.0        6898

  ULC Log Records                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Fully Logged DMLs               62349.1          13.9     2805710       100.0
  Minimally Logged DMLs               0.0           0.0           0         0.0
  -------------------------  ------------  ------------  ----------
  Total ULC Log Records           62349.1          13.9     2805710

  Max ULC Size During Sample
  --------------------------
  Fully Logged DMLs                   n/a           n/a           0       n/a
  Minimally Logged DMLs               n/a           n/a           0       n/a

  ML-DMLs Sub-Command Scans       per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total Sub-Command Scans             0.0           0.0           0       n/a

  ML-DMLs ULC Efficiency          per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total ML-DML Sub-Commands           0.0           0.0           0       n/a

  ULC Semaphore Requests
    Granted                      136378.6          30.4     6137035     100.0 %
    Waited                           52.2           0.0        2350       0.0 %
  -------------------------  ------------  ------------  ----------
  Total ULC Semaphore Req        136430.8          30.4     6139385

  Log Semaphore Requests
    Granted                        2010.7           0.4       90482      89.6 %
    Local Waited                    233.2           0.1       10493      10.4 %
    Global Waited                     0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------
  Total Log Semaphore Req          2243.9           0.5      100975

  Transaction Log Writes            218.2           0.0        9817       n/a
  Transaction Log Alloc             402.8           0.1       18126       n/a
  Avg # Writes per Log Page           n/a           n/a     0.54160       n/a

===============================================================================

Index Management
----------------

  Nonclustered Maintenance        per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Ins/Upd Requiring Maint           0.0           0.0           0       n/a
      # of NC Ndx Maint               0.0           0.0           0       n/a

    Deletes Requiring Maint           0.0           0.0           0       n/a
      # of NC Ndx Maint               0.0           0.0           0       n/a

    RID Upd from Clust Split          0.0           0.0           0       n/a
      # of NC Ndx Maint               0.0           0.0           0       n/a

    Upd/Del DOL Req Maint         20239.0           4.5      910755       n/a
      # of DOL Ndx Maint            753.1           0.2       33889       n/a
      Avg DOL Ndx Maint / Op          n/a           n/a     0.03721       n/a

  Page Splits                        20.5           0.0         921       n/a
    Retries                           0.0           0.0           0       0.0 %
    Deadlocks                         0.0           0.0           0       0.0 %
    Add Index Level                   0.0           0.0           0       0.0 %

  Page Shrinks                        0.0           0.0           0       n/a

  Index Scans                     per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Ascending Scans                   2.0           0.0          88       0.0 %
    DOL Ascending Scans          101922.9          22.7     4586530      99.9 %
    Descending Scans                 14.4           0.0         650       0.0 %
    DOL Descending Scans             76.1           0.0        3424       0.1 %
                             ------------  ------------  ----------
    Total Scans                  102015.4          22.8     4590692

===============================================================================

Metadata Cache Management
-------------------------

  Metadata Cache Summary         per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------

  Open Object Usage
    Active                            n/a           n/a         641       n/a
    Max Ever Used Since Boot          n/a           n/a         726       n/a
    Free                              n/a           n/a        1359       n/a
    Reuse Requests
      Succeeded                       n/a           n/a           0       n/a
      Failed                          n/a           n/a           0       n/a

  Open Index Usage
    Active                            n/a           n/a          57       n/a
    Max Ever Used Since Boot          n/a           n/a          57       n/a
    Free                              n/a           n/a         443       n/a
    Reuse Requests
      Succeeded                       n/a           n/a           0       n/a
      Failed                          n/a           n/a           0       n/a

  Open Partition Usage
    Active                            n/a           n/a          57       n/a
    Max Ever Used Since Boot          n/a           n/a          57       n/a
    Free                              n/a           n/a         443       n/a
    Reuse Requests
      Succeeded                       n/a           n/a           0       n/a
      Failed                          n/a           n/a           0       n/a

  Open Database Usage
    Active                            n/a           n/a           6       n/a
    Max Ever Used Since Boot          n/a           n/a           6       n/a
    Free                              n/a           n/a           6       n/a
    Reuse Requests
      Succeeded                       n/a           n/a           0       n/a
      Failed                          n/a           n/a           0       n/a

  Descriptors immediately discarded   n/a           n/a           0       n/a
  Object Manager Spinlock Contention  n/a           n/a         n/a       0.7 %

  Object Spinlock Contention          n/a           n/a         n/a       0.4 %

  Index Spinlock Contention           n/a           n/a         n/a       0.0 %

  Index Hash Spinlock Contention      n/a           n/a         n/a       0.0 %

  Partition Spinlock Contention       n/a           n/a         n/a       0.0 %

  Partition Hash Spinlock Contention  n/a           n/a         n/a       0.0 %

===============================================================================

Lock Management
---------------

  Lock Summary                    per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total Lock Requests            142054.4          31.7     6392448       n/a
  Avg Lock Contention               689.2           0.2       31012       0.5 %
  Cluster Locks Retained              0.0           0.0           0       0.0 %
  Deadlock Percentage                 0.0           0.0           0       0.0 %

  Lock Detail                     per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------

  Table & Partition Lock Hashtable
    Lookups                           0.0           0.0           0       n/a
    Spinlock Contention               n/a           n/a         n/a       1.8 %

  Exclusive Table
    Granted                           0.1           0.0           6     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total EX-Table Requests             0.1           0.0           6       0.0 %

  Shared Table
    Total SH-Table Requests           0.0           0.0           0       n/a

  Exclusive Intent
    Granted                        7614.5           1.7      342652     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total EX-Intent Requests         7614.5           1.7      342652       5.4 %

  Shared Intent
    Granted                       48685.3          10.9     2190839     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total SH-Intent Requests        48685.3          10.9     2190839      34.3 %

  Exclusive Partition
    Total EX-Partition Reqs           0.0           0.0           0       n/a

  Shared Partition
    Total SH-Partition Reqs           0.0           0.0           0       n/a

  Exclusive Partition Intent
    Total EX-Ptn_Intent Reqs          0.0           0.0           0       n/a

  Shared Partition Intent
    Total SH-Ptn_Intent Reqs          0.0           0.0           0       n/a

  Exclusive Covering Partition Intent
    Total EX-CPtn_Intent Reqs         0.0           0.0           0       n/a

  Shared Covering Partition Intent
    Total SH-CPtn_Intent Reqs         0.0           0.0           0       n/a

  Page & Row Lock HashTable
    Lookups                      121705.6          27.1     5476753       n/a
    Avg Chain Length                  n/a           n/a     1.35933       n/a
    Spinlock Contention               n/a           n/a         n/a       1.9 %

  Exclusive Page
    Granted                           0.2           0.0           7     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total EX-Page Requests              0.2           0.0           7       0.0 %

  Update Page
    Total UP-Page Requests            0.0           0.0           0       n/a

  Shared Page
    Granted                           3.7           0.0         168     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total SH-Page Requests              3.7           0.0         168       0.0 %


  Exclusive Row
    Granted                       34723.8           7.7     1562570      98.3 %
    Waited                          584.5           0.1       26302       1.7 %
  -------------------------  ------------  ------------  ----------  ----------
  Total EX-Row Requests           35308.3           7.9     1588872      24.9 %

  Update Row
    Granted                           0.0           0.0           1     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total UP-Row Requests               0.0           0.0           1       0.0 %

  Shared Row
    Granted                       50265.5          11.2     2261947      99.8 %
    Waited                          104.5           0.0        4703       0.2 %
  -------------------------  ------------  ------------  ----------  ----------
  Total SH-Row Requests           50370.0          11.2     2266650      35.5 %


  Next-Key
    Total Next-Key Requests           0.0           0.0           0       n/a

  Address Lock Hashtable
    Lookups                          72.5           0.0        3263       n/a
    Avg Chain Length                  n/a           n/a     0.00153       n/a
    Spinlock Contention               n/a           n/a         n/a       0.1 %

  Exclusive Address
    Granted                          41.2           0.0        1852     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total EX-Address Requests          41.2           0.0        1852       0.0 %

  Shared Address
    Granted                          31.0           0.0        1394      99.5 %
    Waited                            0.2           0.0           7       0.5 %
  -------------------------  ------------  ------------  ----------  ----------
  Total SH-Address Requests          31.1           0.0        1401       0.0 %


  Last Page Locks on Heaps
    Granted                         166.6           0.0        7499     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total Last Pg Locks               166.6           0.0        7499     100.0 %


  Deadlocks by Lock Type          per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total Deadlocks                     0.0           0.0           0       n/a



  Deadlock Detection
    Deadlock Searches                 0.0           0.0           0       n/a


  Lock Promotions
    Total Lock Promotions             0.0           0.0           0       n/a


  Lock Timeouts by Lock Type      per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total Timeouts                      0.0           0.0           0       n/a

  Cluster Lock Summary            per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------

  Physical Locks Summary          per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
No physical locks are acquired


  Logical Locks Summary          per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------

  Object Locks Summary            per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------


===============================================================================

Data Cache Management
---------------------

  Cache Statistics Summary (All Caches)
  -------------------------------------
                                  per sec      per xact       count  % of total
                             ------------  ------------  ----------  ----------

    Cache Search Summary
      Total Cache Hits           434559.3          96.9    19555169      99.9 %
      Total Cache Misses            287.0           0.1       12914       0.1 %
  -------------------------  ------------  ------------  ----------
    Total Cache Searches         434846.3          97.0    19568083

    Cache Turnover
      Buffers Grabbed             20017.6           4.5      900793       n/a
      Buffers Grabbed Dirty           0.0           0.0           0       0.0 %

    Cache Strategy Summary
      Cached (LRU) Buffers       404738.5          90.3    18213233     100.0 %
      Discarded (MRU) Buffers         0.1           0.0           4       0.0 %

    Large I/O Usage
      Large I/Os Performed          360.5           0.1       16221      92.3 %

      Large I/Os Denied due to
        Pool < Prefetch Size          0.0           0.0           0       0.0 %
        Pages Requested
        Reside in Another
        Buffer Pool                  30.2           0.0        1358       7.7 %
  -------------------------  ------------  ------------  ----------
    Total Large I/O Requests        390.6           0.1       17579

    Large I/O Effectiveness
      Pages by Lrg I/O Cached      1441.9           0.3       64884       n/a
      Pages by Lrg I/O Used         680.0           0.2       30599      47.2 %

    Asynchronous Prefetch Activity
      APFs Issued                     0.0           0.0           0       0.0 %
      APFs Denied Due To
        APF I/O Overloads             0.0           0.0           0       0.0 %
        APF Limit Overloads           0.0           0.0           0       0.0 %
        APF Reused Overloads          0.0           0.0           0       0.0 %
      APF Buffers Found in Cache
        With Spinlock Held            0.0           0.0           0       0.0 %
        W/o Spinlock Held          1872.6           0.4       84269     100.0 %
  -------------------------  ------------  ------------  ----------
    Total APFs Requested           1872.6           0.4       84269

    Other Asynchronous Prefetch Statistics
      APFs Used                       0.0           0.0           0       n/a
      APF Waits for I/O               0.0           0.0           0       n/a
      APF Discards                    0.0           0.0           0       n/a

    Dirty Read Behavior
      Page Requests                   0.0           0.0           0       n/a

-------------------------------------------------------------------------------
  Cache: default data cache
                                  per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Spinlock Contention               n/a           n/a         n/a       2.6 %

    Utilization                       n/a           n/a         n/a     100.0 %

    Cache Searches
      Cache Hits                 434559.3          96.9    19555169      99.9 %
         Found in Wash              306.0           0.1       13772       0.1 %
      Cache Misses                  287.0           0.1       12914       0.1 %
  -------------------------  ------------  ------------  ----------
    Total Cache Searches         434846.3          97.0    19568083

    Pool Turnover
      16 Kb Pool
          LRU Buffer Grab         19657.2           4.4      884572      98.2 %
            Grabbed Locked Buffer     0.0           0.0           0       0.0 %
            Grabbed Dirty             0.0           0.0           0       0.0 %
      64 Kb Pool
          LRU Buffer Grab           360.5           0.1       16221       1.8 %
            Grabbed Locked Buffer     0.0           0.0           0       0.0 %
            Grabbed Dirty             0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------
    Total Cache Turnover          20017.6           4.5      900793

    Cluster Cache Behavior
      No physical locks are acquired on buffers in this cache

    Buffer Wash Behavior
      Statistics Not Available - No Buffers Entered Wash Section Yet

    Cache Strategy
      Cached (LRU) Buffers       404738.5          90.3    18213233     100.0 %
      Discarded (MRU) Buffers         0.1           0.0           4       0.0 %

    Large I/O Usage
      Large I/Os Performed          360.5           0.1       16221      92.3 %

      Large I/Os Denied due to
        Pool < Prefetch Size          0.0           0.0           0       0.0 %
        Pages Requested
        Reside in Another
        Buffer Pool                  30.2           0.0        1358       7.7 %
  -------------------------  ------------  ------------  ----------
    Total Large I/O Requests        390.6           0.1       17579

    Large I/O Detail
     64  Kb Pool
        Pages Cached               1441.9           0.3       64884       n/a
        Pages Used                  680.0           0.2       30599      47.2 %

    Dirty Read Behavior
          Page Requests               0.0           0.0           0       n/a

    Tuning Recommendations for Data cache : default data cache
    -------------------------------------
    - Consider using 'relaxed LRU replacement policy'
      for this cache.

===============================================================================

NV Cache Management
---------------------

  Cache Statistics Summary (All NV Caches)
  ----------------------------------------
                                  per sec      per xact       count  % of total
                             ------------  ------------  ----------  ----------

    Cache Search Summary
      Total Cache Hits                %
      Total Cache Misses              %
  -------------------------  ------------  ------------  ----------
    Total Cache Searches

    Cache Turnover
      Buffer Grabs                     n/a
      Failed Buffer Grabs             %

    Cache Device Reads
      Page Reads                      %
      Metadata Reads                  %
  -------------------------  ------------  ------------  ----------
    Total Reads

    Cache Device Writes
      Page Writes                     %
      Metadata Writes                 %
  -------------------------  ------------  ------------  ----------
    Total Writes
  -------------------------  ------------  ------------  ----------

    Page Writes Skipped

    Lazy Cleaning
      Cache Cleans
      Pages Cleaned

-------------------------------------------------------------------------------
  Cache: User Defined NV Cache
                                  per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Spinlock Contention               n/a           n/a         n/a       0.0 %

    Utilization                       n/a           n/a         n/a      %

    Cache Searches
      Cache Hits                      %
      Cache Misses                    %
  -------------------------  ------------  ------------  ----------
    Total Cache Searches

    Cache Turnover
      Buffer Grabs                     n/a
      Failed Buffer Grabs             %
      Buffer Grabs Retries            %
      Grab Effort                      n/a
      Pauses During Grab              %

    Cache Device Reads
      Page Reads                      %
      Metadata Reads                  %
  -------------------------  ------------  ------------  ----------
    Total Reads

    Cache Device Writes
      Page Writes                     %
        Dirty Page Writes             %
        Clean Page Writes             %
      Metadata Writes                 %
  -------------------------  ------------  ------------  ----------
    Total Writes
  -------------------------  ------------  ------------  ----------
    Dual Writes                       %

    Page Write Skipped NV Cache
      Clean page in NV cache          %
      Selectivity Failed              %
      Skip NV Caching                 %
      Failed Buffer Grabs             %
  -------------------------  ------------  ------------  ----------
    Total Page Write Skips


    Page Write Waits


    Lazy Cleaning
      Cache Cleans
      Pages Cleaned

===============================================================================

Procedure Cache Management        per sec      per xact       count  % of total
---------------------------  ------------  ------------  ----------  ----------
  Procedure Requests              46395.2          10.3     2087785       n/a
  Procedure Reads from Disk           0.0           0.0           1       0.0 %
  Procedure Writes to Disk            0.0           0.0           0       0.0 %
  Procedure Removals                  0.3           0.0          12       n/a
  Procedure Recompilations            0.0           0.0           1       n/a

  Recompilations Requests:
    Execution Phase                   0.0           0.0           1     100.0 %
    Compilation Phase                 0.0           0.0           0       0.0 %
    Execute Cursor Execution          0.0           0.0           0       0.0 %
    Redefinition Phase                0.0           0.0           0       0.0 %

  Recompilation Reasons:
    Table Missing                     0.0           0.0           0       n/a
    Temporary Table Missing           0.0           0.0           0       n/a
    Schema Change                     0.0           0.0           1       n/a
    Index Change                      0.0           0.0           0       n/a
    Isolation Level Change            0.0           0.0           0       n/a
    Permissions Change                0.0           0.0           0       n/a
    Cursor Permissions Change         0.0           0.0           0       n/a

  SQL Statement Cache:
    Statements Cached                 0.0           0.0           0       n/a
    Statements Found in Cache      2741.3           0.6      123360       n/a
    Statements Not Found              0.0           0.0           0       n/a
    Statements Dropped                0.0           0.0           0       n/a
    Statements Restored               0.2           0.0          10       n/a
    Statements Not Cached             0.0           0.0           0       n/a


===============================================================================

Memory Management                 per sec      per xact       count  % of total
---------------------------  ------------  ------------  ----------  ----------
  Pages Allocated                   385.3           0.1       17338       n/a
  Pages Released                    385.2           0.1       17336       n/a

===============================================================================

Recovery Management
-------------------

  Checkpoints                     per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    # of Normal Checkpoints           0.0           0.0           1     100.0 %
    # of Free Checkpoints             0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------
  Total Checkpoints                   0.0           0.0           1

  Avg Time per Normal Chkpt       0.00000 seconds

===============================================================================

Disk I/O Management
-------------------

  Max Outstanding I/Os            per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Server                            n/a           n/a           0       n/a
    Engine 0                          n/a           n/a           0       n/a
    Engine 1                          n/a           n/a           0       n/a
    Engine 2                          n/a           n/a           0       n/a
    Engine 3                          n/a           n/a           0       n/a
    Engine 4                          n/a           n/a           0       n/a
    Engine 5                          n/a           n/a           0       n/a
    Engine 6                          n/a           n/a           0       n/a
    Engine 7                          n/a           n/a           0       n/a


  I/Os Delayed by
    Disk I/O Structures               n/a           n/a           0       n/a
    Server Config Limit               n/a           n/a           0       n/a
    Engine Config Limit               n/a           n/a           0       n/a
    Operating System Limit            n/a           n/a           0       n/a


  Total Requested Disk I/Os        1391.9           0.3       62634

  Completed Disk I/O's
    Asynchronous I/O's
      Total Completed I/Os            0.0           0.0           0       n/a
    Synchronous I/O's
      Total Completed I/Os         1391.8           0.3       62632     100.0 %
  -------------------------  ------------  ------------  ----------
  Total Completed I/Os             1391.8           0.3       62632


  Device Activity Detail
  ----------------------

  Device:
    /opt/sap/data/ase/SPEC_DS_demodb_01_dev.dat
    demodb_01_dat                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                        14.1           0.0         634       3.3 %
    Writes                          418.0           0.1       18809      96.7 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                        432.1           0.1       19443      31.0 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_DS_demodb_01_dev.log
    demodb_01_log                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.0           0.0           0       0.0 %
    Writes                          216.3           0.0        9734     100.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                        216.3           0.0        9734      15.5 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_DS_demodb_02_dev.dat
    demodb_02_dat                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                        35.5           0.0        1599      38.5 %
    Writes                           56.7           0.0        2553      61.5 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                         92.3           0.0        4152       6.6 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_DS_demodb_02_dev.log
    demodb_02_log                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.0           0.0           0       0.0 %
    Writes                            1.9           0.0          85     100.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          1.9           0.0          85       0.1 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_DS_demodb_03_dev.dat
    demodb_03_dat                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                        34.8           0.0        1566      37.4 %
    Writes                           58.2           0.0        2619      62.6 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                         93.0           0.0        4185       6.7 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_DS_demodb_04_dev.dat
    demodb_04_dat                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                        33.6           0.0        1510      36.9 %
    Writes                           57.5           0.0        2587      63.1 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                         91.0           0.0        4097       6.5 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_DS_demodb_05_dev.dat
    demodb_05_dat                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                        35.6           0.0        1603      37.5 %
    Writes                           59.4           0.0        2671      62.5 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                         95.0           0.0        4274       6.8 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_DS_demodb_06_dev.dat
    demodb_06_dat                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                        36.1           0.0        1626      38.7 %
    Writes                           57.3           0.0        2578      61.3 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                         93.4           0.0        4204       6.7 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_DS_demodb_07_dev.dat
    demodb_07_dat                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                        34.7           0.0        1560      37.8 %
    Writes                           56.9           0.0        2562      62.2 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                         91.6           0.0        4122       6.6 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_DS_demodb_08_dev.dat
    demodb_08_dat                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                        34.0           0.0        1528      38.0 %
    Writes                           55.4           0.0        2491      62.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                         89.3           0.0        4019       6.4 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_master_data_01.dat
    master                        per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.0           0.0           0       0.0 %
    Writes                            0.2           0.0           7     100.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.2           0.0           7       0.0 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_sybsystemdb_data_01.dat
    systemdbdev                   per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.0           0.0           0       n/a
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.0           0.0           0       0.0 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_sybsystemprocs_data_01.dat
    sysprocsdev                   per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.0           0.0           0       n/a
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.0           0.0           0       0.0 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_tempdb_data_01.dat
    tempdbdev                     per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.0           0.0           0       n/a
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.0           0.0           0       0.0 %


  -----------------------------------------------------------------------------

  Device:
    /opt_sap_data_ase/SPEC_DS_demodb_09_dev.dat
    demodb_09_dat                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                        28.2           0.0        1267      43.0 %
    Writes                           37.4           0.0        1682      57.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                         65.5           0.0        2949       4.7 %


  -----------------------------------------------------------------------------

  Device:
    /opt_sap_data_ase/SPEC_DS_demodb_10_dev.dat
    demodb_10_dat                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.2           0.0          11       0.8 %
    Writes                           30.0           0.0        1352      99.2 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                         30.3           0.0        1363       2.2 %


  -----------------------------------------------------------------------------

  Device:
    /opt_sap_data_ase/SPEC_DS_demodb_11_dev.dat
    demodb_11_dat                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.0           0.0           0       n/a
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.0           0.0           0       0.0 %


  -----------------------------------------------------------------------------

  Device:
    /opt_sap_data_ase/SPEC_DS_demodb_12_dev.dat
    demodb_12_dat                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.0           0.0           0       n/a
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.0           0.0           0       0.0 %


  -----------------------------------------------------------------------------



===============================================================================

Network I/O Management
----------------------

  Network I/O Requests            per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total Network I/O Requests      57565.4          12.8     2590445       n/a
  Network I/Os Delayed                0.0           0.0           0       0.0 %


  Network Receive Activity        per sec      per xact       count
  -------------------------  ------------  ------------  ----------
  Total TDS Packets Rec'd         57398.9          12.8     2582949
  Total Bytes Rec'd             3390911.3         756.3   152591007
  Avg Bytes Rec'd per Packet          n/a           n/a          59

  Network Send Activity           per sec      per xact       count
  -------------------------  ------------  ------------  ----------
  Total TDS Packets Sent          57527.8          12.8     2588753
  Total Bytes Sent              4870451.1        1086.3   219170301
  Avg Bytes Sent per Packet           n/a           n/a          84

=============================== End of Report =================================




### imRS


sp_configure 'enable mem scale', 1
go
sp_configure 'enable in-memory row storage', 1
go

# opcjonalnie

sp_configure 'number of pack tasks per db', <value> -- def 2
go
sp_configure 'number of imrs gc tasks per db', <value> -- def 2
go
sp_configure 'Number of lob gc tasks per db', <value>
go

#
--sp_dropdevice SPECTRUM_imrslog_01, dropfile
go

disk init name = 'demodb_imrslog_01',
physname = '/opt/sap/data/ase/SPEC_DS_demodb_imrslog_01.dat',
size = '1G',
type = imrslog
go

sp_helpdevice demodb_imrslog_01
go

use master
go
alter database demodb imrslog on demodb_imrslog_01 = '1G'
go

sp_cacheconfig "demodb_row_cache", "1G", row_storage  -- 256MB to minimum
go
alter database demodb row storage on demodb_row_cache
go

alter database demodb set row_caching on for all tables
go

##### -> brak przyspieszenia bo jest blokowowanie logiczne

alter database demodb set snapshot_isolation  on  for all tables
go

##### -> brak przyspieszenia bo jest blokowowanie logiczne

sp_imrs 'show', 'rowcounts'
2> go
 CacheName                        DBName       NRows      NRowsHWM         NVersions          NVersHWM         NInsRows         NMigRows         NCachedRows            NInsVers         NMigVers         NRowsPendGC
 -------------------------------- ------------ ---------- ---------------- ------------------ ---------------- ---------------- ---------------- ---------------------- ---------------- ---------------- ----------------------
 demodb_row_cache                 demodb       28868         28911                 0                48            13576             7533                7759                   0                0                   0


sp_imrs show, rowcounts, demodb_row_cache
go

sp_imrs show, rowcounts, demodb_row_cache
go
2> 3>  DBName       OwnerName          ObjectName           NRows      NRowsHWM         NVersions          NVersHWM         NInsRows         NMigRows         NCachedRows            NInsVers         NMigVers         NRowsPendGC
 ------------ ------------------ -------------------- ---------- ---------------- ------------------ ---------------- ---------------- ---------------- ---------------------- ---------------- ---------------- ----------------------
 demodb       [Any]              [Totals]             28868         28911                 0                48            13576             -226                7759                   0                0                   0
 demodb       dbo                customer             14871         14871                 0                15                0             7522                7349                   0                0                   0
 demodb       dbo                history              13576         13576                 0                 0            13576                0                   0                   0                0                   0
 demodb       dbo                order_line             355           355                 0                 0                0                0                 355                   0                0                   0
 demodb       dbo                orders                  55            76                 0                 0                0                0                  55                   0                0                   0
 demodb       dbo                district                10            10                 0                33                0               10                   0                   0                0                   0
 demodb       dbo                warehouse                1             1                 0                 0                0                1                   0                   0                0                   0
 demodb       dbo                item                     0             0                 0                 0                0                0                   0                   0                0                   0
 demodb       dbo                stock                    0             0                 0                 0                0                0                   0                   0                0                   0
 demodb       dbo                new_orders               0            22                 0                 0                0                0                   0                   0                0                   0





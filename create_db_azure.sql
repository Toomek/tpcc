select @@maxpagesize
go
-- 16384

use master
go
disk init name = 'demodb_01_dat', physname = '/opt/sap/data/ase/SPEC_DS_demodb_01_dev.dat', size = '1024M'
go
disk init name = 'demodb_01_log', physname = '/opt/sap/data/ase/SPEC_DS_demodb_01_dev.log', size = '512M'
go

-- drop
use master
go
drop database demodb
go

-- create
create database demodb
on demodb_01_dat = '1024M'
log on demodb_01_log = '512M'
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
sp_cacheconfig 'default data cache', '4G'
go
sp_cacheconfig "default data cache", "cache_partition=4"
go
sp_poolconfig 'default data cache', "1G", "64K"
go

-- configure 4 threads for SAP ASE
sp_configure 'max online engines', 16
go
alter thread pool syb_default_pool with thread count = 4
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
sp_configure "number of network tasks", 4
go
sp_configure 'user log cache size' --> jest domyslnie na 8k (mimo ze pagesize 2k)
go
sp_configure 'session tempdb log cache size', 65536
go
sp_configure 'heap memory per user', 16384
go

!!! disable firewall
systemctl stop firewalld
systemctl disable firewalld

#######################################
############# TESTY AZURE ############# 
#######################################


#####Size Standard D4s v3 = vCPUs 4 RAM 16 GiB max IOPS 6400, premium SSD
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


#####Size Standard D8ds v4 vCPUs 8 RAM 32 GiB  max IOPS 12800, premium SSD
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
-> 5 run: 12706.036 TpmC              --> sysmon Committed Xacts=1241.1
# 128 connections
-> 7 run: 12291.542 TpmC
-> 8 run: 12469.468 TpmC

# 256 connections
12728.241 TpmC



1> sp_sysmon "00:00:45"
2> go

===============================================================================
      Sybase Adaptive Server Enterprise System Performance Report
===============================================================================

Server Version:        Adaptive Server Enterprise/16.0 SP04 PL03/EBF 30399 SMP/
                       P/x86_64/SLES 12.4/ase160sp04pl03x/3587/64-bit/FBO/Wed A
                       ug 24 01:39:32 2022
Run Date:              Jun 25, 2024
Sampling Started at:   Jun 25, 2024 11:12:31
Sampling Ended at:     Jun 25, 2024 11:13:16
Sample Interval:       00:00:45
Sample Mode:           No Clear
Counters Last Cleared: Jun 25, 2024 10:47:22
Server Name:           SPEC
===============================================================================

Kernel Utilization
------------------


  Engine Utilization (Tick %)   User Busy   System Busy    I/O Busy        Idle
  -------------------------  ------------  ------------  ----------  ----------
  ThreadPool : syb_default_pool
   Engine 0                        25.9 %         1.1 %       0.0 %      73.0 %
   Engine 1                        26.3 %         1.3 %       0.0 %      72.3 %
   Engine 2                        27.9 %         0.2 %       0.0 %      71.9 %
   Engine 3                        27.7 %         2.0 %       0.0 %      70.4 %
   Engine 4                        25.4 %         1.5 %       0.0 %      73.0 %
   Engine 5                        26.3 %         2.4 %       0.0 %      71.2 %
   Engine 6                        25.4 %         0.4 %       0.0 %      74.1 %
   Engine 7                        24.6 %         0.9 %       0.0 %      74.6 %
  -------------------------  ------------  ------------  ----------  ----------
  Pool Summary        Total       209.5 %        10.0 %       0.0 %     580.5 %
                    Average        26.2 %         1.2 %       0.0 %      72.6 %

  -------------------------  ------------  ------------  ----------  ----------
  Server Summary      Total       209.5 %        10.0 %       0.0 %     580.5 %
                    Average        26.2 %         1.2 %       0.0 %      72.6 %


  Average Runnable Tasks            1 min         5 min      15 min  % of total
  -------------------------  ------------  ------------  ----------  ----------
  ThreadPool : syb_default_pool
   Global Queue                       0.0           0.0         0.0       0.0 %
   Engine 0                           0.3           0.3         0.3      14.9 %
   Engine 1                           0.3           0.3         0.2      14.6 %
   Engine 2                           0.1           0.2         0.2       5.9 %
   Engine 3                           0.4           0.4         0.3      17.7 %
   Engine 4                           0.3           0.2         0.1      15.1 %
   Engine 5                           0.2           0.2         0.1       9.4 %
   Engine 6                           0.1           0.2         0.1       3.6 %
   Engine 7                           0.4           0.3         0.2      18.8 %
  -------------------------  ------------  ------------  ----------
  Pool Summary        Total           2.3           2.0         1.6
                    Average           0.3           0.2         0.2

  -------------------------  ------------  ------------  ----------
  Server Summary      Total           2.3           2.0         1.6
                    Average           0.3           0.2         0.2


  CPU Yields by Engine            per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  ThreadPool : syb_default_pool
   Engine 0
      Full Sleeps                    65.5           0.1        2946       1.1 %
      Interrupted Sleeps            657.3           0.5       29579      11.1 %
   Engine 1
      Full Sleeps                    62.9           0.1        2831       1.1 %
      Interrupted Sleeps            682.3           0.5       30705      11.5 %
   Engine 2
      Full Sleeps                    63.8           0.1        2869       1.1 %
      Interrupted Sleeps            676.0           0.5       30421      11.4 %
   Engine 3
      Full Sleeps                    64.8           0.1        2914       1.1 %
      Interrupted Sleeps            661.3           0.5       29757      11.2 %
   Engine 4
      Full Sleeps                    60.4           0.0        2719       1.0 %
      Interrupted Sleeps            714.2           0.6       32140      12.1 %
   Engine 5
      Full Sleeps                    61.3           0.0        2758       1.0 %
      Interrupted Sleeps            685.0           0.6       30826      11.6 %
   Engine 6
      Full Sleeps                    64.8           0.1        2916       1.1 %
      Interrupted Sleeps            646.3           0.5       29083      10.9 %
   Engine 7
      Full Sleeps                    64.0           0.1        2880       1.1 %
      Interrupted Sleeps            681.4           0.5       30664      11.5 %
  -------------------------  ------------  ------------  ----------
  Pool Summary                     5911.3           4.8      266008

  -------------------------  ------------  ------------  ----------
  Total CPU Yields                 5911.3           4.8      266008


  Thread Utilization (OS %)     User Busy   System Busy        Idle
  -------------------------  ------------  ------------  ----------
  ThreadPool : syb_blocking_pool : no activity during sample

  ThreadPool : syb_default_pool
   Thread 2    (Engine 0)          21.1 %         3.0 %      75.9 %
   Thread 3    (Engine 1)          22.0 %         3.3 %      74.7 %
   Thread 4    (Engine 2)          22.1 %         3.0 %      74.9 %
   Thread 5    (Engine 3)          21.3 %         3.1 %      75.6 %
   Thread 14   (Engine 4)          23.2 %         3.1 %      73.7 %
   Thread 15   (Engine 5)          22.0 %         3.2 %      74.8 %
   Thread 16   (Engine 6)          20.8 %         3.0 %      76.2 %
   Thread 17   (Engine 7)          22.0 %         3.2 %      74.7 %
  -------------------------  ------------  ------------  ----------
  Pool Summary      Total         174.6 %        24.8 %     600.5 %
                  Average          21.8 %         3.1 %      75.1 %

  ThreadPool : syb_system_pool
   Thread 1    (Signal Handler)     0.0 %         0.0 %     100.0 %
   Thread 10   (NetController)      2.3 %         4.2 %      93.4 %
   Thread 11   (NetController)      2.4 %         4.3 %      93.3 %
   Thread 12   (NetController)      2.3 %         4.3 %      93.4 %
   Thread 13   (NetController)      2.6 %         4.3 %      93.1 %
  -------------------------  ------------  ------------  ----------
  Pool Summary      Total           9.7 %        17.1 %     473.2 %
                  Average           1.9 %         3.4 %      94.6 %

  -------------------------  ------------  ------------  ----------
  Server Summary    Total         184.3 %        41.9 %    1473.8 %
                  Average          10.8 %         2.5 %      86.7 %

  Adaptive Server threads are consuming 2.3 CPU units.
  Throughput (committed xacts per CPU unit) : 548.6


  Page Faults at OS               per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
   Minor Faults                       1.6           0.0          73     100.0 %
   Major Faults                       0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
   Total Page Faults                  1.6           0.0          73     100.0 %


  Context Switches at OS          per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  ThreadPool : syb_blocking_pool
   Voluntary                          0.0           0.0           0       0.0 %
   Non-Voluntary                      0.0           0.0           0       0.0 %
  ThreadPool : syb_default_pool
   Voluntary                       6402.5           5.2      288111      33.1 %
   Non-Voluntary                      0.5           0.0          23       0.0 %
  ThreadPool : syb_system_pool
   Voluntary                      12958.5          10.4      583133      66.9 %
   Non-Voluntary                      0.3           0.0          13       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
   Total Context Switches         19361.8          15.6      871280     100.0 %


  CtlibController Activity        per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
   Polls                             0.0           0.0           0       0.0 %

  DiskController Activity         per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
   Polls                             0.0           0.0           0       0.0 %

  NetController Activity          per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
   Polls                          64245.5          51.8     2891047       n/a
   Polls Returning Events         13644.5          11.0      614002      21.2 %
   Polls Returning Max Events         0.0           0.0           0       0.0 %
   Total Events                   15873.0          12.8      714283       n/a
   Events Per Poll                    n/a           n/a       0.247       n/a


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
    Engine 0                       2335.6           1.9      105103      12.0 %
    Engine 1                       2456.6           2.0      110549      12.6 %
    Engine 2                       2447.2           2.0      110125      12.6 %
    Engine 3                       2374.4           1.9      106847      12.2 %
    Engine 4                       2581.9           2.1      116186      13.3 %
    Engine 5                       2465.9           2.0      110967      12.7 %
    Engine 6                       2337.2           1.9      105172      12.0 %
    Engine 7                       2468.8           2.0      111097      12.7 %
  -------------------------  ------------  ------------  ----------
  Pool Summary        Total       19467.7          15.7      876046
                    Average        2433.4           2.0      109505

  -------------------------  ------------  ------------  ----------
    Total Task Switches:          19467.7          15.7      876046

  Task Context Switches Due To:
    Voluntary Yields                413.2           0.3       18593       2.1 %
    Cache Search Misses               0.3           0.0          15       0.0 %
    Exceeding I/O batch size          0.5           0.0          24       0.0 %
    System Disk Writes               30.2           0.0        1357       0.2 %
    Logical Lock Contention         356.5           0.3       16044       1.8 %
    Address Lock Contention           0.1           0.0           6       0.0 %
    Latch Contention                 20.7           0.0         932       0.1 %
    Physical Lock Transition          0.0           0.0           0       0.0 %
    Logical Lock Transition           0.0           0.0           0       0.0 %
    Object Lock Transition            0.0           0.0           0       0.0 %
    Log Semaphore Contention        372.5           0.3       16763       1.9 %
    IMRSLog Semaphore Contention      0.0           0.0           0       0.0 %
    PLCBLOCK flush                  615.7           0.5       27708       3.2 %
    PLC Lock Contention              34.8           0.0        1565       0.2 %
    Group Commit Sleeps             842.0           0.7       37891       4.3 %
    Last Log Page Writes            384.7           0.3       17310       2.0 %
    Modify Conflicts                483.3           0.4       21747       2.5 %
    I/O Device Contention             0.0           0.0           0       0.0 %
    Network Packet Received       15903.8          12.8      715671      81.7 %
    Network Packet Sent               8.1           0.0         366       0.0 %
    Interconnect Message Sleeps       0.0           0.0           0       0.0 %
    Network services                  0.0           0.0           0       0.0 %
    Other Causes                      1.2           0.0          54       0.0 %

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
    To High Priority                755.8           0.6       34010      50.0 %
    To Medium Priority              755.7           0.6       34006      50.0 %
    To Low Priority                   0.4           0.0          16       0.0 %
  -------------------------  ------------  ------------  ----------
  Total Priority Changes           1511.8           1.2       68032

  Allotted Slices Exhausted       per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    High Priority                     0.0           0.0           2       0.2 %
    Medium Priority                  21.3           0.0         957      99.8 %
    Low Priority                      0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------
  Total Slices Exhausted             21.3           0.0         959

  Skipped Tasks By Engine         per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Engine 0                          3.1           0.0         139      14.7 %
    Engine 1                          2.9           0.0         131      13.8 %
    Engine 2                          2.0           0.0          89       9.4 %
    Engine 3                          2.8           0.0         126      13.3 %
    Engine 4                          2.6           0.0         117      12.4 %
    Engine 5                          1.9           0.0          87       9.2 %
    Engine 6                          2.7           0.0         122      12.9 %
    Engine 7                          3.0           0.0         135      14.3 %
  -------------------------  ------------  ------------  ----------
  Total Engine Skips                 21.0           0.0         946

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
  Clean                             56.0           0.0        2522     100.0 %
  Dirty                              0.0           0.0           1       0.0 %
                             ------------  ------------  ----------
Total Washes                        56.1           0.0        2523

Garbage Collections                 13.5           0.0         606       n/a
Pages Processed in GC               22.4           0.0        1008       n/a

Statistics Updates                   0.2           0.0           8       n/a

  Tuning Recommendations for Housekeeper
  --------------------------------------
  - Consider increasing the 'housekeeper free write percent'
    configuration parameter.

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
    Committed Xacts                1241.1           n/a       55848     n/a

  Transaction Detail              per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Inserts
    Fully Logged
      APL Heap Table                  0.0           0.0           0       0.0 %
      APL Clustered Table             0.0           0.0           0       0.0 %
      Data Only Lock Table         3410.0           2.7      153451     100.0 %
      Fast Bulk Insert                0.0           0.0           0       0.0 %
      Fast Log Bulk Insert            0.0           0.0           0       0.0 %
    Minimally Logged
      APL Heap Table                  0.0           0.0           0       0.0 %
      APL Clustered Table             0.0           0.0           0       0.0 %
      Data Only Lock Table            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total Rows Inserted              3410.0           2.7      153451      37.9 %

  Updates
    Fully Logged
      APL Deferred                    0.0           0.0           0       0.0 %
      APL Direct In-place             0.0           0.0           0       0.0 %
      APL Direct Cheap                0.0           0.0           0       0.0 %
      APL Direct Expensive            0.0           0.0           0       0.0 %
      DOL Deferred                    0.0           0.0           0       0.0 %
      DOL Direct                   5372.7           4.3      241772     100.0 %
    Minimally Logged
      APL Direct In-place             0.0           0.0           0       0.0 %
      APL Direct Cheap                0.0           0.0           0       0.0 %
      APL Direct Expensive            0.0           0.0           0       0.0 %
      DOL Direct                      0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total Rows Updated               5372.7           4.3      241772      59.7 %

  Data Only Locked Updates
    Fully Logged
      DOL Replace                  3069.6           2.5      138133      69.9 %
      DOL Shrink                      0.0           0.0           0       0.0 %
      DOL Cheap Expand             1256.8           1.0       56554      28.6 %
      DOL Expensive Expand          512.8           0.4       23075      11.7 %
      DOL Expand & Forward          533.6           0.4       24010      12.2 %
      DOL Fwd Row Returned            0.0           0.0           0       0.0 %
    Minimally Logged
      DOL Replace                     0.0           0.0           0       0.0 %
      DOL Shrink                      0.0           0.0           0       0.0 %
      DOL Cheap Expand                0.0           0.0           0       0.0 %
      DOL Expensive Expand            0.0           0.0           0       0.0 %
      DOL Expand & Forward            0.0           0.0           0       0.0 %
      DOL Fwd Row Returned            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total DOL Rows Updated           4388.8           3.5      197496      48.8 %

  Deletes
    Fully Logged
      APL Deferred                    0.0           0.0           0       0.0 %
      APL Direct                      0.0           0.0           0       0.0 %
      DOL                           211.5           0.2        9519     100.0 %
    Minimally Logged
      APL Direct                      0.0           0.0           0       0.0 %
      DOL                             0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total Rows Deleted                211.5           0.2        9519       2.4 %

  Selects
    Total Rows Selected            6175.1           5.0      277878     100.0 %

  =========================  ============  ============  ==========
  Total Rows Affected              8994.3           7.2      404742
  =========================  ============  ============  ==========

===============================================================================

Transaction Management
----------------------

  ULC Flushes to Xact Log         per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Any Logging Mode DMLs
    by End Transaction             1208.3           1.0       54375      96.5 %
    by Change of Database             0.2           0.0           7       0.0 %
    by Unpin                          0.1           0.0           6       0.0 %
    by Log markers                    1.8           0.0          79       0.1 %
    by No Free Plcblock              33.9           0.0        1526       2.7 %

  Fully Logged DMLs
    by Full ULC                       1.0           0.0          45       0.1 %
    by Single Log Record              6.6           0.0         298       0.5 %

  Minimally Logged DMLs
    by Full ULC                       0.0           0.0           0       0.0 %
    by Single Log Record              0.0           0.0           0       0.0 %
    by Start of Sub-Command           0.0           0.0           0       0.0 %
    by End of Sub-Command             0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------
  Total ULC Flushes                1251.9           1.0       56336

  ULC Flushes Skipped             per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Fully Logged DMLs
    by ULC Discards                  44.2           0.0        1988     100.0 %
  Minimally Logged DMLs
    by ULC Discards                   0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------
  Total ULC Flushes Skips            44.2           0.0        1988

  ULC Log Records                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Fully Logged DMLs               17417.7          14.0      783795       100.0
  Minimally Logged DMLs               0.0           0.0           0         0.0
  -------------------------  ------------  ------------  ----------
  Total ULC Log Records           17417.7          14.0      783795

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
    Granted                       36972.8          29.8     1663775      99.9 %
    Waited                           34.8           0.0        1565       0.1 %
  -------------------------  ------------  ------------  ----------
  Total ULC Semaphore Req         37007.6          29.8     1665340

  Log Semaphore Requests
    Granted                         262.3           0.2       11805      41.3 %
    Local Waited                    372.5           0.3       16763      58.7 %
    Global Waited                     0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------
  Total Log Semaphore Req           634.8           0.5       28568

  Transaction Log Writes            415.8           0.3       18709       n/a
  Transaction Log Alloc             112.2           0.1        5048       n/a
  Avg # Writes per Log Page           n/a           n/a     3.70622       n/a

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

    Upd/Del DOL Req Maint          5584.2           4.5      251291       n/a
      # of DOL Ndx Maint            211.8           0.2        9531       n/a
      Avg DOL Ndx Maint / Op          n/a           n/a     0.03793       n/a

  Page Splits                         5.8           0.0         263       n/a
    Retries                           0.0           0.0           0       0.0 %
    Deadlocks                         0.0           0.0           0       0.0 %
    Add Index Level                   0.0           0.0           0       0.0 %

  Page Shrinks                        0.0           0.0           0       n/a

  Index Scans                     per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Ascending Scans                   1.3           0.0          60       0.0 %
    DOL Ascending Scans           28383.4          22.9     1277252      99.9 %
    Descending Scans                  3.7           0.0         167       0.0 %
    DOL Descending Scans             21.1           0.0         948       0.1 %
                             ------------  ------------  ----------
    Total Scans                   28409.5          22.9     1278427

===============================================================================

Metadata Cache Management
-------------------------

  Metadata Cache Summary         per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------

  Open Object Usage
    Active                            n/a           n/a         203       n/a
    Max Ever Used Since Boot          n/a           n/a         636       n/a
    Free                              n/a           n/a        1797       n/a
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
    Active                            n/a           n/a          10       n/a
    Max Ever Used Since Boot          n/a           n/a          10       n/a
    Free                              n/a           n/a           2       n/a
    Reuse Requests
      Succeeded                       n/a           n/a           0       n/a
      Failed                          n/a           n/a           0       n/a

  Descriptors immediately discarded   n/a           n/a           0       n/a
  Object Manager Spinlock Contention  n/a           n/a         n/a       0.4 %

  Object Spinlock Contention          n/a           n/a         n/a       0.2 %

  Index Spinlock Contention           n/a           n/a         n/a       0.0 %

  Index Hash Spinlock Contention      n/a           n/a         n/a       0.0 %

  Partition Spinlock Contention       n/a           n/a         n/a       0.0 %

  Partition Hash Spinlock Contention  n/a           n/a         n/a       0.0 %

===============================================================================

Lock Management
---------------

  Lock Summary                    per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
  Total Lock Requests             39543.8          31.9     1779469       n/a
  Avg Lock Contention               356.7           0.3       16050       0.9 %
  Cluster Locks Retained              0.0           0.0           0       0.0 %
  Deadlock Percentage                 0.0           0.0           0       0.0 %

  Lock Detail                     per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------

  Table & Partition Lock Hashtable
    Lookups                           0.0           0.0           0       n/a
    Spinlock Contention               n/a           n/a         n/a       1.0 %

  Exclusive Table
    Granted                           0.3           0.0          13     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total EX-Table Requests             0.3           0.0          13       0.0 %

  Shared Table
    Total SH-Table Requests           0.0           0.0           0       n/a

  Exclusive Intent
    Granted                        2117.6           1.7       95291     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total EX-Intent Requests         2117.6           1.7       95291       5.4 %

  Shared Intent
    Granted                       13673.0          11.0      615284     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total SH-Intent Requests        13673.0          11.0      615284      34.6 %

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
    Lookups                       34575.7          27.9     1555908       n/a
    Avg Chain Length                  n/a           n/a     0.07345       n/a
    Spinlock Contention               n/a           n/a         n/a       1.0 %

  Exclusive Page
    Granted                           1.2           0.0          55     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total EX-Page Requests              1.2           0.0          55       0.0 %

  Update Page
    Total UP-Page Requests            0.0           0.0           0       n/a

  Shared Page
    Granted                           2.2           0.0          98     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total SH-Page Requests              2.2           0.0          98       0.0 %


  Exclusive Row
    Granted                        9474.3           7.6      426344      96.7 %
    Waited                          319.9           0.3       14395       3.3 %
  -------------------------  ------------  ------------  ----------  ----------
  Total EX-Row Requests            9794.2           7.9      440739      24.8 %

  Update Row
    Granted                           1.8           0.0          80     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total UP-Row Requests               1.8           0.0          80       0.0 %

  Shared Row
    Granted                       13900.8          11.2      625536      99.7 %
    Waited                           36.6           0.0        1649       0.3 %
  -------------------------  ------------  ------------  ----------  ----------
  Total SH-Row Requests           13937.4          11.2      627185      35.2 %


  Next-Key
    Total Next-Key Requests           0.0           0.0           0       n/a

  Address Lock Hashtable
    Lookups                          16.2           0.0         731       n/a
    Avg Chain Length                  n/a           n/a     0.00000       n/a
    Spinlock Contention               n/a           n/a         n/a       0.0 %

  Exclusive Address
    Granted                          12.3           0.0         552     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total EX-Address Requests          12.3           0.0         552       0.0 %

  Shared Address
    Granted                           3.7           0.0         166      96.5 %
    Waited                            0.1           0.0           6       3.5 %
  -------------------------  ------------  ------------  ----------  ----------
  Total SH-Address Requests           3.8           0.0         172       0.0 %


  Last Page Locks on Heaps
    Granted                         163.8           0.1        7373     100.0 %
    Waited                            0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total Last Pg Locks               163.8           0.1        7373     100.0 %


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
      Total Cache Hits           106020.5          85.4     4770921     100.0 %
      Total Cache Misses              0.3           0.0          15       0.0 %
  -------------------------  ------------  ------------  ----------
    Total Cache Searches         106020.8          85.4     4770936

    Cache Turnover
      Buffers Grabbed              5483.8           4.4      246771       n/a
      Buffers Grabbed Dirty           0.0           0.0           0       0.0 %

    Cache Strategy Summary
      Cached (LRU) Buffers       102077.8          82.3     4593502     100.0 %
      Discarded (MRU) Buffers         0.1           0.0           4       0.0 %

    Large I/O Usage
      Large I/Os Performed           27.7           0.0        1246      95.4 %

      Large I/Os Denied due to
        Pool < Prefetch Size          0.0           0.0           0       0.0 %
        Pages Requested
        Reside in Another
        Buffer Pool                   1.3           0.0          60       4.6 %
  -------------------------  ------------  ------------  ----------
    Total Large I/O Requests         29.0           0.0        1306

    Large I/O Effectiveness
      Pages by Lrg I/O Cached       110.8           0.1        4984       n/a
      Pages by Lrg I/O Used         110.8           0.1        4984     100.0 %

    Asynchronous Prefetch Activity
      APFs Issued                     0.4           0.0          16       0.1 %
      APFs Denied Due To
        APF I/O Overloads             0.0           0.0           0       0.0 %
        APF Limit Overloads           0.0           0.0           0       0.0 %
        APF Reused Overloads          0.0           0.0           0       0.0 %
      APF Buffers Found in Cache
        With Spinlock Held            0.1           0.0           3       0.0 %
        W/o Spinlock Held           606.1           0.5       27274      99.9 %
  -------------------------  ------------  ------------  ----------
    Total APFs Requested            606.5           0.5       27293

    Other Asynchronous Prefetch Statistics
      APFs Used                       0.4           0.0          16       n/a
      APF Waits for I/O               0.1           0.0           4       n/a
      APF Discards                    0.0           0.0           0       n/a

    Dirty Read Behavior
      Page Requests                   0.0           0.0           0       n/a

-------------------------------------------------------------------------------
  Cache: default data cache
                                  per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Spinlock Contention               n/a           n/a         n/a       1.5 %

    Utilization                       n/a           n/a         n/a     100.0 %

    Cache Searches
      Cache Hits                 106020.5          85.4     4770921     100.0 %
         Found in Wash               49.0           0.0        2207       0.0 %
      Cache Misses                    0.3           0.0          15       0.0 %
  -------------------------  ------------  ------------  ----------
    Total Cache Searches         106020.8          85.4     4770936

    Pool Turnover
      16 Kb Pool
          LRU Buffer Grab          5456.1           4.4      245525      99.5 %
            Grabbed Locked Buffer     0.0           0.0           0       0.0 %
            Grabbed Dirty             0.0           0.0           0       0.0 %
      64 Kb Pool
          LRU Buffer Grab            27.7           0.0        1246       0.5 %
            Grabbed Locked Buffer     0.0           0.0           0       0.0 %
            Grabbed Dirty             0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------
    Total Cache Turnover           5483.8           4.4      246771

    Cluster Cache Behavior
      No physical locks are acquired on buffers in this cache

    Buffer Wash Behavior
      Statistics Not Available - No Buffers Entered Wash Section Yet

    Cache Strategy
      Cached (LRU) Buffers       102077.8          82.3     4593502     100.0 %
      Discarded (MRU) Buffers         0.1           0.0           4       0.0 %

    Large I/O Usage
      Large I/Os Performed           27.7           0.0        1246      95.4 %

      Large I/Os Denied due to
        Pool < Prefetch Size          0.0           0.0           0       0.0 %
        Pages Requested
        Reside in Another
        Buffer Pool                   1.3           0.0          60       4.6 %
  -------------------------  ------------  ------------  ----------
    Total Large I/O Requests         29.0           0.0        1306

    Large I/O Detail
     64  Kb Pool
        Pages Cached                110.8           0.1        4984       n/a
        Pages Used                  110.8           0.1        4984     100.0 %

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
  Procedure Requests              12818.9          10.3      576851       n/a
  Procedure Reads from Disk           0.0           0.0           2       0.0 %
  Procedure Writes to Disk            0.0           0.0           0       0.0 %
  Procedure Removals                  0.2           0.0           8       n/a
  Procedure Recompilations            0.1           0.0           4       n/a

  Recompilations Requests:
    Execution Phase                   0.1           0.0           3      75.0 %
    Compilation Phase                 0.0           0.0           1      25.0 %
    Execute Cursor Execution          0.0           0.0           0       0.0 %
    Redefinition Phase                0.0           0.0           0       0.0 %

  Recompilation Reasons:
    Table Missing                     0.1           0.0           4       n/a
    Temporary Table Missing           0.0           0.0           1       n/a
    Schema Change                     0.0           0.0           0       n/a
    Index Change                      0.0           0.0           0       n/a
    Isolation Level Change            0.0           0.0           0       n/a
    Permissions Change                0.0           0.0           0       n/a
    Cursor Permissions Change         0.0           0.0           0       n/a

  SQL Statement Cache:
    Statements Cached                 0.0           0.0           0       n/a
    Statements Found in Cache       758.3           0.6       34124       n/a
    Statements Not Found              0.0           0.0           0       n/a
    Statements Dropped                0.0           0.0           0       n/a
    Statements Restored               0.1           0.0           3       n/a
    Statements Not Cached             0.0           0.0           0       n/a


===============================================================================

Memory Management                 per sec      per xact       count  % of total
---------------------------  ------------  ------------  ----------  ----------
  Pages Allocated                   107.6           0.1        4842       n/a
  Pages Released                    107.7           0.1        4848       n/a

===============================================================================

Recovery Management
-------------------

  Checkpoints                     per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    # of Normal Checkpoints           0.2           0.0           8     100.0 %
    # of Free Checkpoints             0.0           0.0           0       0.0 %
  -------------------------  ------------  ------------  ----------
  Total Checkpoints                   0.2           0.0           8

  Avg Time per Normal Chkpt       0.87500 seconds

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


  Total Requested Disk I/Os         457.9           0.4       20607

  Completed Disk I/O's
    Asynchronous I/O's
      Total Completed I/Os            0.0           0.0           0       n/a
    Synchronous I/O's
      Total Completed I/Os          458.0           0.4       20608     100.0 %
  -------------------------  ------------  ------------  ----------
  Total Completed I/Os              458.0           0.4       20608


  Device Activity Detail
  ----------------------

  Device:
    /opt/sap/data/ase/SPEC_DS_demodb_01_dev.dat
    demodb_01_dat                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.1           0.0           3       0.2 %
    Writes                           37.1           0.0        1669      99.8 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                         37.2           0.0        1672       8.1 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_DS_demodb_01_dev.log
    demodb_01_log                 per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.0           0.0           0       0.0 %
    Writes                          416.1           0.3       18723     100.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                        416.1           0.3       18723      90.9 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_SPECTRUM__log_01.dat
    SPECTRUM__log_01              per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.0           0.0           0       0.0 %
    Writes                            0.1           0.0           3     100.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.1           0.0           3       0.0 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_SPECTRUM_data_01.dat
    SPECTRUM_data_01              per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.0           0.0           0       0.0 %
    Writes                            0.1           0.0           3     100.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.1           0.0           3       0.0 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_master_data_01.dat
    master                        per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.0           0.0           2       8.0 %
    Writes                            0.5           0.0          23      92.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.6           0.0          25       0.1 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_my_db_dat.dat
    my_db_dat                     per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.0           0.0           0       0.0 %
    Writes                            0.1           0.0           3     100.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.1           0.0           3       0.0 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_my_db_log.dat
    my_db_log                     per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.0           0.0           0       0.0 %
    Writes                            0.1           0.0           4     100.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.1           0.0           4       0.0 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_pubs2_dat.dat
    pubs2_dat                     per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.0           0.0           0       0.0 %
    Writes                            0.1           0.0           3     100.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.1           0.0           3       0.0 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_pubs2_log.dat
    pubs2_log                     per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.0           0.0           0       0.0 %
    Writes                            0.1           0.0           3     100.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.1           0.0           3       0.0 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_pubtune_data.dat
    pubtune_data                  per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.0           0.0           0       0.0 %
    Writes                            0.1           0.0           3     100.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.1           0.0           3       0.0 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_pubtune_log.dat
    pubtune_log                   per sec      per xact       count  % of total
  -------------------------  ------------  ------------  ----------  ----------
    Reads
      APF                             0.0           0.0           0       0.0 %
      Non-APF                         0.0           0.0           0       0.0 %
    Writes                            0.1           0.0           3     100.0 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          0.1           0.0           3       0.0 %


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
    Reads
      APF                             0.4           0.0          16       9.9 %
      Non-APF                         0.2           0.0          10       6.2 %
    Writes                            3.0           0.0         135      83.9 %
  -------------------------  ------------  ------------  ----------  ----------
  Total I/Os                          3.6           0.0         161       0.8 %


  -----------------------------------------------------------------------------

  Device:
    /opt/sap/data/ase/SPEC_tempdb_data_01.dat
    tempdbdev                     per sec      per xact       count  % of total
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
  Total Network I/O Requests      15911.9          12.8      716037       n/a
  Network I/Os Delayed                0.0           0.0           0       0.0 %


  Network Receive Activity        per sec      per xact       count
  -------------------------  ------------  ------------  ----------
  Total TDS Packets Rec'd         15839.0          12.8      712756
  Total Bytes Rec'd              936140.8         754.3    42126334
  Avg Bytes Rec'd per Packet          n/a           n/a          59

  Network Send Activity           per sec      per xact       count
  -------------------------  ------------  ------------  ----------
  Total TDS Packets Sent          15903.8          12.8      715671
  Total Bytes Sent              1343934.5        1082.9    60477054
  Avg Bytes Sent per Packet           n/a           n/a          84

=============================== End of Report =================================
(return status = 0)
1> 2>










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





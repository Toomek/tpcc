

use master
go
disk init name = 'demodb_01_dat', physname = '/opt/data/ase/PRIMARY_DS_demodb_01_dev.dat', size = '1024M'
go
disk init name = 'demodb_02_dat', physname = '/opt/data/ase/PRIMARY_DS_demodb_02_dev.dat', size = '1024M'
go
disk init name = 'demodb_01_log', physname = '/opt/data/ase/PRIMARY_DS_demodb_01_dev.log', size = '512M'
go
disk init name = 'demodb_02_log', physname = '/opt/data/ase/PRIMARY_DS_demodb_02_dev.log', size = '512M'
go

use master
go
drop database demodb
go

create database demodb
on demodb_01_dat = '1024M', demodb_02_dat = '1024M'
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
use demodb
go
sp_logiosize "8"
go
use tempdb
go
sp_logiosize "8"
go


sp_configure 'enable functionality group', 1
go

-- configure max memory on SAP ASE for 13G
sp_configure 'max memory', 6815744
go
sp_cacheconfig 'default data cache', '6G'
go
sp_cacheconfig "default data cache", "cache_partition=4"
go
sp_poolconfig 'default data cache', "1G", "8K"
go

-- configure 4 threads for SAP ASE
sp_configure 'max online engines', 4
go
alter thread pool syb_default_pool with thread count = 4
go
sp_configure "lock scheme", 0, datarows
go
sp_configure "number of locks", 1000000
go
sp_configure "user connections",256
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
sp_configure 'session tempdb log cache size', 8192
go
sp_configure 'heap memory per user', 16384
go


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
physname = '/opt/data/ase/PRIMARY_DS_demodb_imrslog_01.dat',
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







use master
go
disk init name = 'demodb_01_dat', physname = '/opt/data/ase/PRIMARY_DS_demodb_01_dev.dat', size = '1024M'
go
disk init name = 'demodb_01_log', physname = '/opt/data/ase/PRIMARY_DS_demodb_01_dev.log', size = '512M'
go
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


sp_configure 'enable functionality group', 1
go

-- configure max memory on SAP ASE for 12G
sp_configure 'max memory', 6291456
go
sp_cacheconfig 'default data cache', '10G'
go
-- configure 4 threads for SAP ASE
sp_configure 'max online engines', 4
go
alter thread pool syb_default_pool with thread count = 4
go
sp_configure "lock scheme", 0, datarows
go




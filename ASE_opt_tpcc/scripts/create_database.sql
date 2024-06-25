use master
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
use demodb
go
sp_logiosize "8"
go
use tempdb
go
sp_logiosize "8"
go



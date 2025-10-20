USE [unscproduzione]
GO
/****** Object:  StoredProcedure [dbo].[netsend]    Script Date: 14/10/2025 12:36:26 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [dbo].[netsend] @dbname varchar(50) 
As

--Script Language and Platform: MS SQL 7.0 and MS SQL 2000
--Objecttive: Before restoreing,upgrading database,database administrator is responsible to 
--inform all the users in that database that they are going to be disconnected and remind 
--them to save their works.
--exec netsend 'xyz'--xyz is the database name
--Created by :Claire Hsu  2003/4/19
--Email:messageclaire@yahoo.com

create table #table1000(msg varchar(1000))
insert into #table1000 select  distinct 'net send '+ltrim(rtrim(y.hostname))+ ' "Ciao! Sono WWW1! Come và il lavoro?? Ma lo sapete che mancano solo 8 giorni??? Buon Lavoro!!!"' from master.dbo.sysprocesses y,master.dbo.sysdatabases x where y.hostname <> @@servername and y.hostname<>'' 
and x.dbid = y.dbid and x.name = @dbname
declare @msgs varchar(1000)
declare cur1 cursor for select msg from #table1000
open cur1
fetch next from cur1 into @msgs
while @@fetch_status = 0
begin
exec master.dbo.xp_cmdshell @msgs
fetch next from cur1 into @msgs
end
close cur1
deallocate cur1
drop table #table1000



--Usage
--exec netsend 'xyz'
GO

USE master;
go

SET NOCOUNT ON;

-- Declare variables.
DECLARE @bakPath       nvarchar(260);   -- Fully qualified backup file name location.

DECLARE @targetDirData nvarchar(260);
DECLARE @targetDirLog  nvarchar(260);
DECLARE @dbName        sysname;         -- Target DB (name of DB that you're restoring).
DECLARE @pName_Data    nvarchar(260);
DECLARE @pName_Log     nvarchar(260);

DECLARE @version       nvarchar(128);
DECLARE @sql           nvarchar(MAX);
DECLARE @parmDef       nvarchar(MAX);
DECLARE @lName_Data    nvarchar(128);
DECLARE @lName_Log     nvarchar(128);

-- Initialize variables.
SET @bakPath       = '$(bakPath)';

SET @targetDirData = 'D:\AppsData\database\mssql\CLIENT\';
SET @targetDirLog  = 'D:\AppsData\database\mssql\CLIENT\';
SET @dbName        = '$(dbName)';
SET @pName_Data    = @targetDirData + @dbName + '.mdf';
SET @pName_Log     = @targetDirLog  + @dbName + '.ldf';

-- SELECT @version = CAST(SERVERPROPERTY ('ProductVersion') AS nvarchar(128));
-- PRINT '[INFO] SQL Server ' + @version;

IF EXISTS (SELECT name FROM master.sys.databases WHERE name = @dbName)
BEGIN
    PRINT 'INFO- Database ' + QUOTENAME(@dbName) + ' already exists on ' + @@SERVERNAME + '.  Dropping it...';
    SET @sql =
    'DROP DATABASE ' + QUOTENAME(@dbName) + ';';
    EXEC sp_executesql @sql;
END;

-- Get filelist information from the backup file.
IF OBJECT_ID ('tempdb..##file_list') IS NOT NULL
BEGIN
    DROP TABLE ##file_list;
END;

CREATE TABLE ##file_list
    (LogicalName          nvarchar(128),
     PhysicalName         nvarchar(260),
     Type                 char(1),
     FileGroupName        nvarchar(128),
     Size                 numeric(20, 0),
     MaxSize              numeric(20, 0),
     FileID               bigint,
     CreateLSN            numeric(25, 0),
     DropLSN              numeric(25, 0),
     UniqueID             uniqueidentifier,
     ReadOnlyLSN          numeric(25, 0),
     ReadWriteLSN         numeric(25, 0),
     BackupSizeInBytes    bigint,
     SourceBlockSize      int,
     FileGroupID          int,
     LogGroupGUID         uniqueidentifier,
     DifferentialBaseLSN  numeric(25, 0),
     DifferentialBaseGUID uniqueidentifier,
     IsReadOnly           bit,
     IsPresent            bit,
     TDEThumbprint        varbinary(32)
     , SnapshotURL        nvarchar(360) -- When using SQL Server 2017.
    );

SET @sql =
'RESTORE FILELISTONLY
     FROM DISK = @bakPath;';
SET @parmDef = '@bakPath nvarchar(260)';
INSERT INTO ##file_list
    EXEC sp_executesql @sql, @parmDef,
         @bakPath = @bakPath;

SET @lName_Data = (SELECT LogicalName FROM ##file_list WHERE Type = 'D');
SET @lName_Log  = (SELECT LogicalName FROM ##file_list WHERE Type = 'L');

-- Restore the backup.
PRINT 'INFO- Restoring Database ' + QUOTENAME(@dbName) + ' to ' + @@SERVERNAME + '...';

SET @sql =
'RESTORE DATABASE @dbName
     FROM DISK = @bakPath
     WITH MOVE @lName_Data TO @pName_Data,
          MOVE @lName_Log  TO @pName_Log;' -- , RECOVERY;';
SET @parmDef = N'@dbName sysname, @bakPath nvarchar(260), @lName_Data nvarchar(128), @pName_Data nvarchar(260), @lName_Log nvarchar(128), @pName_Log nvarchar(260)';
EXEC sp_executesql @sql, @parmDef,
     @dbName     = @dbName,
     @bakPath    = @bakPath,
     @lName_Data = @lName_Data,
     @pName_Data = @pName_Data,
     @lName_Log  = @lName_Log,
     @pName_Log  = @pName_Log;

-- Map your ARCHIBUS database accounts (and make DB the new default one).
PRINT 'INFO- ARCHIBUS: Map the server logins to the database users in ' + QUOTENAME(@dbName) + ' and grant accesses to ''afm_secure''...'

SET @sql =
'USE ' + QUOTENAME(@dbName) + ';
 IF EXISTS (SELECT * FROM sys.triggers WHERE name = ''ChangeLogging_LogDDLCommands'')
     DROP TRIGGER ChangeLogging_LogDDLCommands ON DATABASE;
 EXEC sp_defaultdb ''afm'', ' + QUOTENAME(@dbName) + ';
 EXEC sp_change_users_login ''Update_One'', ''afm'', ''afm'';
 EXEC sp_change_users_login ''Update_One'', ''afm_secure'', ''afm_secure'';
 GRANT REFERENCES, SELECT ON AFM.AFM_GROUPS TO afm_secure;
 GRANT REFERENCES, SELECT ON AFM.AFM_USERS TO afm_secure;'
EXEC sp_executesql @sql;

-- Reset afm_users.user_pwd.
PRINT 'INFO- ARCHIBUS: Reset the password of the Users in ' + QUOTENAME(@dbName) + '...'

SET @sql =
'USE ' + QUOTENAME(@dbName) + ';
 UPDATE afm.afm_users SET user_pwd = ''afm'';'
EXEC sp_executesql @sql;
go

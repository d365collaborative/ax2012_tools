USE MASTER
SET NOCOUNT ON
DECLARE @RestorePath AS NVARCHAR(MAX), @NewDBName AS NVARCHAR(MAX), @SQL2012 AS BIT, @NewDataPath AS NVARCHAR(MAX), @NewLogPath AS NVARCHAR(MAX), @SQL2014 AS BIT, @VERBOSE AS BIT, @DefaultDataPath nvarchar(512), @DefaultLogPath nvarchar(512), 
@DefaultBackupPath nvarchar(512), @MasterData nvarchar(512), @MasterLog nvarchar(512), @ChangeRecovery2Simpel AS BIT, @SQL2016 AS BIT, @NORECOVERY AS BIT

SET @RestorePath = N'#RESTOREPATH#'; --Last char CANNOT be '\'
SET @NewDBName = '#DATABASENAME#'; --NULL if you want to use the original name from the file.

SET @VERBOSE = 0

SET @SQL2012 = 1
SET @SQL2014 = 0
SET @SQL2016 = 0

SET @ChangeRecovery2Simpel = 1
SET @NORECOVERY = 0

--################# Template Code - Get default file path for DATA / LOG / Backup #################--
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @DefaultDataPath output
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @DefaultLogPath output
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory', @DefaultBackupPath output

exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters', N'SqlArg0', @MasterData output
select @MasterData=substring(@MasterData, 3, 255)
select @MasterData=substring(@MasterData, 1, len(@MasterData) - charindex('\', reverse(@MasterData)))


exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters', N'SqlArg2', @MasterLog output
select @MasterLog=substring(@MasterLog, 3, 255)
select @MasterLog=substring(@MasterLog, 1, len(@MasterLog) - charindex('\', reverse(@MasterLog)))

select @DefaultDataPath = isnull(@DefaultDataPath, @MasterData) , 
	   @DefaultLogPath = isnull(@DefaultLogPath, @MasterLog),
	   @DefaultBackupPath = isnull(@DefaultBackupPath, @MasterLog)	   


--################# Template Code - Get default file path for DATA / LOG / Backup #################--

DECLARE @BackupFilePath AS NVARCHAR(MAX), @SQLRestore AS NVARCHAR(MAX), @LogicalNameMDF AS NVARCHAR(MAX), @LogicalNameLDF AS NVARCHAR(MAX), @PhysicalName AS NVARCHAR(MAX), @Version AS NUMERIC

(18,10), @InstanceName AS NVARCHAR(MAX);
SET @SQLRestore = '';


SET @Version = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - 1) + '.' + REPLACE(RIGHT(CAST

(SERVERPROPERTY('ProductVersion') AS nvarchar(max)), LEN(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))),'.','') AS 

numeric(18,10))

IF OBJECT_ID('tempdb..#FileListTable') IS NOT NULL
	DROP TABLE #FileListTable

create table #FileListTable
(
LogicalName nvarchar(128)
,PhysicalName nvarchar(260)
,Type char(1)
,FileGroupName nvarchar(128)
,Size numeric(20,0)
,MaxSize numeric(20,0),
FileId tinyint,
CreateLSN numeric(25,0),
DropLSN numeric(25, 0),
UniqueID uniqueidentifier,
ReadOnlyLSN numeric(25,0),
ReadWriteLSN numeric(25,0),
BackupSizeInBytes bigint,
SourceBlockSize int,
FileGroupId int,
LogGroupGUID uniqueidentifier,
DifferentialBaseLSN numeric(25,0),
DifferentialBaseGUID uniqueidentifier,
IsReadOnly bit,
IsPresent bit,
TDEThumbprint varbinary(32)
)

IF OBJECT_ID('tempdb..#HeaderOnlyTable') IS NOT NULL
	DROP TABLE #HeaderOnlyTable

CREATE TABLE #HeaderOnlyTable 
(
	BackupName  nvarchar(128),
	BackupDescription  nvarchar(255) ,
	BackupType  smallint ,
	ExpirationDate  datetime ,
	Compressed  bit ,
	Position  smallint ,
	DeviceType  tinyint ,
	UserName  nvarchar(128) ,
	ServerName  nvarchar(128) ,
	DatabaseName  nvarchar(128) ,
	DatabaseVersion  int ,
	DatabaseCreationDate  datetime ,
	BackupSize  numeric(20,0) ,
	FirstLSN  numeric(25,0) ,
	LastLSN  numeric(25,0) ,
	CheckpointLSN  numeric(25,0) ,
	DatabaseBackupLSN  numeric(25,0) ,
	BackupStartDate  datetime ,
	BackupFinishDate  datetime ,
	SortOrder  smallint ,
	CodePage  smallint ,
	UnicodeLocaleId  int ,
	UnicodeComparisonStyle  int ,
	CompatibilityLevel  tinyint ,
	SoftwareVendorId  int ,
	SoftwareVersionMajor  int ,
	SoftwareVersionMinor  int ,
	SoftwareVersionBuild  int ,
	MachineName  nvarchar(128) ,
	Flags  int ,
	BindingID  uniqueidentifier ,
	RecoveryForkID  uniqueidentifier ,
	Collation  nvarchar(128) ,
	FamilyGUID  uniqueidentifier ,
	HasBulkLoggedData  bit ,
	IsSnapshot  bit ,
	IsReadOnly  bit ,
	IsSingleUser  bit ,
	HasBackupChecksums  bit ,
	IsDamaged  bit ,
	BeginsLogChain  bit ,
	HasIncompleteMetaData  bit ,
	IsForceOffline  bit ,
	IsCopyOnly  bit ,
	FirstRecoveryForkID  uniqueidentifier ,
	ForkPointLSN  numeric(25,0) NULL,
	RecoveryModel  nvarchar(60) ,
	DifferentialBaseLSN  numeric(25,0) NULL,
	DifferentialBaseGUID  uniqueidentifier ,
	BackupTypeDescription  nvarchar(60) ,
	BackupSetGUID  uniqueidentifier NULL,
	CompressedBackupSize  numeric(20,0)
	
)

IF (@SQL2012 = 1 OR @SQL2014 = 1)
BEGIN
	ALTER TABLE #HeaderOnlyTable 
	ADD containment tinyint not NULL --New in SQL 2012
END


IF(@SQL2014 = 1)
BEGIN
	ALTER TABLE #HeaderOnlyTable 
	ADD KeyAlrithm nvarchar(32) null --New in SQL 2014 (PCU1)
	
	ALTER TABLE #HeaderOnlyTable 
	ADD EncryptorThumbprint varbinary(20) null --New in SQL 2014 (PCU1)
	
	ALTER TABLE #HeaderOnlyTable 
	ADD EncryptorType nvarchar(32) null --New in SQL 2014 (PCU1)	
END

IF(@SQL2016 = 1)
BEGIN
	ALTER TABLE #FileListTable
	ADD SnapshotUrl nvarchar(360)

END


DECLARE @LoopRestorePathData NVARCHAR(MAX), @LoopRestorePathLog NVARCHAR(MAX)
SET @BackupFilePath = @RestorePath
	IF(@VERBOSE = 1)
	BEGIN
		SELECT 'BackupFilePath', @BackupFilePath;	

		PRINT 'BEGIN QUERYING FILES';

		EXEC ('RESTORE HEADERONLY FROM DISK = '''+ @BackupFilePath +'''')

		EXEC ('RESTORE FILELISTONLY FROM DISK = '''+ @BackupFilePath +'''')	
	END
	

	INSERT #HeaderOnlyTable 
	EXEC ('RESTORE HEADERONLY FROM DISK = '''+ @BackupFilePath +'''')
	
	INSERT #FileListTable 
	EXEC ('RESTORE FILELISTONLY FROM DISK = '''+ @BackupFilePath +'''')	


	SELECT @LogicalNameMDF = (SELECT LogicalName FROM #FileListTable WHERE [Type] = 'D' )
	
	IF(@VERBOSE = 1)
	BEGIN
		SELECT 'LogicalNameMDF', @LogicalNameMDF
	END

	SELECT @LogicalNameLDF = (SELECT LogicalName FROM #FileListTable WHERE [Type] = 'L' )
	
	IF(@VERBOSE = 1)
	BEGIN
		SELECT 'LogicalNameLDF', @LogicalNameLDF
	END
	
	DECLARE @LocalDBName NVARCHAR(200)

	SET @SQLRestore = ''
	
	IF(@VERBOSE = 1)
	BEGIN
		SELECT 'DefaultDataPath_DefaultLogPath', @DefaultDataPath, @DefaultLogPath
	END
		
	IF( @NewDBName IS NULL)
	BEGIN
		SET @LocalDBName = (SELECT DATABASENAME FROM #HeaderOnlyTable)
	END
	ELSE
	BEGIN 
		SET @LocalDBName = @NewDBName
	END

		
	SELECT @LoopRestorePathData = @DefaultDataPath + '\' + @LocalDBName +'.mdf'	
	SELECT @LoopRestorePathLog =  @DefaultLogPath + '\' + @LocalDBName +'_log.ldf'
		
	SET @SQLRestore += CHAR(13) +'USE MASTER' + CHAR(13) + ';' + CHAR(13)
	SET @SQLRestore += 'IF db_id('''+ @LocalDBName +''') IS NOT NULL' + CHAR(13) + 'BEGIN' + CHAR(13)
	SET @SQLRestore += 'ALTER DATABASE ['+ @LocalDBName +'] SET SINGLE_USER WITH ROLLBACK IMMEDIATE' + ';' + CHAR(13) 
	SET @SQLRestore += 'END' + CHAR(13)+ ';' + CHAR(13)
	SET @SQLRestore += 'RESTORE DATABASE ['+ @LocalDBName +'] FROM  DISK = N'''+ @BackupFilePath +''' WITH  FILE = 1,  MOVE N'''+ @LogicalNameMDF +''' TO N'''+ @LoopRestorePathData +''',  MOVE N'''+ @LogicalNameLDF +''' TO N'''+ @LoopRestorePathLog +''',  NOUNLOAD,  REPLACE,  STATS = 5' 
	
	IF(@NORECOVERY = 1)
	BEGIN
		SET @SQLRestore += ', NORECOVERY'
	END
	
	SET @SQLRestore += CHAR(13) + ';' + CHAR(13)
	
	IF(@LogicalNameMDF != @LocalDBName)
	BEGIN
		SET @SQLRestore += 'ALTER DATABASE ['+ @LocalDBName +'] MODIFY FILE (NAME=N'''+ @LogicalNameMDF +''', NEWNAME=N'''+ @LocalDBName +''')' + CHAR(13) + 'ALTER DATABASE ['+ @LocalDBName +'] MODIFY FILE (NAME=N'''+ @LogicalNameLDF +''', NEWNAME=N'''+ @LocalDBName +'_log'')' + CHAR(13) + ';' + CHAR(13)
	END

	SET @SQLRestore += 'ALTER DATABASE ['+ @LocalDBName +'] SET MULTI_USER' + CHAR(13) + ';' + CHAR(13)

	IF(@ChangeRecovery2Simpel = 1)
	BEGIN
		SET @SQLRestore += 'ALTER DATABASE ['+ @LocalDBName +'] SET RECOVERY SIMPLE '+ CHAR(13) + ';' + CHAR(13)
		SET @SQLRestore += 'EXECUTE ('''
		SET @SQLRestore += 'USE ['+ @LocalDBName +'] ' 
		SET @SQLRestore += 'DBCC SHRINKFILE (N'''''+ @LocalDBName + '_log'''' , 0, TRUNCATEONLY)'
		SET @SQLRestore += ''')'+ CHAR(13) + ';' + CHAR(13) 
	END	

	IF(@VERBOSE = 1)
	BEGIN
		PRINT (@SQLRestore)
		SELECT 'DefaultDataPath_DefaultLogPath_2', @DefaultDataPath, @DefaultLogPath
	END
		
	SELECT @LogicalNameMDF AS DatabaseNameFromFile, 'See message generated. It contains the formatted version of the script' AS [Message], @SQLRestore AS Script2Run
	PRINT (@SQLRestore)
			
	IF(@VERBOSE = 1)
	BEGIN
		SELECT *
		FROM #HeaderOnlyTable 
		
		SELECT *
		FROM #FileListTable
	END
	
	SET @SQLRestore = ''
	
	TRUNCATE TABLE #HeaderOnlyTable
	TRUNCATE TABLE #FileListTable


--Cleanup.
IF OBJECT_ID('tempdb..#DirectoryTree') IS NOT NULL
      DROP TABLE #DirectoryTree;


/*	Clean up...
*/
IF OBJECT_ID('tempdb..#tempInstanceNames') IS NOT NULL
	DROP TABLE #tempInstanceNames


IF OBJECT_ID('tempdb..#HeaderOnlyTable') IS NOT NULL
	DROP TABLE #HeaderOnlyTable

GO
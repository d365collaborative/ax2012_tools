BACKUP DATABASE [#DATABASENAME#] TO  DISK = N'#BACKUPPATH#' WITH  COPY_ONLY, COMPRESSION, NOFORMAT, NOINIT,  NAME = N'#DATABASENAME#-Full Database Backup-#DATESTRING#', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
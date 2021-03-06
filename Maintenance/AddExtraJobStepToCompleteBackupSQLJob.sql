USE [msdb]

DECLARE @JobID UNIQUEIDENTIFIER;
DECLARE @JobStepCmd NVARCHAR(MAX);

SELECT @JobID = job_id
FROM dbo.sysjobs
WHERE name LIKE '%DailyCompleteBackup';

SELECT @JobStepCmd = command 
FROM dbo.sysjobsteps
WHERE job_id = @JobID
AND step_id = 1;


/****** Object:  Step [DailyCompleteBackup]    Script Date: 05/11/2014 11:45:59 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_id=@JobID, @step_id=1;

EXEC msdb.dbo.sp_add_jobstep @job_id=@JobID, @step_name=N'Check the Instance Role', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=1, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/* check to see if this server is the primary instance 
We only want to continue if we are on the primary instance */
IF NOT EXISTS (
			SELECT * FROM sys.availability_replicas r
				INNER JOIN sys.dm_hadr_availability_replica_states s
					ON r.replica_id = s.replica_id
			WHERE replica_server_name = @@SERVERNAME
			AND s.role_desc = ''PRIMARY'')
BEGIN
	RAISERROR(''This is the SECONDARY server so do not proceed with the rest of the job'',16,1);
END', 
		@database_name=N'master', 
		@flags=0;

EXEC msdb.dbo.sp_add_jobstep @job_id=@JobID, @step_name=N'DailyCompleteBackup', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=@JobStepCmd, 
		@flags=0
GO

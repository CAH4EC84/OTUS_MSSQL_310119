USE [otusProject]
GO
EXEC sp_configure 'clr enabled',1
GO
EXEC sp_configure 'clr strict security',0;
GO
RECONFIGURE
GO

USE master
--Сбой при запросе разрешения типа "System.Net.Mail.SmtpPermission, System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089".
ALTER DATABASE [otusProject] SET TRUSTWORTHY ON; 
go
USE [otusProject]
GO
/*
DROP FUNCTION [dbo].[fn_SendMail]
DROP ASSEMBLY [HW17CLR_MailSender]
*/

CREATE ASSEMBLY [HW17CLR_MailSender]
AUTHORIZATION [dbo]
FROM 'D:\Temp\HW17CLR_MailSender.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS

GO
 CREATE FUNCTION fn_SendMail (@subj nvarchar(255),@mailTo nvarchar(255))
 RETURNS nvarchar(max)
 as EXTERNAL NAME [HW17CLR_MailSender].MailSender.Send


 SELECT [dbo].[fn_SendMail] ('Subject - Check CLR','alex2@russia.spb.ru')
 

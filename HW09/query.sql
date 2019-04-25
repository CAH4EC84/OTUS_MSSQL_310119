/*Создаем БД для проекта*/
CREATE DATABASE [otusProject]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'otusProject', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\otusProject.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'otusProject_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\otusProject_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [otusProject] SET COMPATIBILITY_LEVEL = 140
GO
ALTER DATABASE [otusProject] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [otusProject] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [otusProject] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [otusProject] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [otusProject] SET ARITHABORT OFF 
GO
ALTER DATABASE [otusProject] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [otusProject] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [otusProject] SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = OFF)
GO
ALTER DATABASE [otusProject] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [otusProject] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [otusProject] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [otusProject] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [otusProject] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [otusProject] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [otusProject] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [otusProject] SET  DISABLE_BROKER 
GO
ALTER DATABASE [otusProject] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [otusProject] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [otusProject] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [otusProject] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [otusProject] SET  READ_WRITE 
GO
ALTER DATABASE [otusProject] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [otusProject] SET  MULTI_USER 
GO
ALTER DATABASE [otusProject] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [otusProject] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [otusProject] SET DELAYED_DURABILITY = DISABLED 
GO
USE [otusProject]
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = Off;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = Primary;
GO
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = On;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = Primary;
GO
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = Off;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = Primary;
GO
USE [otusProject]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [otusProject] MODIFY FILEGROUP [PRIMARY] DEFAULT
GO

/*Создаем схемы*/

CREATE SCHEMA [clients];
GO

CREATE SCHEMA [orders];
GO

CREATE SCHEMA [reports];
GO

CREATE SCHEMA [subscriptions];
GO

EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Клиенты получатели отчетов, как клиенты системы (поставщики \ аптеки), так и локальные отчеты менеджерам.', @level0type = N'SCHEMA', @level0name = N'clients';
GO

EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Входящие заказы', @level0type = N'SCHEMA', @level0name = N'orders';
GO

EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Импортируемые подписки (на данный момент XML)', @level0type = N'SCHEMA', @level0name = N'subscriptions';
GO

/*Созадем таблицы для БД*/

-- ************************************** [subscriptions].[importedData]

CREATE TABLE [subscriptions].[importedData]
(
 [id]       bigint NOT NULL ,
 [name]     nvarchar(255) NOT NULL ,
 [path]     nvarchar(255) NOT NULL ,
 [timeOf]   datetime NOT NULL ,
 [recState] int NOT NULL ,
 [xml]      xml NOT NULL ,

 CONSTRAINT [PK_ImportedData] PRIMARY KEY CLUSTERED ([id] ASC)
);
GO


-- ************************************** [clients].[regions]

CREATE TABLE [clients].[regions]
(
 [id]       bigint NOT NULL ,
 [parentId] bigint NULL ,
 [name]     nvarchar(255) NULL ,
 [recState] int NULL ,

 CONSTRAINT [PK_regions] PRIMARY KEY CLUSTERED ([id] ASC)
);
GO

-- ************************************** [clients].[users]

CREATE TABLE [clients].[users]
(
 [id]             bigint NOT NULL ,
 [regionsId]      bigint NOT NULL ,
 [parentId]       bigint NOT NULL ,
 [name]           nvarchar(255) NULL ,
 [type]           int NULL ,
 [recState]       int NULL ,
 [inn]            nvarchar(20) NULL ,
 [subscriptionId] bigint NOT NULL ,

 CONSTRAINT [PK_users] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_76] FOREIGN KEY ([regionsId])  REFERENCES [clients].[regions]([id]),
 CONSTRAINT [FK_96] FOREIGN KEY ([subscriptionId])  REFERENCES [subscriptions].[importedData]([id])
);
GO

CREATE NONCLUSTERED INDEX [fkIdx_76] ON [clients].[users] 
 (
  [regionsId] ASC
 )

GO

CREATE NONCLUSTERED INDEX [fkIdx_96] ON [clients].[users] 
 (
  [subscriptionId] ASC
 )
GO


-- ************************************** [orders].[heads]

CREATE TABLE [orders].[heads]
(
 [id]         bigint NOT NULL ,
 [timeOf]     datetime NOT NULL ,
 [recState]   int NULL ,
 [num]        nvarchar(50) NULL ,
 [fileKey]    nvarchar(255) NULL ,
 [amount]     decimal(19,2) NULL ,
 [amountInit] decimal(19,2) NULL ,
 [fromUserId] bigint NOT NULL ,
 [toUserId]   bigint NOT NULL ,

 CONSTRAINT [PK_heads] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_86] FOREIGN KEY ([fromUserId])  REFERENCES [clients].[users]([id]),
 CONSTRAINT [FK_89] FOREIGN KEY ([toUserId])  REFERENCES [clients].[users]([id])
);
GO


CREATE NONCLUSTERED INDEX [fkIdx_86] ON [orders].[heads] 
 (
  [fromUserId] ASC
 )

GO

CREATE NONCLUSTERED INDEX [fkIdx_89] ON [orders].[heads] 
 (
  [toUserId] ASC
 )

GO

-- ************************************** [orders].[lines]

CREATE TABLE [orders].[lines]
(
 [id]       bigint NOT NULL ,
 [headsId]  bigint NOT NULL ,
 [timeOf]   datetime NULL ,
 [recState] int NULL ,
 [posCount] int NULL ,
 [product]  nvarchar(255) NULL ,
 [maker]    nvarchar(255) NULL ,

 CONSTRAINT [PK_lines] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_28] FOREIGN KEY ([headsId])  REFERENCES [orders].[heads]([id])
);
GO


CREATE NONCLUSTERED INDEX [fkIdx_28] ON [orders].[lines] 
 (
  [headsId] ASC
 )

GO

-- ************************************** [reports].[types]

CREATE TABLE [reports].[types]
(
 [id]   bigint NOT NULL ,
 [name] varchar(255) NOT NULL ,

 CONSTRAINT [PK_types] PRIMARY KEY CLUSTERED ([id] ASC)
);
GO

-- ************************************** [reports].[reports]

CREATE TABLE [reports].[reports]
(
 [id]         bigint NOT NULL ,
 [name]       nvarchar(255) NOT NULL ,
 [timeOf]     datetime NOT NULL ,
 [recState]   int NOT NULL ,
 [typesId]    bigint NOT NULL ,
 [exportPath] nvarchar(255) NOT NULL ,

 CONSTRAINT [PK_reports] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_132] FOREIGN KEY ([typesId])  REFERENCES [reports].[types]([id])
);
GO

CREATE NONCLUSTERED INDEX [fkIdx_132] ON [reports].[reports] 
 (
  [typesId] ASC
 )

GO

-- ************************************** [reports].[usersReports]

CREATE TABLE [reports].[usersReports]
(
 [reportTypeid] bigint NOT NULL ,
 [id]           bigint NOT NULL ,
 [usersid]      bigint NOT NULL ,

 CONSTRAINT [PK_usersReports] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_116] FOREIGN KEY ([reportTypeid])  REFERENCES [reports].[reports]([id]),
 CONSTRAINT [FK_121] FOREIGN KEY ([usersid])  REFERENCES [clients].[users]([id])
);
GO


CREATE NONCLUSTERED INDEX [fkIdx_116] ON [reports].[usersReports] 
 (
  [reportTypeid] ASC
 )

GO

CREATE NONCLUSTERED INDEX [fkIdx_121] ON [reports].[usersReports] 
 (
  [usersid] ASC
 )

GO

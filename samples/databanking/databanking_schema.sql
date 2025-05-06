--:setvar DBName OGS_DataBanking
--:setvar DBPath "C:\MS SQL"
--:setvar script_folder "C:\Haller-Erne GmbH\SQL SCRIPT"

USE [master]
GO
/****** Object:  Database [$(DBName)] Script Date: 2025-02-11 09:31:53 ******/
CREATE DATABASE [$(DBName)]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'$(DBName)', FILENAME = N'$(DBPath)\$(DBName).mdf' , SIZE = 73728KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'$(DBName)_log', FILENAME = N'$(DBPath)\$(DBName)_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [$(DBName)] SET COMPATIBILITY_LEVEL = 140
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [$(DBName)].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [$(DBName)] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [$(DBName)] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [$(DBName)] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [$(DBName)] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [$(DBName)] SET ARITHABORT OFF 
GO
ALTER DATABASE [$(DBName)] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [$(DBName)] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [$(DBName)] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [$(DBName)] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [$(DBName)] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [$(DBName)] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [$(DBName)] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [$(DBName)] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [$(DBName)] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [$(DBName)] SET  DISABLE_BROKER 
GO
ALTER DATABASE [$(DBName)] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [$(DBName)] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [$(DBName)] SET TRUSTWORTHY ON 
GO
ALTER DATABASE [$(DBName)] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [$(DBName)] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [$(DBName)] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [$(DBName)] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [$(DBName)] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [$(DBName)] SET  MULTI_USER 
GO
ALTER DATABASE [$(DBName)] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [$(DBName)] SET DB_CHAINING OFF 
GO
ALTER DATABASE [$(DBName)] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [$(DBName)] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [$(DBName)] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [$(DBName)] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'$(DBName)', N'ON'
GO
ALTER DATABASE [$(DBName)] SET QUERY_STORE = OFF
GO
USE [$(DBName)]
GO
/****** Object:  User [sys3xx]    Script Date: 2025-02-11 09:31:53 ******/
CREATE USER [sys3xx] FOR LOGIN [sys3xx] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  Schema [Utility]    Script Date: 2025-02-11 09:31:53 ******/
CREATE SCHEMA [Utility]
GO
/****** Object:  UserDefinedFunction [dbo].[IDCodeParser]    Script Date: 2025-02-11 09:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[IDCodeParser](@IDCode varchar(64) )
RETURNS  @tmp TABLE (Model varchar(16), SerialNumber varchar(16), [Order] varchar(16), Preassembly varchar(16))
AS
begin
------------------------------------------------------------------------
------------------------------------------------------------------------
IF SUBSTRING(@IDCode,  4,1) = '-'   -- MAL-100380A0-000023  /   MAL-100380A0000023         
BEGIN
INSERT INTO @tmp
SELECT 
	SUBSTRING(@IDCode,  5,8),	-- [100380A0]   as Model
	SUBSTRING(@IDCode,  14,9),	-- [000023]   as SerialNumber
	'' ,						-- []  Order
	SUBSTRING(@IDCode,  1,3);	-- [MAL]   as Preassembly
RETURN
END 
------------------------------------------------------------------------
------------------------------------------------------------------------
IF (SUBSTRING(@IDCode,  9,3) = '-Re' or SUBSTRING(@IDCode,  9,3) = '-Li') -- -- 100380A0-Re24110501424103588764
BEGIN
INSERT INTO @tmp
SELECT
	SUBSTRING(@IDCode,  1,8),	-- [100380A0]   as Model
	SUBSTRING(@IDCode,  18,5),	-- [000023]   as SerialNumber
	SUBSTRING(@IDCode,  23,9),  -- [103588764]  Order
	SUBSTRING(@IDCode,  9,3);	-- [MAL]   as Preassembly
	RETURN
END
------------------------------------------------------------------------
-- default :  100380A0 309224 12345 123456789
------------------------------------------------------------------------
INSERT INTO @tmp
SELECT
	SUBSTRING(@IDCode,  1,8),	-- [100380A0]   as Model
	SUBSTRING(@IDCode,  15,5),	-- [000023]   as SerialNumber
	SUBSTRING(@IDCode,  20,9),  -- [103588764]  Order
	'';							-- [MAL]   as Preassembly
RETURN
end


GO
/****** Object:  UserDefinedFunction [dbo].[IDCodeParserRev2]    Script Date: 2025-02-11 09:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[IDCodeParserRev2](@IDCode varchar(64) )
RETURNS  @tmp TABLE (Model varchar(16), SerialNumber varchar(16), Preassembly varchar(16))
AS
begin
------------------------------------------------------------------------
-- 100380A0-GAS-000031 
------------------------------------------------------------------------
IF (SUBSTRING(@IDCode,  9,1) = '-'  and SUBSTRING(@IDCode,  13,1) = '-'   )
BEGIN
INSERT INTO @tmp
SELECT 
	SUBSTRING(@IDCode,  1,8),	-- [100380A0]   as Model
	SUBSTRING(@IDCode,  14,9),	-- [000023]   as SerialNumber
	SUBSTRING(@IDCode,  10,3);	-- [MAL]   as Preassembly
RETURN
END 
------------------------------------------------------------------------
------------------------------------------------------------------------
-- not valid ID code
------------------------------------------------------------------------
INSERT INTO @tmp
SELECT '','',''
RETURN
end


GO
/****** Object:  UserDefinedFunction [dbo].[QT_GetCurveName]    Script Date: 2025-02-11 09:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
CREATE FUNCTION [dbo].[QT_GetCurveName]( @Chn  int, @Seq int)
RETURNS varchar(20)
AS
BEGIN
	RETURN RTRIM(CONCAT ('CHN',RIGHT( '0' + convert( varchar(2) ,  @Chn ),  2 ), '_', @Seq, '.hrv'))
END
GO
/****** Object:  UserDefinedFunction [dbo].[QT_GetCurvePath]    Script Date: 2025-02-11 09:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
CREATE FUNCTION [dbo].[QT_GetCurvePath]( @IP   char(16), @date datetime)
RETURNS varchar(256)
AS
BEGIN
	RETURN RTRIM(CONCAT ( RTRIM(@IP), '\',  Format (@date, 'yyyy-MM-dd')))
END
GO
/****** Object:  Table [dbo].[Applications]    Script Date: 2025-02-11 09:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Applications](
	[application_id] [numeric](7, 0) IDENTITY(1,1) NOT NULL,
	[name] [varchar](40) NOT NULL,
	[desc] [varchar](1024) NULL,
 CONSTRAINT [PK_Applications] PRIMARY KEY CLUSTERED 
(
	[application_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[NonConformID]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NonConformID](
	[Model] [varchar](32) NOT NULL,
	[SerialNumber] [varchar](64) NOT NULL,
	[ID] [varchar](32) NOT NULL,
	[TIME] [datetime] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PDFReport]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PDFReport](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Station] [varchar](64) NOT NULL,
	[IDCode] [varchar](64) NOT NULL,
	[FileName] [varchar](256) NOT NULL,
	[TIME] [datetime] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Permissions]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Permissions](
	[permission_id] [numeric](7, 0) IDENTITY(1,1) NOT NULL,
	[application_id] [numeric](7, 0) NOT NULL,
	[name] [varchar](40) NOT NULL,
	[code] [numeric](7, 0) NOT NULL,
	[command] [nvarchar](1024) NULL,
	[desc] [varchar](1024) NULL,
 CONSTRAINT [PK_Permissions] PRIMARY KEY CLUSTERED 
(
	[permission_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[QualityCode]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QualityCode](
	[QC] [int] NOT NULL,
	[NAME] [varchar](40) NOT NULL,
	[SHORT] [char](16) NOT NULL,
	[TYPEID] [int] NOT NULL,
 CONSTRAINT [XPKQualityCode] PRIMARY KEY CLUSTERED 
(
	[QC] ASC,
	[TYPEID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Results]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Results](
	[ResultID] [int] IDENTITY(1,1) NOT NULL,
	[TIME] [datetime] NOT NULL,
	[TypeID] [int] NOT NULL,
	[Model] [varchar](32) NOT NULL,
	[PartID] [varchar](64) NOT NULL,
	[AFO] [varchar](64) NOT NULL,
	[Final] [int] NOT NULL,
	[JOB] [varchar](32) NOT NULL,
	[OpSeq] [int] NOT NULL,
	[Operation] [varchar](32) NOT NULL,
	[Prg] [int] NULL,
	[Task] [int] NULL,
	[TaskName] [varchar](32) NOT NULL,
	[Tool] [varchar](32) NOT NULL,
	[Station] [varchar](32) NOT NULL,
	[QC] [int] NOT NULL,
	[TOTAL] [int] NOT NULL,
	[Barcode] [varchar](256) NULL,
	[RunCount] [int] NULL,
	[Value1] [float] NULL,
	[Value2] [float] NULL,
	[Value3] [float] NULL,
	[Value4] [float] NULL,
	[Value5] [float] NULL,
	[Value6] [float] NULL,
	[USER] [varchar](32) NULL,
 CONSTRAINT [PK_Results] PRIMARY KEY CLUSTERED 
(
	[ResultID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [PJOResult] UNIQUE NONCLUSTERED 
(
	[PartID] ASC,
	[AFO] ASC,
	[Final] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StationResults]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StationResults](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Barcode] [varchar](64) NOT NULL,
	[Station] [varchar](32) NOT NULL,
	[STATE] [int] NOT NULL,
	[STARTTIME1] [datetime] NOT NULL,
	[STARTTIME2] [datetime] NOT NULL,
	[ProcessDuration] [int] NULL,
	[User] [varchar](32) NOT NULL,
	[MODEL] [varchar](32) NOT NULL,
	[SN] [varchar](32) NOT NULL,
	[ORDER] [varchar](32) NOT NULL,
	[PREASSEMBLY] [varchar](32) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SystemType]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SystemType](
	[TypeID] [int] NOT NULL,
	[NAME] [char](32) NOT NULL,
	[UNIT1] [int] NULL,
	[UNIT2] [int] NULL,
	[UNIT3] [int] NULL,
	[UNIT4] [int] NULL,
	[UNIT5] [int] NULL,
	[UNIT6] [int] NULL,
 CONSTRAINT [XPKSystemType] PRIMARY KEY CLUSTERED 
(
	[TypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TimeTracking]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TimeTracking](
	[AssemblyID] [int] IDENTITY(1,1) NOT NULL,
	[Barcode] [varchar](32) NOT NULL,
	[Rawcode] [varchar](64) NOT NULL,
	[Station] [varchar](32) NOT NULL,
	[STATE] [varchar](8) NOT NULL,
	[ProcessDuration] [int] NULL,
	[STARTTIME] [datetime] NOT NULL,
	[TotalDuration] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[AssemblyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Unit]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Unit](
	[UnitID] [int] NOT NULL,
	[NAME] [varchar](64) NOT NULL,
	[SHORT] [char](8) NOT NULL,
	[DECIMAL] [smallint] NOT NULL,
	[Unit] [varchar](16) NULL,
 CONSTRAINT [XPKUnit] PRIMARY KEY CLUSTERED 
(
	[UnitID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [NonClusteredIndex-20240814-153801]    Script Date: 2025-02-11 09:31:54 ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20240814-153801] ON [dbo].[NonConformID]
(
	[Model] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [NonClusteredIndex-20240814-153913]    Script Date: 2025-02-11 09:31:54 ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20240814-153913] ON [dbo].[NonConformID]
(
	[SerialNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [NonClusteredIndex-20241119-015118]    Script Date: 2025-02-11 09:31:54 ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20241119-015118] ON [dbo].[StationResults]
(
	[MODEL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [NonClusteredIndex-20241119-015215]    Script Date: 2025-02-11 09:31:54 ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20241119-015215] ON [dbo].[StationResults]
(
	[ORDER] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [NonClusteredIndex-20241119-015304]    Script Date: 2025-02-11 09:31:54 ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20241119-015304] ON [dbo].[StationResults]
(
	[SN] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [NonClusteredIndex-20241119-015324]    Script Date: 2025-02-11 09:31:54 ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20241119-015324] ON [dbo].[StationResults]
(
	[PREASSEMBLY] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[StationResults] ADD  DEFAULT ('') FOR [MODEL]
GO
ALTER TABLE [dbo].[StationResults] ADD  DEFAULT ('') FOR [SN]
GO
ALTER TABLE [dbo].[StationResults] ADD  DEFAULT ('') FOR [ORDER]
GO
ALTER TABLE [dbo].[StationResults] ADD  DEFAULT ('') FOR [PREASSEMBLY]
GO
ALTER TABLE [dbo].[Results]  WITH NOCHECK ADD  CONSTRAINT [R_2] FOREIGN KEY([TypeID])
REFERENCES [dbo].[SystemType] ([TypeID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Results] NOCHECK CONSTRAINT [R_2]
GO
/****** Object:  StoredProcedure [dbo].[AddAssemblyState]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[AddAssemblyState] 
	@Barcode		[varchar](32),
	@Rawcode		[varchar](64),
	@Station		[varchar](32),
	@STATE			[varchar](8),
	@TotalDuration [int],
	@STARTTIME		[datetime]
	
AS
BEGIN
	INSERT INTO dbo.TimeTracking
				([Barcode], [Rawcode], [Station], [STATE], [TotalDuration], [STARTTIME]) 
		VALUES  (@Barcode,  @Rawcode,  @Station,  @STATE, @TotalDuration, @STARTTIME)
	SELECT AssemblyID FROM dbo.TimeTracking WHERE AssemblyID = SCOPE_IDENTITY() 
END
GO
/****** Object:  StoredProcedure [dbo].[AddEndAssemblyState]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[AddEndAssemblyState] 
	@ENDTIME	[datetime],
	@AssemblyID int,
	@STATE		[varchar](8)
AS
BEGIN
	DECLARE @STARTTIME datetime
	SELECT @STARTTIME = STARTTIME FROM dbo.TimeTracking
	WHERE AssemblyID = @AssemblyID

	UPDATE dbo.TimeTracking
	SET ProcessDuration = datediff(ss,@STARTTIME,@ENDTIME),
		TotalDuration = TotalDuration + datediff(ss,@STARTTIME,@ENDTIME),
		STATE = @STATE
	WHERE AssemblyID = @AssemblyID
END
GO
/****** Object:  StoredProcedure [dbo].[AddResult]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Croitor>
-- Create date: <2020-12-09>
-- Description:	<mumu>
-- =============================================
CREATE PROCEDURE [dbo].[AddResult] 
	@Time   [datetime],
	@TypeID [int],
	@Model [varchar](32),
	@PartID [varchar](64),
	@AFO    [varchar](64),
	@Final  [int],
	@JOB [varchar](32),
	@OpSeq [int],
	@Operation [varchar](32),
	@Prg [int],
	@Task [int],
	@TaskName [varchar](32),
	@Tool [varchar](32),
	@Station [varchar](32),
	@QC [int] ,
	@Total [int],
	@Barcode [varchar](256) ,
	@RunCount [int],
	@Value1 [float],
	@Value2 [float],
	@Value3 [float],
	@Value4 [float],
	@Value5 [float],
	@Value6 [float],
	@User [varchar](32)
AS
BEGIN

declare @ShortID [varchar](64) = CONCAT (SUBSTRING(@PartID,1,32), '%')
	
	-- TODO:: save Model & AFO into separate Table
	declare @ResultID [int] = NULL
	declare @prevTime [datetime] = NULL

	declare @Unit1 [int] = NULL
	declare @Unit2 [int] = NULL
	declare @Unit3 [int] = NULL
	declare @Unit4 [int] = NULL
	declare @Unit5 [int] = NULL
	declare @Unit6 [int] = NULL

	select @Unit1 = Unit1, @Unit2 = Unit2, @Unit3 = Unit3, @Unit4 = Unit4, @Unit5 = Unit5, @Unit6 = Unit6
	from [dbo].SystemType where TypeID = @TypeID

--	if @Unit1 is NULL SET @Value1 = NULL
--	if @Unit2 is NULL SET @Value2 = NULL
--	if @Unit3 is NULL SET @Value3 = NULL
--	if @Unit4 is NULL SET @Value4 = NULL
--	if @Unit5 is NULL SET @Value5 = NULL
--	if @Unit6 is NULL SET @Value6 = NULL

	select @ResultID = ResultID,  @prevTime = [TIME] from dbo.Results
	where PartID like @ShortID and AFO = @AFO and [FINAL] = @FINAL

	IF @ResultID is NULL BEGIN  -- this is a new result
		INSERT INTO dbo.Results
					 ([TIME], [TypeID], [Model], [PartID], [AFO], [FINAL], [JOB], [OpSeq], [Operation], [Prg], [Task],[TaskName],
					  [Tool], [Station], [QC], [TOTAL], [Barcode], [RunCount],
					  [Value1], [Value2], [Value3], [Value4], [Value5], [Value6], [User]) 
			VALUES  (@TIME, @TypeID, @Model, @PartID, @AFO, @FINAL, @JOB, @OpSeq, @Operation, @Prg, @Task,@TaskName,
					 @Tool, @Station, @QC, @Total, @Barcode, @RunCount,
					 @Value1, @Value2,@Value3, @Value4,@Value5, @Value6, @User)
	END
	ELSE IF @prevTime <> @TIME BEGIN  -- overwrite old result only if time is different
		 UPDATE dbo.Results
				SET [Time]		= @Time,
					[TypeID]	= @TypeID,
					[Model]	    = @Model,
					[JOB]		= @JOB,
					[OpSeq]     = @OpSeq,
					[Operation] = @Operation,
					[Prg]       = @Prg,
					[Task]		= @Task,
					[TaskName]	= @TaskName,
					[Tool]		= @Tool,
					[Station]	= @Station,
					[QC]		= @QC,
					[TOTAL]		= @Total,
					[Barcode]	= @Barcode,
					[RunCount]  = @RunCount,
					Value1      = @Value1,
					Value2      = @Value2,
					Value3      = @Value3,
					Value4      = @Value4,
					Value5      = @Value5,
					Value6      = @Value6,
					[User]		= @User
			where @ResultID = ResultID
	END
END
GO
/****** Object:  StoredProcedure [dbo].[AddStationState]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
CREATE PROCEDURE [dbo].[AddStationState] 
	@Barcode		[varchar](64),
	@Station		[varchar](32),
	@STARTTIME2		[datetime]
 
AS
BEGIN
	DECLARE @MODEL varchar(32),
			@ORDER varchar(32),
			@SN varchar(32),
			@PREASSEMBLY varchar(32)

	select @MODEL=Model, @ORDER=[Order], @SN=SerialNumber, @PREASSEMBLY=Preassembly from [IDCodeParser](@Barcode)
	DECLARE @TotalDuration int = (SELECT SUM (ProcessDuration) FROM StationResults WHERE Barcode = @Barcode);
	INSERT INTO dbo.StationResults
				([Barcode],[Station], [STATE],	[STARTTIME1], [STARTTIME2], [ProcessDuration],[User], [MODEL], [ORDER], [SN], [PREASSEMBLY]) 
		VALUES  (@Barcode,  @Station,  0,  @STARTTIME2,  @STARTTIME2, 0, '', @MODEL, @ORDER, @SN, @PREASSEMBLY )
	SELECT ID as id, @TotalDuration as asembly_time FROM dbo.StationResults WHERE ID = SCOPE_IDENTITY() 
END
GO
/****** Object:  StoredProcedure [dbo].[CheckCharge]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CheckCharge]
	@IDCode varchar(64)
AS 

 declare @st_state  int = (select Top 1 [STATE]  from [$(DBName)].[dbo].[StationResults]
    	where [Barcode] = @IDCode 
		ORDER by ID desc)

   IF @st_state is not NULL
	begin 
		select @st_state as st_state
	end
	else	
		select -1 as st_state


GO
/****** Object:  StoredProcedure [dbo].[CheckLastAssembly]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CheckLastAssembly] 
	@Barcode		[varchar](32)
	
AS
BEGIN
	SELECT TOP 1 TotalDuration FROM TimeTracking WHERE Barcode = @Barcode ORDER BY STARTTIME DESC
END
GO
/****** Object:  StoredProcedure [dbo].[CheckStationState]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
CREATE PROCEDURE [dbo].[CheckStationState] 
	@Barcode		[varchar](32),
	@Station		[varchar](32) = NULL
AS
BEGIN

DECLARE @MODEL varchar(32),
		@ORDER varchar(32),
		@SN varchar(32),
		@PREASSEMBLY varchar(32)
select @MODEL=Model, @ORDER=[Order], @SN=SerialNumber, @PREASSEMBLY=Preassembly from [IDCodeParser](@Barcode)

declare @tmp Table ([State] int, STARTTIME1 datetime,  ProcessDuration int)
INSERT INTO @tmp
	select  [State], STARTTIME1, ProcessDuration  from StationResults
	WHERE Model = @Model
	and   [ORDER] = @Order
	and   SN = @SN
	and   [Station] = @Station
declare @maxTime datetime = (select max(STARTTIME1+ ProcessDuration)  from @tmp)
declare @lastState int   = (select [State]  from @tmp WHERE (STARTTIME1+ ProcessDuration) = @maxTime)
 
SELECT SUM (ProcessDuration) as assembly_time, @lastState as last_state FROM @tmp
END

GO
/****** Object:  StoredProcedure [dbo].[ClearResults]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ClearResults] 
	@PartID   [varchar](64),
	@afo_list [varchar](MAX)
AS
BEGIN
declare @ShortID [varchar](64) = CONCAT (SUBSTRING(@PartID,1,32), '%')

		UPDATE dbo.Results
		SET	QC = 0,
			TOTAL = 0,
			Barcode = NULL,
			RunCount = 0,
			[TIME] = GETDATE(),
			[Value1] = NULL,
			[Value2] = NULL,
			[Value3] = NULL,
			[Value4] = NULL,
			[Value5] = NULL,
			[Value6] = NULL
		WHERE PartID like @ShortID and [AFO] in (SELECT * FROM STRING_SPLIT(@afo_list, ';'))
END
GO
/****** Object:  StoredProcedure [dbo].[GetNonConformList]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetNonConformList]  	@Model [varchar](32), 	@SerialNumber [varchar](64)
AS
BEGIN
	SET NOCOUNT ON;
	SELECT * from [dbo].[NonConformID] where [Model] = @MODEL and [SerialNumber] = @SerialNumber
END
GO
/****** Object:  StoredProcedure [dbo].[GetPDFFile]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =============================================
CREATE PROCEDURE [dbo].[GetPDFFile] @FileName varchar(256)
AS
BEGIN
	SET NOCOUNT ON;
DECLARE @FullFileName VARCHAR(1000) = CONCAT('D:\Data\PDF_Reports\', @FileName)

SELECT Utility.ReadFromFileAsBlob(@FullFileName);

END
GO
/****** Object:  StoredProcedure [dbo].[GetResults]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetResults]  @PartID [varchar](64)
AS
BEGIN

	SET NOCOUNT ON;

declare @tmp  table ( [ResultID] [int], [TIME] [datetime], TypeID [int], Model [varchar](32), PartID [varchar](64),
                      [AFO] [varchar](64), [Final] [int],JOB [varchar](32), OpSeq [int], Operation [varchar](32),
					  [Prg] [int], Task [int], [TaskName] [varchar](32), Tool [varchar](32), Station [varchar](32), QC [int] , TOTAL [int],
					  Barcode [varchar](256) , RunCount [int] ,
					  Value1 float, Value2 float, Value3 float, Value4 float, Value5 float, Value6 float, [User] varchar (32), [START_TIME] [datetime])

declare @ShortID [varchar](64) = CONCAT (SUBSTRING(@PartID,1,32), '%')

declare @job_order table ([START_TIME] [datetime],  JOB [varchar](32))

	INSERT INTO @tmp
	select *, NULL from dbo.Results where [PartID] like @ShortID 

	INSERT INTO @job_order 
		SELECT Min([TIME]),  [JOB] from @tmp group by [JOB]

	MERGE @tmp  AS T
	USING (select * from @job_order) AS S
		ON  S.Job = T.Job
	WHEN MATCHED THEN 
		UPDATE SET T.[START_TIME]	= S.[START_TIME];

	SELECT * from @tmp order by [START_TIME] ASC, OpSeq ASC	
END
GO
/****** Object:  StoredProcedure [dbo].[GetStationStates]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
CREATE PROCEDURE [dbo].[GetStationStates] 
		@MODEL varchar(32),
		@ORDER varchar(32),
		@SN varchar(32),
		@PREASSEMBLY varchar(32)
AS
BEGIN
	select  Station, Barcode from StationResults
	WHERE [Model] = @Model
	and   ((LEN(@ORDER) = 0)       or ([ORDER] = @Order))
	and   ((LEN(@SN) = 0)          or ([SN] = @SN))
	and   ((LEN(@PREASSEMBLY) = 0) or ([PREASSEMBLY] = @PREASSEMBLY))
	and   [State] = 1
END

GO
/****** Object:  StoredProcedure [dbo].[InsertPDFReport]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROCEDURE [dbo].[InsertPDFReport] 
	@Station  [varchar](64),
	@IDCode   [varchar](64),
	@FileName [varchar](256),
	@PDF [varbinary](max)
AS
BEGIN
 
SET NOCOUNT ON;
DECLARE @FullFileName VARCHAR(1000) = CONCAT('D:\Data\PDF_Reports\', @FileName)

select Utility.WriteToFile(@PDF, @FullFileName, 0);

 
DECLARE @exists int = (select count(*) PDFReport from PDFReport where IDCode = @IDCode and Station = @Station)
IF (@exists is NULL) or (@exists = 0)
	INSERT INTO	PDFReport VALUES (@Station, @IDCode, @FileName, CURRENT_TIMESTAMP)
ELSE
	UPDATE PDFReport SET FileName = @FileName,
					 [TIME] = CURRENT_TIMESTAMP
		where IDCode = @IDCode and Station = @Station
END
GO
/****** Object:  StoredProcedure [dbo].[SetNonConformID]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Croitor>
-- Create date: <2020-12-09>
-- Description:	<mumu>
-- =============================================
CREATE PROCEDURE [dbo].[SetNonConformID] 
	@Model [varchar](32),
	@SerialNumber [varchar](64),
	@newID [varchar](32),
	@oldID [varchar](32)
AS
BEGIN
	if (select COUNT(*) from [dbo].[NonConformID]
							 where [Model] = @Model
							 and   [SerialNumber] = @SerialNumber
							 and   [ID] = @oldID
		) > 0
		BEGIN  -- update / delete existing record
			if (@newID is not NULL) and (LEN(@newID) > 0)
				update [dbo].[NonConformID] SET ID = @newID, [TIME] = CURRENT_TIMESTAMP
					where [Model] = @Model
					and   [SerialNumber] = @SerialNumber
					and   [ID] = @oldID;
			else delete from [dbo].[NonConformID] 
					where [Model] = @Model
					and   [SerialNumber] = @SerialNumber
					and   [ID] = @oldID;
		END
	else
		BEGIN  -- insert record
			if (@newID is not NULL) and (LEN(@newID) > 0)
				INSERT INTO [dbo].[NonConformID] values( @Model, @SerialNumber,  @newID,  CURRENT_TIMESTAMP);
		END
END
GO
/****** Object:  StoredProcedure [dbo].[spWriteStringToFile]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[spWriteStringToFile]
 (
@String Varchar(max), --8000 in SQL Server 2000
@Path VARCHAR(255),
@Filename VARCHAR(100)

--
)
AS
DECLARE  @objFileSystem int
        ,@objTextStream int,
		@objErrorObject int,
		@strErrorMessage Varchar(1000),
	    @Command varchar(1000),
	    @hr int,
		@fileAndPath varchar(80)

set nocount on

select @strErrorMessage='opening the File System Object'
EXECUTE @hr = sp_OACreate  'Scripting.FileSystemObject' , @objFileSystem OUT

Select @FileAndPath=@path+'\'+@filename
if @HR=0 Select @objErrorObject=@objFileSystem , @strErrorMessage='Creating file "'+@FileAndPath+'"'
if @HR=0 execute @hr = sp_OAMethod   @objFileSystem   , 'CreateTextFile'
	, @objTextStream OUT, @FileAndPath,2,True

if @HR=0 Select @objErrorObject=@objTextStream, 
	@strErrorMessage='writing to the file "'+@FileAndPath+'"'
if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Write', Null, @String

if @HR=0 Select @objErrorObject=@objTextStream, @strErrorMessage='closing the file "'+@FileAndPath+'"'
if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Close'

if @hr<>0
	begin
	Declare 
		@Source varchar(255),
		@Description Varchar(255),
		@Helpfile Varchar(255),
		@HelpID int
	
	EXECUTE sp_OAGetErrorInfo  @objErrorObject, 
		@source output,@Description output,@Helpfile output,@HelpID output
	Select @strErrorMessage='Error whilst '
			+coalesce(@strErrorMessage,'doing something')
			+', '+coalesce(@Description,'')
	raiserror (@strErrorMessage,16,1)
	end
EXECUTE  sp_OADestroy @objTextStream
EXECUTE sp_OADestroy @objFileSystem
GO
/****** Object:  StoredProcedure [dbo].[MergePDF]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MergePDF]
		@MODEL varchar(32),
		@ORDER varchar(32),
		@SN varchar(32)
AS
BEGIN
	SET NOCOUNT ON;

DECLARE @BaseFolder varchar(100) = 'D:\Data\PDF_Reports\PDFMerge'
DECLARE @cmd SYSNAME = @BaseFolder+'\merge.cmd"'
DECLARE @convert SYSNAME = @BaseFolder+'\convert.cmd"'
DECLARE @dstFolder varchar(100) = 'D:\Data\PDF_Reports\SummaryReport'

DECLARE @dstFileName varchar(256) = @dstFolder + '\'+ @Model +'-'+ @SN + '-'+ @ORDER + '.pdf'

print @dstFileName 

DECLARE @tmp Table (ID int, PDFFileName varchar(256));

-- add report from all final assembly stations
INSERT INTO @tmp
SELECT -1, r.FileName
	from PDFReport r
	cross apply IDCodeParser(IDCode) parsed
	where @Model = parsed.Model
      and @Order = parsed.[Order]
	  and @SN    = parsed.SerialNumber

-- add reports from related preassembly stations
INSERT INTO @tmp
SELECT pre.ID, r.FileName
	from  GetPDFPreassemblyList (@Model, @Order, @SN) pre
	JOIN  PDFReport r ON r.IDCode = CONCAT(pre.Preassembly, '-', pre.Model, '-', pre.SerialNumber)
	order by pre.ID

-- create Batch file "merge.cmd"
DECLARE @txt varchar(1024) = '@ECHO OFF' + CHAR(13)+CHAR(10)
SET @txt = @txt + 'cd /d D:\Data\PDF_Reports' + CHAR(13)+CHAR(10)
SET @txt = @txt + '"' + @BaseFolder+'\pdftk.exe" '

-- add next PDF file into batch file
DECLARE @PDFFileName varchar(256)
DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR 
SELECT PDFFileName FROM @tmp order by ID

OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @PDFFileName
WHILE @@FETCH_STATUS = 0
BEGIN 
	SET @txt = @txt + '"' + @PDFFileName +'" '
    FETCH NEXT FROM MY_CURSOR INTO @PDFFileName
END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR

	SET @txt = @txt + 'cat output "'+ @dstFileName + '"' + CHAR(13)+CHAR(10)
	SET @txt = @txt + 'if %errorlevel%==0 (   echo PDF_SUCCESS ) ' + CHAR(13)+CHAR(10)

-- save batch text to file 'merge.cmd'
execute spWriteStringToFile @txt , @BaseFolder,'tmp_merge.cmd';
EXEC master..xp_cmdshell @convert,no_output;
EXEC master..xp_cmdshell @cmd;

END

GO
/****** Object:  StoredProcedure [dbo].[UpdateStationState]    Script Date: 2025-02-11 09:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROCEDURE [dbo].[UpdateStationState] 
	@ID				[varchar](64),
	@State          int,
	@STARTTIME1		[datetime],
	@ProcessDuration int,
	@User		    [varchar](32)
 
AS
BEGIN
	UPDATE dbo.StationResults
			SET	[STATE] = @State,
				STARTTIME1 = @STARTTIME1,
				[ProcessDuration] = @ProcessDuration,
				[User] = @User 
	where ID = @ID
END
GO

USE [$(DBName)]

:r $(script_folder)\dictionaries.sql

USE [master]
GO
ALTER DATABASE [$(DBName)] SET  READ_WRITE 
GO

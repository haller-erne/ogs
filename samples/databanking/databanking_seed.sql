GO
DECLARE @DBName varchar(256) = (SELECT DB_NAME())
PRINT CONCAT (  @DBName,'--> start job: fill out TABLES')
/****** -----------------------------------------------------------------------------------------******/

GO
/****** Object:  Table [dbo].[QualityCode]    ******/

GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (0, N'Invalid/not started', N'SYS_Err         ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (1, N'OK', N'OK              ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (2, N'Angle high', N'A+              ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (4, N'Angle low', N'A-              ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (8, N'Torque high', N'T+              ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (10, N'Angle high, Torque high', N'A+,T+           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (12, N'Angle low, Torque high', N'A-,T+           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (16, N'Torque low', N'T-              ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (18, N'Angle high, Torque low', N'A+,T-           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (20, N'Angle low, Torque low', N'A- T-           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (32, N'Gradient high', N'G+              ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (34, N'Angle high, Gradient high', N'A+,G+           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (36, N'Angle low, Gradient high', N'A-,G+           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (40, N'Torque high, Gradient high', N'T+,G+           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (42, N'Angle high, Torque high, Gradient high', N'A+,T+,G+        ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (44, N'Angle low, Torque high, Gradient high', N'A-,T+,G+        ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (48, N'Torque low, Gradient high', N'T-,G+           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (50, N'Angle high, Torque low, Gradient high', N'A+,T-,G+        ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (52, N'Angle low, Torque low, Gradient high', N'A-,T-,G+        ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (64, N'Gradient low', N'G-              ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (66, N'Angle high, Gradient low', N'A+,G-           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (68, N'Angle low, Gradient low', N'A-,G-           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (72, N'Torque high, Gradient low', N'T+,G-           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (74, N'Angle high, Torque high, Gradient low', N'A+,T+,G-        ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (76, N'Angle low, Torque high, Gradient low', N'A-,T+,G-        ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (80, N'Torque low, Gradient low', N'T-,G-           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (82, N'Angle high, Torque low, Gradient low', N'A+,T-,G-        ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (84, N'Angle low, Torque low, Gradient low', N'A-,T-,G-        ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (128, N'Loosen(SoRel)', N'SoRel           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (129, N'System error', N'fault           ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (130, N'Remove signal', N'(C)Cw=0/En=0    ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (131, N'Timeout sync/rework/appl', N't+Sync/RW/app   ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (132, N'Synchronization', N'Sync            ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (133, N'Rework', N'RW              ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (135, N'Spindle bypass', N'ByPass          ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (137, N'Torque redundancy', N'RedT            ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (138, N'Angle redundancy', N'RedA            ', 1)
GO
INSERT [dbo].[QualityCode] ([QC], [NAME], [SHORT], [TYPEID]) VALUES (139, N'Start-up test', N'Tst             ', 1)
GO
/****** Table  [dbo].[SystemType]  ******/

GO
INSERT [dbo].[SystemType] ([TypeID], [NAME], [UNIT1], [UNIT2], [UNIT3], [UNIT4], [UNIT5], [UNIT6]) VALUES (1, N'Bosch Tightening System         ', 1, 2, 3, 4, 5, 6)
GO
INSERT [dbo].[SystemType] ([TypeID], [NAME], [UNIT1], [UNIT2], [UNIT3], [UNIT4], [UNIT5], [UNIT6]) VALUES (2, N'Confirmation                    ', NULL, NULL, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[SystemType] ([TypeID], [NAME], [UNIT1], [UNIT2], [UNIT3], [UNIT4], [UNIT5], [UNIT6]) VALUES (4, N'Measurement System (mm)         ', 7, NULL, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[SystemType] ([TypeID], [NAME], [UNIT1], [UNIT2], [UNIT3], [UNIT4], [UNIT5], [UNIT6]) VALUES (5, N'Test GUI                        ', 8, 9, 10, 11, 12, 13)
GO

/****** Table  [dbo].[Unit]  ******/

INSERT [dbo].[Unit] ([UnitID], [NAME], [SHORT], [DECIMAL], [Unit]) VALUES (1, N'Torque', N'T       ', 2, N'Nm')
GO
INSERT [dbo].[Unit] ([UnitID], [NAME], [SHORT], [DECIMAL], [Unit]) VALUES (2, N'Angle', N'A       ', 1, N'Deg')
GO
INSERT [dbo].[Unit] ([UnitID], [NAME], [SHORT], [DECIMAL], [Unit]) VALUES (3, N'TMin', N'T-      ', 2, N'Nm')
GO
INSERT [dbo].[Unit] ([UnitID], [NAME], [SHORT], [DECIMAL], [Unit]) VALUES (4, N'TMax', N'T+      ', 2, N'Nm')
GO
INSERT [dbo].[Unit] ([UnitID], [NAME], [SHORT], [DECIMAL], [Unit]) VALUES (5, N'AMin', N'A-      ', 1, N'Deg')
GO
INSERT [dbo].[Unit] ([UnitID], [NAME], [SHORT], [DECIMAL], [Unit]) VALUES (6, N'AMax', N'A+      ', 1, N'Deg')
GO
INSERT [dbo].[Unit] ([UnitID], [NAME], [SHORT], [DECIMAL], [Unit]) VALUES (7, N'Length', N'L       ', 2, N'mm')
GO
INSERT [dbo].[Unit] ([UnitID], [NAME], [SHORT], [DECIMAL], [Unit]) VALUES (8, N'Pressure', N'Pr      ', 3, N'Pa')
GO
INSERT [dbo].[Unit] ([UnitID], [NAME], [SHORT], [DECIMAL], [Unit]) VALUES (9, N'Temperature', N'Temp    ', 1, N'°C')
GO
INSERT [dbo].[Unit] ([UnitID], [NAME], [SHORT], [DECIMAL], [Unit]) VALUES (10, N'Area', N'Ar      ', 2, N'm2')
GO
INSERT [dbo].[Unit] ([UnitID], [NAME], [SHORT], [DECIMAL], [Unit]) VALUES (11, N'Speed', N'Speed   ', 1, N'Km/h')
GO
INSERT [dbo].[Unit] ([UnitID], [NAME], [SHORT], [DECIMAL], [Unit]) VALUES (12, N'Resistence', N'R       ', 4, N'Om')
GO
INSERT [dbo].[Unit] ([UnitID], [NAME], [SHORT], [DECIMAL], [Unit]) VALUES (13, N'Height', N'H       ', 1, N'sm')
GO
/****** -----------------------------------------------------------------------------------------******/
DECLARE @DBName varchar(256) = (SELECT DB_NAME())
PRINT CONCAT ( @DBName,'--> job completed: fill out TABLES')
GO
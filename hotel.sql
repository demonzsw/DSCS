USE [hotel]
GO

CREATE DATABASE [hotel]

CREATE TABLE [dbo].[member](
	[m_id] [int] NOT NULL primary key,
	[m_name] [varchar](50) NOT NULL,
	[sex] [varchar](1) NOT NULL,
	[credential_type] [varchar](20) NOT NULL,
	[creadential_no] [varchar](20) NOT NULL,
	[m_tel] [varchar](11) NOT NULL,
	[address] [varchar](50) NULL,
	CONSTRAINT CK_sex1 CHECK (sex='男' OR sex='女'),
) 
GO

CREATE TABLE [dbo].[customertype](
	[customer_type_id] [int] NOT NULL primary key,
	[customer_type] [varchar](10) NOT NULL,
	[discount] [float] NOT NULL,
)
GO

CREATE TABLE [dbo].[roomtype](
	[type_id] [int] NOT NULL primary key,
	[type] [varchar](10) NOT NULL,
	[bed_num] [int] NOT NULL,
	[price] [float] NOT NULL,
	[foregift] [float] NOT NULL,
	[cl_room] [varchar](1) NOT NULL,
	[cl_price] [float] NOT NULL,
	CONSTRAINT CK_cl_room CHECK (cl_room='是' OR cl_room='否'),
)
GO

CREATE TABLE [dbo].[roominfo](
	[room_id] [int] NOT NULL primary key,
	[type_id] [int] NOT NULL,
	[state] [varchar](2) NOT NULL,
	[statetime] [varchar](30) NOT NULL,
	[remark] [varchar](50) NOT NULL,
	foreign key([type_id]) references [dbo].[roomtype](type_id),
	CONSTRAINT CK_state CHECK (state='空闲' OR state='入住'),
)
GO

CREATE TABLE [dbo].[customer](
	[customer_id] [int] NOT NULL primary key,
	[customer_type_id] [int] NOT NULL,
	[sex] [varchar](1) NOT NULL,
	[credential_type] [varchar](20) NOT NULL,
	[credential_no] [varchar](20) NOT NULL,
	foreign key([customer_type_id]) references [dbo].[customertype](customer_type_id),
	CONSTRAINT CK_sex2 CHECK (sex='男' OR sex='女'),
)
GO

CREATE TABLE [dbo].[livein](
	[in_no] [int] NOT NULL primary key,
	[room_id] [int] NOT NULL,
	[customer_id] [varchar](50) NOT NULL,
	[person_num] [int] NOT NULL,
	[in_time] [datetime] NOT NULL,
	[money] [float] NOT NULL,
	[days] [int] NOT NULL,
	foreign key([room_id]) references [dbo].[roominfo](room_id),
)
GO

CREATE TABLE [dbo].[checkout](
	[chk_no] [int] NOT NULL primary key,
	[in_no] [int] NOT NULL,
	[chk_time] [datetime] NOT NULL,
	[days] [int] NOT NULL,
	[money] [float] NOT NULL,
	foreign key([in_no]) references [dbo].[livein](in_no),
)


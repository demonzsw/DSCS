USE [hotel]
GO

--删除已存在表
if exists(select * from sysobjects where name = 'hotelinfo') drop table hotelinfo;
if exists(select * from sysobjects where name = 'member') drop table member;
if exists(select * from sysobjects where name = 'checkout') drop table checkout;
if exists(select * from sysobjects where name = 'livein') drop table livein;
if exists(select * from sysobjects where name = 'operator') drop table operator;
if exists(select * from sysobjects where name = 'customer') drop table customer;
if exists(select * from sysobjects where name = 'customertype') drop table customertype;
if exists(select * from sysobjects where name = 'roominfo') drop table roominfo;
if exists(select * from sysobjects where name = 'roomtype') drop table roomtype;

--创建会员表
CREATE TABLE [dbo].[member](
	[m_id] [int] primary key IDENTITY,
	[m_name] [varchar](20) NOT NULL,
	[sex] [varchar](2) NOT NULL,
	[credential_no] [varchar](20) NOT NULL,		--证件号
	[m_tel] [varchar](11) NOT NULL,
	[address] [varchar](50) NULL,
	[discount] [float] NOT NULL,
	CONSTRAINT CK_sex1 CHECK (sex='男' OR sex='女'),
) 
GO

--创建顾客类型表
CREATE TABLE [dbo].[customertype](
	[type_id] [int] NOT NULL primary key,			--0,1
	[type] [varchar](10) NOT NULL,					--普通，会员
)
GO

--创建房间类型表
CREATE TABLE [dbo].[roomtype](
	[type_id] [int] NOT NULL primary key,	--1,2,3
	[type] [varchar](15) NOT NULL,			--标准间，长包房，双人房(一张双人床)
	[bed_num] [int] NOT NULL,
	[price] [float] NOT NULL,
	[foregift] [float] NOT NULL,			--租金
)
GO

--创建房间信息表
CREATE TABLE [dbo].[roominfo](
	[room_id] [int] primary key IDENTITY,
	[type_id] [int] NOT NULL,
	[state] [varchar](4) NOT NULL,
	[remark] [varchar](50) NULL,			--备注，可为空
	foreign key([type_id]) references [dbo].[roomtype](type_id),
	CONSTRAINT CK_state CHECK (state='空闲' OR state='入住'),
)
GO

--创建顾客表
CREATE TABLE [dbo].[customer](
	[customer_id] [int] primary key IDENTITY,
	[type_id] [int] default 0 NOT NULL,
	[customer_name] [varchar](20) NOT NULL,
	[sex] [varchar](2) NOT NULL,
	[credential_no] [varchar](20) NOT NULL,
	foreign key([type_id]) references [dbo].[customertype](type_id),
	CONSTRAINT CK_sex2 CHECK (sex='男' OR sex='女'),
)
GO

--创建操作员表
CREATE TABLE [dbo].[operator](
	[operator_id] [int] primary key IDENTITY,
	[operator_name] varchar(20)	NOT NULL,
	[pwd] [varchar](15) NOT NULL,
)
GO

--创建入住信息表
CREATE TABLE [dbo].[livein](
	[in_no] [int] primary key IDENTITY,
	[room_id] [int] NOT NULL,
	[customer_id] [varchar](50) NOT NULL,
	[person_num] [int] NOT NULL,
	[in_time] [datetime] NOT NULL,			--入住时间
	[days] [int] NOT NULL,					--预计住房时间
	[operator_id] [int] NOT NULL,
	foreign key([room_id]) references [dbo].[roominfo](room_id),
	foreign key([operator_id]) references [dbo].[operator](operator_id),
)
GO

--创建结算表
CREATE TABLE [dbo].[checkout](
	[chk_no] [int] primary key IDENTITY, 
	[in_no] [int] NOT NULL,					
	[chk_time] [datetime] NOT NULL,			--结算时间
	[days] [int] default 0 NOT NULL,
	[money] [float] default 0 NOT NULL,
	[operator_id] [int] NOT NULL,
	foreign key([in_no]) references [dbo].[livein](in_no),
	foreign key([operator_id]) references [dbo].[operator](operator_id),
)
GO

--创建酒店信息总览表
CREATE TABLE [dbo].[hotelinfo](
	[room_num] [int] NOT NULL,
	[vacant_room_num] [int] NOT NULL,
	[standard_room_num] [int] NOT NULL,
	[vacant_standard_room_num] [int] NOT NULL,
	[permanent_room_num] [int] NOt NULL,
	[vacant_permanent_room_num] [int] NOt NULL,
	[double_bed_room_num] [int] NOT NULL,
	[vacant_double_bed_room_num] [int] NOT NULL,
	[current_person_num] [int] NOT NULL,
	[occupancy] [float] NOT NULL,
)
GO

--添加数据

--存储过程
--查看满足条件的空房间信息
if exists(select * from sysobjects where type='p' and name='proc_find_room') drop PROCEDURE proc_find_room;
GO
CREATE PROCEDURE proc_find_room
	@typeId int
	AS
SELECT * from roominfo
WHERE type_id = @typeId and state = '空闲'
GO

--查看顾客是否为会员
if exists(select * from sysobjects where type='p' and name='proc_is_member') drop PROCEDURE proc_is_member;
GO
CREATE PROCEDURE proc_is_member
	@credentialNo char,
	@isMember int OUTPUT
	AS
SELECT @ismember = count(*) from member
where credential_no = @credentialNo
GO

--查看房间价钱
if exists(select * from sysobjects where type='p' and name='proc_room_price') drop PROCEDURE proc_room_price;
GO
CREATE PROCEDURE proc_room_price
	@price float OUTPUT,
	@roomId int
	AS
select @price = price from roomtype rt,roominfo ri
where ri.type_id = rt.type_id and ri.room_id = @roomid
GO

--触发器
--创建customer insert触发器
if exists(select * from sysobjects where type='tr' and name='trig_customer_insert') drop trigger trig_customer_insert;
GO
create trigger trig_customer_insert
 on customer
 after insert
 as
 begin
	declare @perNum int;
	declare @customerId int;
	declare @typeId int;
	declare @credentialNo char;
	select @customerId = customer_id,@credentialNo = credential_no from inserted;
	EXEC proc_is_member @credentialNo,@typeId OUTPUT;
	select @perNum = COUNT(*) from customer;
	update hotelinfo set current_person_num = @perNum;
	update customer set type_id = @typeId;  
 end;
GO

--创建customer delete触发器
if exists(select * from sysobjects where type='tr' and name='trig_customer_delete') drop trigger trig_customer_delete;
GO
create trigger trig_customer_delete
 on customer
 after delete
 as
 begin
	declare @perNum int;
	select @perNum = COUNT(*) from customer;
	update hotelinfo set current_person_num = @perNum;
 end;
GO

--创建roominfo insert,delete触发器
if exists(select * from sysobjects where type='tr' and name='trig_roominfo_insert-delete') drop trigger trig_roominfo_insert_delete;
GO
create trigger trig_roominfo_insert_delete
 on roominfo
 after insert,delete
 as
 begin
	declare @roomNum int;
	declare @vacantRoomNum int;
	declare @standardRoomNum int;
	declare @vacantStandardRoomNum int;
	declare @permanentRoomNum int;
	declare @vacantPermanentRoomNum int;
	declare @doubleBedRoomNum int;
	declare @vacantDoubleBedRoomNum int;
	select @roomNum = COUNT(*) from roominfo;
	update hotelinfo set room_num = @roomNum;
	select @vacantRoomNum = COUNT(*) from roominfo where state = '空闲';
	update hotelinfo set vacant_room_num = @vacantRoomNum;
	select @standardRoomNum = COUNT(*) from roominfo where type_id = 1;
	update hotelinfo set standard_room_num = @standardRoomNum;
	select @vacantStandardRoomNum = COUNT(*) from roominfo where type_id = 1 and state = '空闲';
	update hotelinfo set vacant_standard_room_num = @vacantStandardRoomNum;
	select @permanentRoomNum = COUNT(*) from roominfo where type_id = 2;
	update hotelinfo set permanent_room_num = @permanentRoomNum;
	select @vacantPermanentRoomNum = COUNT(*) from roominfo where type_id = 2 and state = '空闲';
	update hotelinfo set vacant_permanent_room_num = @vacantPermanentRoomNum;
	select @doubleBedRoomNum = COUNT(*) from roominfo where type_id = 3;
	update hotelinfo set double_bed_room_num = @doubleBedRoomNum;
	select @vacantDoubleBedRoomNum = COUNT(*) from roominfo where type_id = 3 and state = '空闲';
	update hotelinfo set vacant_double_bed_room_num = @vacantDoubleBedRoomNum;
 end;
GO

--创建livein insert触发器
if exists(select * from sysobjects where type='tr' and name='trig_livein_insert') drop trigger trig_livein_insert;
GO
create trigger trig_livein_insert
 on livein
 after insert
 as
 begin
 	declare @roomId int;
	declare @occupancy float;
	declare @roomNum int;
	declare @liveInRoomNum int;
	select @roomId = room_id from inserted;
	select @roomNum = room_num from hotelinfo;
	select @liveInRoomNum = COUNT(*) from livein;
	select @occupancy = (@liveInRoomNum+0.0) / @roomNum;
	update hotelinfo set occupancy = @occupancy;
	update roominfo set state = '入住' where room_id = @roomId;
 end;
Go

--创建checkout insert触发器
if exists(select * from sysobjects where type='tr' and name='trig_checkout_insert') drop trigger trig_checkout_insert;
GO
CREATE TRIGGER trig_checkout_insert
 on checkout
 after INSERT
 as
 BEGIN
	DECLARE @chkNo int;
	DECLARE @roomId int;
	DECLARE @inNo int;
	DECLARE @days int;
	DECLARE @inTime DATETIME;
	DECLARE @chkTime DATETIME;
	SELECT @chkNo = chk_no,@inNo = in_no,@chkTime = chk_time from inserted;
	SELECT @roomId = room_id,@inTime = in_time from livein where in_no = @inNO;
	SELECT @days = datediff(day,@inTime,@chkTime);
	UPDATE roominfo set state = '空闲' where room_id = @roomId;
	UPDATE checkout set days = @days where chk_no = @chkNo;
 END;
GO

--创建结算总视图
if exists(select * from sysobjects where name='check_view') DROP view check_view;
GO
CREATE VIEW check_view AS
SELECT rt.type,rt.bed_num,rt.price,rt.foregift,l.person_num,l.in_time,c.chk_time,l.days as days1,c.days as days2,
c.money,l.operator_id as livein_operator_id,c.operator_id as checkout_operator_id
from roomtype rt,roominfo ri,livein l,checkout c
where c.in_no = l.in_no and l.room_id = ri.room_id and ri.type_id = rt.type_id
GO

--创建会员索引
if exists(select * from sysobjects where name='index_member') DROP index index_member on member;
GO
CREATE index index_member on member(m_id)
GO

--创建房间索引
if exists(select * from sysobjects where name='index_room') DROP index index_room on roominfo;
GO
CREATE INDEX index_room on roominfo(room_id)
GO

--创建顾客索引
if exists(select * from sysobjects where name='index_customer') DROP index index_customer on customer;
GO
CREATE INDEX index_customer on customer(type_id desc);
GO
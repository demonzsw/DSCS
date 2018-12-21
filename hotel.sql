USE [hotel]
GO

--ɾ���Ѵ��ڱ�
if exists(select * from sysobjects where name = 'hotelinfo') drop table hotelinfo;
if exists(select * from sysobjects where name = 'member') drop table member;
if exists(select * from sysobjects where name = 'checkout') drop table checkout;
if exists(select * from sysobjects where name = 'livein') drop table livein;
if exists(select * from sysobjects where name = 'operator') drop table operator;
if exists(select * from sysobjects where name = 'customer') drop table customer;
if exists(select * from sysobjects where name = 'customertype') drop table customertype;
if exists(select * from sysobjects where name = 'roominfo') drop table roominfo;
if exists(select * from sysobjects where name = 'roomtype') drop table roomtype;

--������Ա��
CREATE TABLE [dbo].[member](
	[m_id] [int] primary key IDENTITY,
	[m_name] [varchar](20) NOT NULL,
	[sex] [varchar](2) NOT NULL,
	[credential_no] [varchar](20) NOT NULL,		--֤����
	[m_tel] [varchar](11) NOT NULL,
	[address] [varchar](50) NULL,
	[discount] [float] NOT NULL,
	CONSTRAINT CK_sex1 CHECK (sex='��' OR sex='Ů'),
) 
GO

--�����˿����ͱ�
CREATE TABLE [dbo].[customertype](
	[type_id] [int] NOT NULL primary key,			--0,1
	[type] [varchar](10) NOT NULL,					--��ͨ����Ա
)
GO

--�����������ͱ�
CREATE TABLE [dbo].[roomtype](
	[type_id] [int] NOT NULL primary key,	--1,2,3
	[type] [varchar](15) NOT NULL,			--��׼�䣬��������˫�˷�(һ��˫�˴�)
	[bed_num] [int] NOT NULL,
	[price] [float] NOT NULL,
	[foregift] [float] NOT NULL,			--���
)
GO

--����������Ϣ��
CREATE TABLE [dbo].[roominfo](
	[room_id] [int] primary key IDENTITY,
	[type_id] [int] NOT NULL,
	[state] [varchar](4) NOT NULL,
	[remark] [varchar](50) NULL,			--��ע����Ϊ��
	foreign key([type_id]) references [dbo].[roomtype](type_id),
	CONSTRAINT CK_state CHECK (state='����' OR state='��ס'),
)
GO

--�����˿ͱ�
CREATE TABLE [dbo].[customer](
	[customer_id] [int] primary key IDENTITY,
	[type_id] [int] default(0) NOT NULL,
	[customer_name] [varchar](20) NOT NULL,
	[sex] [varchar](2) NOT NULL,
	[credential_no] [varchar](20) NOT NULL,
	foreign key([type_id]) references [dbo].[customertype](type_id),
	CONSTRAINT CK_sex2 CHECK (sex='��' OR sex='Ů'),
)
GO

--��������Ա��
CREATE TABLE [dbo].[operator](
	[operator_id] [int] primary key IDENTITY,
	[operator_name] varchar(20)	NOT NULL,
	[pwd] [varchar](15) NOT NULL,
)
GO

--������ס��Ϣ��
CREATE TABLE [dbo].[livein](
	[in_no] [int] primary key IDENTITY,
	[room_id] [int] NOT NULL,
	[customer_id] [varchar](50) NOT NULL,
	[person_num] [int] NOT NULL,
	[in_time] [datetime] NOT NULL,			--��סʱ��
	[days] [int] NOT NULL,					--Ԥ��ס��ʱ��
	[operator_id] [int] NOT NULL,
	foreign key([room_id]) references [dbo].[roominfo](room_id),
	foreign key([operator_id]) references [dbo].[operator](operator_id),
)
GO

--���������
CREATE TABLE [dbo].[checkout](
	[chk_no] [int] primary key IDENTITY, 
	[in_no] [int] NOT NULL,					
	[chk_time] [datetime] NOT NULL,			--����ʱ��
	[days] [int] default(0) NOT NULL,
	[money] [float] default(0) NOT NULL,
	[operator_id] [int] NOT NULL,
	foreign key([in_no]) references [dbo].[livein](in_no),
	foreign key([operator_id]) references [dbo].[operator](operator_id),
)
GO

--�����Ƶ���Ϣ������
CREATE TABLE [dbo].[hotelinfo](
	[id] [int] primary key,
	[room_num] [int] default(0),
	[vacant_room_num] [int] default(0),
	[standard_room_num] [int] default(0),
	[vacant_standard_room_num] [int] default(0),
	[permanent_room_num] [int] default(0),
	[vacant_permanent_room_num] [int] default(0),
	[double_bed_room_num] [int] default(0),
	[vacant_double_bed_room_num] [int] default(0),
	[current_person_num] [int] default(0),
	[occupancy] [float] default(0),
)
GO

--�洢����
--�鿴���������Ŀշ�����Ϣ
if exists(select * from sysobjects where type='p' and name='proc_find_room') drop PROCEDURE proc_find_room;
GO
CREATE PROCEDURE proc_find_room
	@typeId int
	AS
SELECT * from roominfo
WHERE type_id = @typeId and state = '����'
GO

--�鿴�˿��Ƿ�Ϊ��Ա
if exists(select * from sysobjects where type='p' and name='proc_is_member') drop PROCEDURE proc_is_member;
GO
CREATE PROCEDURE proc_is_member
	@credentialNo char,
	@isMember int OUTPUT
	AS
SELECT @ismember = count(*) from member
where credential_no = @credentialNo
GO

--�鿴�����Ǯ
if exists(select * from sysobjects where type='p' and name='proc_room_price') drop PROCEDURE proc_room_price;
GO
CREATE PROCEDURE proc_room_price
	@price float OUTPUT,
	@roomId int
	AS
select @price = price from roomtype rt,roominfo ri
where ri.type_id = rt.type_id and ri.room_id = @roomid
GO

--������
--����customer insert������
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

--����customer delete������
if exists(select * from sysobjects where type='tr' and name='trig_customer_delete') drop trigger trig_customer_delete;
GO
create trigger trig_customer_delete
 on customer
 after delete
 as
 begin
	declare @perNum int;
	select @perNum = COUNT(*) from customer;
	update hotelinfo set current_person_num = @perNum where id = 1;
 end;
GO

--����roominfo insert,delete������
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
	select @vacantRoomNum = COUNT(*) from roominfo where state = '����';
	update hotelinfo set vacant_room_num = @vacantRoomNum where id = 1;
	select @standardRoomNum = COUNT(*) from roominfo where type_id = 1;
	update hotelinfo set standard_room_num = @standardRoomNum where id = 1;
	select @vacantStandardRoomNum = COUNT(*) from roominfo where type_id = 1 and state = '����';
	update hotelinfo set vacant_standard_room_num = @vacantStandardRoomNum where id = 1;
	select @permanentRoomNum = COUNT(*) from roominfo where type_id = 2;
	update hotelinfo set permanent_room_num = @permanentRoomNum where id = 1;
	select @vacantPermanentRoomNum = COUNT(*) from roominfo where type_id = 2 and state = '����';
	update hotelinfo set vacant_permanent_room_num = @vacantPermanentRoomNum where id = 1;
	select @doubleBedRoomNum = COUNT(*) from roominfo where type_id = 3;
	update hotelinfo set double_bed_room_num = @doubleBedRoomNum where id = 1;
	select @vacantDoubleBedRoomNum = COUNT(*) from roominfo where type_id = 3 and state = '����';
	update hotelinfo set vacant_double_bed_room_num = @vacantDoubleBedRoomNum where id = 1;
 end;
GO

--����livein insert������
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
	update hotelinfo set occupancy = @occupancy where id = 1;
	update roominfo set state = '��ס' where room_id = @roomId;
 end;
Go

--����checkout insert������
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
	UPDATE roominfo set state = '����' where room_id = @roomId;
	UPDATE checkout set days = @days where chk_no = @chkNo;
 END;
GO

--������������ͼ
if exists(select * from sysobjects where name='check_view') DROP view check_view;
GO
CREATE VIEW check_view AS
SELECT rt.type,rt.bed_num,rt.price,rt.foregift,l.person_num,l.in_time,c.chk_time,l.days as days1,c.days as days2,
c.money,l.operator_id as livein_operator_id,c.operator_id as checkout_operator_id
from roomtype rt,roominfo ri,livein l,checkout c
where c.in_no = l.in_no and l.room_id = ri.room_id and ri.type_id = rt.type_id
GO

--������Ա����
if exists(select * from sysobjects where name='index_member') DROP index index_member on member;
GO
CREATE index index_member on member(m_id)
GO

--������������
if exists(select * from sysobjects where name='index_room') DROP index index_room on roominfo;
GO
CREATE INDEX index_room on roominfo(room_id)
GO

--�����˿�����
if exists(select * from sysobjects where name='index_customer') DROP index index_customer on customer;
GO
CREATE INDEX index_customer on customer(type_id desc);
GO

--�������
--insert into hotelinfo(id) values(1);
--insert into roomtype values (1,'��׼��',2,180,100);
--insert into roominfo(type_id,state) values (1,'����');
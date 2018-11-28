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
	[m_id] [int] NOT NULL primary key,
	[m_name] [varchar](20) NOT NULL,
	[sex] [varchar](1) NOT NULL,
	[credential_type] [varchar](20) NOT NULL,		--֤������
	[creadential_no] [varchar](20) NOT NULL,		--֤����
	[m_tel] [varchar](11) NOT NULL,
	[address] [varchar](50) NULL,
	CONSTRAINT CK_sex1 CHECK (sex='��' OR sex='Ů'),
) 
GO

--�����˿����ͱ�
CREATE TABLE [dbo].[customertype](
	[type_id] [int] NOT NULL primary key,			--1,2
	[type] [varchar](10) NOT NULL,					--��ͨ����Ա
	[discount] [float] NOT NULL,
)
GO

--�����������ͱ�
CREATE TABLE [dbo].[roomtype](
	[type_id] [int] NOT NULL primary key,	--1,2,3
	[type] [varchar](10) NOT NULL,			--��׼�䣬��������˫�˷�(һ��˫�˴�)
	[bed_num] [int] NOT NULL,
	[price] [float] NOT NULL,
	[foregift] [float] NOT NULL,			--���
	[cl_room] [varchar](1) NOT NULL,		--�Ƿ�Ϊ�ӵ㷿
	[cl_price] [float] NULL,
	CONSTRAINT CK_cl_room CHECK (cl_room='��' OR cl_room='��'),
)
GO

--����������Ϣ��
CREATE TABLE [dbo].[roominfo](
	[room_id] [int] NOT NULL primary key,
	[type_id] [int] NOT NULL,
	[state] [varchar](2) NOT NULL,
	[statetime] [varchar](30) NULL,			--״̬ά��ʱ��
	[remark] [varchar](50) NULL,			--��ע����Ϊ��
	foreign key([type_id]) references [dbo].[roomtype](type_id),
	CONSTRAINT CK_state CHECK (state='����' OR state='��ס'),
)
GO

--�����˿ͱ�
CREATE TABLE [dbo].[customer](
	[customer_id] [int] NOT NULL primary key,
	[type_id] [int] NOT NULL,
	[customer_name] [varchar](20) NOT NULL,
	[sex] [varchar](1) NOT NULL,
	[credential_type] [varchar](20) NOT NULL,
	[credential_no] [varchar](20) NOT NULL,
	foreign key([type_id]) references [dbo].[customertype](type_id),
	CONSTRAINT CK_sex2 CHECK (sex='��' OR sex='Ů'),
)
GO

--��������Ա��
CREATE TABLE [dbo].[operator](
	[operator_id] [int] NOT NULL primary key,
	[operator_name] varchar(20)	NOT NULL,
	[pwd] [varchar](10) NOT NULL,
)
GO

--������ס��Ϣ��
CREATE TABLE [dbo].[livein](
	[in_no] [int] NOT NULL primary key,
	[room_id] [int] NOT NULL,
	[customer_id] [varchar](50) NOT NULL,
	[person_num] [int] NOT NULL,
	[in_time] [datetime] NOT NULL,			--��סʱ��
	[money] [float] NOT NULL,
	[days] [int] NOT NULL,					--Ԥ��ס��ʱ��
	[operator_id] [int] NOT NULL,
	foreign key([room_id]) references [dbo].[roominfo](room_id),
	foreign key([operator_id]) references [dbo].[operator](operator_id),
)
GO

--���������
CREATE TABLE [dbo].[checkout](
	[chk_no] [int] NOT NULL primary key,
	[in_no] [int] NOT NULL,					
	[chk_time] [datetime] NOT NULL,			--����ʱ��
	[days] [int] NOT NULL,
	[money] [float] NOT NULL,
	[operator_id] [int] NOT NULL,
	foreign key([in_no]) references [dbo].[livein](in_no),
	foreign key([operator_id]) references [dbo].[operator](operator_id),
)
GO

--�����Ƶ���Ϣ������
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
	[total_num] [int] NOT NULL,
	[occupancy] [float] NOT NULL,
)
GO

--����customer insert������
if exists(select * from sysobjects where type='tr' and name='trig_customer_insert') drop trigger trig_customer_insert;
GO
create trigger trig_customer_insert
 on customer
 after insert
 as
 begin
	declare @perNum int;
	select @perNum = COUNT(*) from customer;
	update hotelinfo set current_person_num = @perNum;
	update hotelinfo set total_num = @perNum;
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
	update hotelinfo set current_person_num = @perNum;
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
	update hotelinfo set vacant_room_num = @vacantRoomNum;
	select @standardRoomNum = COUNT(*) from roominfo where type_id = 1;
	update hotelinfo set standard_room_num = @standardRoomNum;
	select @vacantStandardRoomNum = COUNT(*) from roominfo where type_id = 1 and state = '����';
	update hotelinfo set vacant_standard_room_num = @vacantStandardRoomNum;
	select @permanentRoomNum = COUNT(*) from roominfo where type_id = 2;
	update hotelinfo set permanent_room_num = @permanentRoomNum;
	select @vacantPermanentRoomNum = COUNT(*) from roominfo where type_id = 2 and state = '����';
	update hotelinfo set vacant_permanent_room_num = @vacantPermanentRoomNum;
	select @doubleBedRoomNum = COUNT(*) from roominfo where type_id = 3;
	update hotelinfo set double_bed_room_num = @doubleBedRoomNum;
	select @vacantDoubleBedRoomNum = COUNT(*) from roominfo where type_id = 3 and state = '����';
	update hotelinfo set vacant_double_bed_room_num = @vacantDoubleBedRoomNum;
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
	declare @occupancy float;
	declare @roomNum int;
	declare @liveInRoomNum int;
	select @roomNum = room_num from hotelinfo;
	select @liveInRoomNum = COUNT(*) from livein;
	select @occupancy = (@liveInRoomNum+0.0) / @roomNum;
	update hotelinfo set occupancy = @occupancy;
 end;
Go

--�������
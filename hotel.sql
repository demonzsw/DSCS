USE [hotel]
GO

--ɾ���Ѵ��ڱ�
if exists(select * from sysobjects where name = 'hotelinfo') drop table hotelinfo;
if exists(select * from sysobjects where name = 'member') drop table member;
if exists(select * from sysobjects where name = 'checkout') drop table checkout;
if exists(select * from sysobjects where name = 'livein') drop table livein;
if exists(select * from sysobjects where name = 'operator') drop table operator;
if exists(select * from sysobjects where name = 'customer') drop table customer;
if exists(select * from sysobjects where name = 'membertype') drop table membertype;
if exists(select * from sysobjects where name = 'roominfo') drop table roominfo;
if exists(select * from sysobjects where name = 'roomtype') drop table roomtype;

--������Ա���ͱ�
CREATE TABLE [dbo].[membertype](
	[type_id] [int] primary key IDENTITY(0,1),
	[member_type] [varchar](20) NOT NULL,
	[discount] [float] NOT NULL,
)
GO

--������Ա��
CREATE TABLE [dbo].[member](
	[m_id] [int] primary key IDENTITY,
	[m_name] [varchar](20) NOT NULL,
	[type_id] [int] NOT NULL,
	[sex] [varchar](2) NOT NULL,
	[credential_no] int NOT NULL,		--֤����
	[m_tel] [varchar](11) NOT NULL,
	[address] [varchar](50) NULL,
	FOREIGN KEY(type_id) REFERENCES [dbo].[membertype](type_id),
	CONSTRAINT CK_sex1 CHECK (sex='��' OR sex='Ů'),
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
	[state] [varchar](4) default '����',
	[remark] [varchar](50) NULL,			--��ע����Ϊ��
	foreign key([type_id]) references [dbo].[roomtype](type_id),
	CONSTRAINT CK_state CHECK (state='����' OR state='��ס'),
)
GO

--�����˿ͱ�
CREATE TABLE [dbo].[customer](
	[customer_id] [int] primary key IDENTITY,
	[type_id] [int] default(0),
	[customer_name] [varchar](20) NOT NULL,
	[sex] [varchar](2) NOT NULL,
	[credential_no] int NOT NULL,
	foreign key([type_id]) references [dbo].[membertype](type_id),
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
	[customer_id] [int] NOT NULL,
	[person_num] [int] NOT NULL,
	[in_time] [datetime] NULL,			--��סʱ��
	[days] [int] NOT NULL,					--Ԥ��ס��ʱ��
	[operator_id] [int] NOT NULL,
	foreign key([room_id]) references [dbo].[roominfo](room_id),
	foreign key([operator_id]) references [dbo].[operator](operator_id),
	FOREIGN key(customer_id) REFERENCES customer(customer_id),
)
GO

--���������
CREATE TABLE [dbo].[checkout](
	[chk_no] [int] primary key IDENTITY, 
	[in_no] [int] NOT NULL,					
	[chk_time] [datetime] NULL,			--����ʱ��
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

--�鿴�˿�����
if exists(select * from sysobjects where type='p' and name='proc_customer_type') drop PROCEDURE proc_customer_type;
GO
CREATE PROCEDURE proc_customer_type
	@credentialNo int,
	@typeId int OUTPUT
	AS
	declare @flag int;
	select @flag = count(*) from member where credential_no = @credentialNo;
	if(@flag<=0) select @typeId = 0;
	else select @typeId = type_id from member where credential_no = @credentialNo;
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

--��Ǯ
if exists(select * from sysobjects where type='p' and name='proc_money_cal') drop PROCEDURE proc_money_cal;
GO
CREATE PROCEDURE proc_money_cal
	@money float OUTPUT,
	@chkNo int
	AS
	declare @inNo int;
	declare @roomId int;
	declare @customerId int;
	declare @price float;
	declare @days int;
	declare @customerTypeId int;
	declare @discount float;
	select @inNo = in_no from checkout where chk_no = @chkNo;
	select @roomId = room_id,@customerId = customer_id from livein where in_no = @inNo;
	EXECUTE proc_room_price @price OUTPUT,@roomId;
	select @days = days from checkout where chk_no = @chkNo;
	select @customerTypeId = type_id from customer where customer_id = @customerId;
	if NOT EXISTS(select * from membertype where type_id = @customerTypeId) select @discount = 1;
	else select @discount = discount from membertype where type_id = @customerTypeId;
	select @money = @price * @days * @discount;
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
	declare @credentialNo int;
	select @customerId = customer_id,@credentialNo = credential_no from inserted;
	EXECUTE proc_customer_type @credentialNo,@typeId OUTPUT;
	select @perNum = COUNT(*) from customer;
	update hotelinfo set current_person_num = @perNum;
	update customer set type_id = @typeId where customer_id = @customerId;  
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
 	declare @inNo int;
 	declare @roomId int;
	declare @occupancy float;
	declare @roomNum int;
	declare @liveInRoomNum int;
	declare @inTime datetime;
	select @inTime = getdate();
	select @inNo = in_no from inserted;
	select @roomId = room_id from inserted;
	select @roomNum = room_num from hotelinfo;
	select @liveInRoomNum = COUNT(*) from livein;
	select @occupancy = (@liveInRoomNum+0.0) / @roomNum;
	update hotelinfo set occupancy = @occupancy where id = 1;
	update roominfo set state = '��ס' where room_id = @roomId;
	update livein set in_time = @inTime where in_no = @inNo;
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
	SELECT @chkTime = getdate();
	SELECT @chkNo = chk_no,@inNo = in_no from inserted;
	SELECT @roomId = room_id,@inTime = in_time from livein where in_no = @inNO;
	SELECT @days = datediff(day,@inTime,@chkTime);
	UPDATE roominfo set state = '����' where room_id = @roomId;
	UPDATE checkout set chk_time = @chkTime where chk_no = @chkNo;
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
insert into hotelinfo(id) values(1);
insert into roomtype values (1,'��׼��',2,200,100);
insert into roomtype values (2,'���˷�',1,100,50);
insert into roomtype values (3,'˫�˷�',1,150,100);
insert into roominfo(type_id) values (1);
insert into roominfo(type_id) values (1);
insert into roominfo(type_id) values (1);
insert into roominfo(type_id) values (2);
insert into roominfo(type_id) values (2);
insert into roominfo(type_id) values (3);
insert into roominfo(type_id) values (3);
insert into membertype(member_type,discount) values('�ǻ�Ա',1);
insert into membertype(member_type,discount) values('��ͨ��Ա',0.98);
insert into membertype(member_type,discount) values('��ʯ��Ա',0.9);
insert into membertype(member_type,discount) values('�׽��Ա',0.88);
insert into member(m_name,type_id,sex,credential_no,m_tel) values('����ΰ',3,'��',34198018,'123456');
insert into member(m_name,type_id,sex,credential_no,m_tel) values('���ı�',3,'��',34192133,'654321');
insert into member(m_name,type_id,sex,credential_no,m_tel) values('������',2,'��',34192318,'000001');
insert into member(m_name,type_id,sex,credential_no,m_tel) values('marry',2,'Ů',34198222,'222222');
insert into member(m_name,type_id,sex,credential_no,m_tel) values('jack',2,'��',3331018,'199999');
insert into member(m_name,type_id,sex,credential_no,m_tel) values('rose',1,'Ů',3433138,'333356');
insert into operator(operator_name,pwd) values('charles','sadhd111');
insert into operator(operator_name,pwd) values('rocks','qwer23333');
insert into customer(customer_name,sex,credential_no) values('����ΰ','��',34198018);
insert into customer(customer_name,sex,credential_no) values('���ı�','��',34192133);
insert into customer(customer_name,sex,credential_no) values('������','��',34192318);
insert into customer(customer_name,sex,credential_no) values('rose','Ů',3433138);
insert into customer(customer_name,sex,credential_no) values('amy','Ů',233333);
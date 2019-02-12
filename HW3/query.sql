--1. Довставлять в базу 5 записей используя insert в таблицу Customers или Suppliers
Insert Into [WideWorldImporters].[Sales].[Customers] (
	[CustomerID],
	[CustomerName], 
	[BillToCustomerID], 
	[CustomerCategoryID], 
	[PrimaryContactPersonID], 
	[AlternateContactPersonID], 
	[DeliveryMethodID], 
	[DeliveryCityID], 
	[PostalCityID], 
	[AccountOpenedDate], 
	[StandardDiscountPercentage],
	[IsStatementSent], 
	[IsOnCreditHold], 
	[PaymentDays], 
	[PhoneNumber], 
	[FaxNumber], 
 	[WebsiteURL],
	[DeliveryAddressLine1],
	[DeliveryPostalCode],
	[PostalAddressLine1],
	[PostalPostalCode],
	[LastEditedBy]
	)
Values 
( NEXT VALUE FOR Sequences.CustomerID, 'Alexander' , 
	1,1,1,1,1,19586,19586, GETDATE(),1,1,1,1,'1-11','1-111','www.1.com','address1','111','111','111',1),
( NEXT VALUE FOR Sequences.CustomerID, 'Aleksey' , 
	2,2,2,2,2,19587,19587, GETDATE(),2,2,2,2,'2-22','2-222','www.2.com','address2','222','222','222',1),
( NEXT VALUE FOR Sequences.CustomerID, 'Andrey' ,  
	3,3,3,3,3,19588,19588, GETDATE(),3,3,3,3,'3-33','3-333','www.3.com','address3','333','333','333',3),
( NEXT VALUE FOR Sequences.CustomerID, 'Anton' , 
	4,4,4,4,4,19589,19589, GETDATE(),4,4,4,4,'4-44','4-444','www.4.com','address4','444','444','444',4),
( NEXT VALUE FOR Sequences.CustomerID, 'Argronom' , 
	5,5,5,5,5,19585,19585, GETDATE(),5,5,5,5,'5-55','5-555','www.5.com','address5','555','555','555',5)

--2. Удалите 1 запись из Customers, которая была вами добавлена

DELETE 
from [WideWorldImporters].[Sales].[Customers]
WHERE [WideWorldImporters].[Sales].[Customers].CustomerId  in (1077)

--3. Изменить одну запись, из добавленных через UPDATE
UPDATE [WideWorldImporters].[Sales].[Customers]
SET [WideWorldImporters].[Sales].[Customers].[CustomerName] = [CustomerName] + ' - Updated'
WHERE [WideWorldImporters].[Sales].[Customers].CustomerId in (1076)


--4. Написать MERGE, который вставит запись в клиенты, если ее там нет, и изменит если она уже есть
--структура таблиц [CustomersHW3] идентична [Customer]  содержит данные из инсерта, но с парой отличных идов [CustomerID]
BEGIN TRAN

MERGE [WideWorldImporters].[Sales].[Customers] as TARGET
	USING 
		(Select 
			[CustomerID],[CustomerName],[BillToCustomerID],[CustomerCategoryID],[PrimaryContactPersonID],[AlternateContactPersonID], 
			[DeliveryMethodID],[DeliveryCityID],[PostalCityID],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent], 
			[IsOnCreditHold],[PaymentDays],[PhoneNumber],[FaxNumber],[WebsiteURL],[DeliveryAddressLine1],[DeliveryPostalCode],
			[PostalAddressLine1],[PostalPostalCode],[LastEditedBy]
		FROM [WideWorldImporters].[Sales].[CustomersHW3] 
		) as SOURCE (
			[CustomerID],[CustomerName],[BillToCustomerID],[CustomerCategoryID],[PrimaryContactPersonID],[AlternateContactPersonID],[DeliveryMethodID], 
			[DeliveryCityID],[PostalCityID],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays], 
			[PhoneNumber],[FaxNumber],[WebsiteURL],[DeliveryAddressLine1],[DeliveryPostalCode],[PostalAddressLine1],[PostalPostalCode],[LastEditedBy])
	ON (TARGET.[CustomerID] = SOURCE.[CustomerID])  --
WHEN MATCHED 
	THEN UPDATE SET TARGET.CustomerName = SOURCE.CustomerName + ' MERGE',
				    TARGET.WebsiteURL = SOURCE.WebsiteURL + ' MERGE URL'
WHEN NOT MATCHED
	THEN INSERT (
		[CustomerName], [BillToCustomerID], [CustomerCategoryID], [PrimaryContactPersonID], [AlternateContactPersonID], [DeliveryMethodID], 
		[DeliveryCityID],[PostalCityID],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays], 
		[PhoneNumber],[FaxNumber],[WebsiteURL],[DeliveryAddressLine1],[DeliveryPostalCode],[PostalAddressLine1],[PostalPostalCode],[LastEditedBy])
	VALUES (
		[CustomerName], [BillToCustomerID], [CustomerCategoryID], [PrimaryContactPersonID], [AlternateContactPersonID], [DeliveryMethodID], 
		[DeliveryCityID],[PostalCityID],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays], 
		[PhoneNumber],[FaxNumber],[WebsiteURL],[DeliveryAddressLine1],[DeliveryPostalCode],[PostalAddressLine1],[PostalPostalCode],[LastEditedBy])
OUTPUT deleted.*, $action, inserted.*;

--ROLLBACK TRAN
COMMIT TRAN
	

--5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
/* Конфигурируем сервер для отображения расширенных настроек.
EXEC sp_configure 'show advanced option', '1'; RECONFIGURE;  EXEC sp_configure; 

Разрешаем выполнять запросы из командной строки.
EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE; EXEC sp_configure; 

-t field_term 
	Specifies the field terminator. The default is \t (tab character)
-T option (trusted connection)
-w Performs the bulk copy operation using Unicode characters
-S server_name [\instance_name] 
-d database_name
bcp in | out | queryout
*/
DECLARE @query as VARCHAR(1000) = 'Select [Continent],COUNT([CountryName]) as CountyCount FROM [WideWorldImporters].[Application].[Countries] GROUP BY [Continent] Order by [Continent]'
DECLARE @bcp as VARCHAR(2000) = 'bcp "'+@query+'" queryout D:\Golikov_A_S\LearningMSSQL\CountyCount.txt -T -w -t -S DBOPER -d WideWorldImporters'
exec master..xp_cmdshell @bcp



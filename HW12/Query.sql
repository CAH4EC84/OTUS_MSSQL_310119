USE WideWorldImporters
--1) Загрузить данные из файла StockItems.xml в таблицу StockItems. Существующие записи в таблице обновить, отсутствующие добавить (искать по StockItemName).

--Считываем данные как BLOB из XML - и записываеми их в переменную типа XML
DECLARE @xmlDocument AS XML
SET @xmlDocument = (
	SELECT * FROM OPENROWSET (
		BULK 'D:\Golikov_A_S\LearningMSSQL\11_examples-188-9df3d7\StockItems.xml',
		SINGLE_BLOB
	) as X
)

-- OpenXml преобразование XML в таблицу (т.к данных мало сохраним их во временную таблицу)
IF OBJECT_ID('tempdb..#TMPStockItems') IS NOT NULL DROP TABLE tempdb..#TMPStockItems

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument



Select * INTO #TMPStockItems
	FROM (SELECT * FROM OPENXML (@docHandle,'/StockItems/Item',3) /*1 - attributes 2 - elements 3 - both*/
	--Список разбираемых полей
	WITH (
		[Name] nvarchar(100),
		[SupplierID] int ,
		[UnitPackageID] int './Package/UnitPackageID' ,
		[OuterPackageID] int './Package/OuterPackageID',
		[QuantityPerOuter] int './Package/QuantityPerOuter',
		[TypicalWeightPerUnit] decimal(18,3) './Package/TypicalWeightPerUnit',
		[LeadTimeDays] int,
		[IsChillerStock] bit,
		[TaxRate] decimal(18,3),
		[UnitPrice] decimal(18,2)
	) ) as parsedXML
EXEC sp_xml_removedocument @docHandle

/*
Select tws.*
	from #TMPStockItems tws 
	left join [Warehouse].[StockItems] ws on tws.NAME = ws.[StockItemName]
where ws.[StockItemName] is null
*/

--Upsert через Megre
MERGE INTO [Warehouse].[StockItems] as TARGET
	USING #TMPStockItems as SOURCE
	ON SOURCE.NAME = TARGET.[StockItemName]
WHEN MATCHED THEN UPDATE
	SET TARGET.[SupplierID] = SOURCE.[SupplierID],
		TARGET.[UnitPackageID] = SOURCE.[UnitPackageID],
		TARGET.[OuterPackageID] = SOURCE.[OuterPackageID],
		TARGET.[QuantityPerOuter]  = SOURCE.[QuantityPerOuter] ,
		TARGET.[TypicalWeightPerUnit] = SOURCE.[TypicalWeightPerUnit],
		TARGET.[LeadTimeDays] = SOURCE.[LeadTimeDays],
		TARGET.[IsChillerStock]  = SOURCE.[IsChillerStock] ,
		TARGET.[TaxRate] = SOURCE.[TaxRate],
		TARGET.[UnitPrice] = SOURCE.[UnitPrice]
WHEN NOT MATCHED THEN INSERT (
	[StockItemName],[SupplierID],[UnitPackageID],[OuterPackageID],
	[QuantityPerOuter],[TypicalWeightPerUnit],[LeadTimeDays],
	[IsChillerStock],[TaxRate],[UnitPrice],
	--Ключи которых нет в XML
	[LastEditedBy]
)
VALUES (
	SOURCE.[NAME],SOURCE.[SupplierID],SOURCE.[UnitPackageID],
	SOURCE.[OuterPackageID],SOURCE.[QuantityPerOuter] ,SOURCE.[TypicalWeightPerUnit],
	SOURCE.[LeadTimeDays],SOURCE.[IsChillerStock] , SOURCE.[TaxRate],SOURCE.[UnitPrice],
	1
);




--2) Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
Select top 3
	a.[StockItemName] as [@name],
	[SupplierID],
	(Select b.[UnitPackageID],b.[OuterPackageID],b.[QuantityPerOuter],b.[TypicalWeightPerUnit]
		from [Warehouse].[StockItems] b where a.[StockItemID] = b.[StockItemID]
		FOR XML PATH('Package'), TYPE
		),
	[LeadTimeDays],
	[IsChillerStock],
	[TaxRate],
	[UnitPrice]
from [Warehouse].[StockItems] a
Order by [@Name]
FOR XML PATH('Item'), ROOT('StockItems')

--Альтернативный вариант с TYPE
SELECT  StockItemName as '@Name',
	SupplierID,
	UnitPackageID as 'Package/UnitPackageID',
	OuterPackageID as 'Package/OuterPackageID',
	QuantityPerOuter as 'Package/QuantityPerOuter',
	TypicalWeightPerUnit as 'Package/TypicalWeightPerUnit',
	LeadTimeDays,
	IsChillerStock,
	TaxRate,
	UnitPrice
FROM Warehouse.StockItems FOR XML PATH('Item'), ELEMENTS, ROOT('StockItems'), TYPE;

/*
3) В таблице StockItems в колонке CustomFields есть данные в json.
Написать select для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- Range (из CustomFields)

*/
Select [StockItemID]
	,[StockItemName]
	,JSON_VALUE(CustomFields,'$.CountryOfManufacture') AS CountryOfManufacture
	,JSON_VALUE(CustomFields,'$.Range') AS Range
from [Warehouse].[StockItems] a

/*
4. Найти в StockItems строки, где есть тэг "Vintage"
Запрос написать через функции работы с JSON.
Тэги искать в поле CustomFields, а не в Tags.
*/
Select [StockItemID]
	,[StockItemName]
	,CustomFields
	,x.[value] as searchingInTagValue
from [Warehouse].[StockItems]
CROSS APPLY openjson ([Warehouse].[StockItems].CustomFields,'$.Tags') as x
where x.value = 'Vintage'


/*5. Пишем динамический PIVOT. 
По заданию из 8го занятия про CROSS APPLY и PIVOT 
Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
Название клиента
МесяцГод Количество покупок

Нужно написать запрос, который будет генерировать результаты для всех клиентов 
имя клиента указывать полностью из CustomerName
дата должна иметь формат dd.mm.yyyy например 25.12.2019
*/



/*Формируем строку*/ 
DECLARE @firmsString as nvarchar(max) = '',
		@tmp as nvarchar(max);

DECLARE _cursor CURSOR FOR (Select DISTINCT CustomerName from Sales.Customers)
OPEN _cursor
FETCH NEXT FROM _cursor INTO @tmp;
WHILE @@FETCH_STATUS = 0  
BEGIN  
       Set @firmsString = @firmsString +QUOTENAME(ISNULL(@tmp,'') )+ ','
   FETCH NEXT FROM _cursor into @tmp; 
END  
CLOSE _cursor;  
DEALLOCATE _cursor;
/*Встречаются строки с одиночной кавычкой [Wingtip Toys (Kapa'a, HI)]*/

--Set @firmsString = substring(REPLACE(@firmsString,char(39),char(39)+char(39)),1,LEN(@firmsString));
Select @firmsString
/*Формируем запрос*/


DECLARE @query as nvarchar(max);
Set @query ='Select FORMAT(PivotTable.InvDate, ''dd.MM.yyyy'' ),'
	+substring(@firmsString,1,len(@firmsString)-1) +'
	FROM (Select DISTINCT  
			CAST (DATEADD(mm,DATEDIFF(mm,0,Inv.InvoiceDate),0) as DATE) as InvDate,	
			cros.substr,COUNT(*) OVER (Partition by Inv.CustomerID,FORMAT( CAST (DATEADD(mm,DATEDIFF(mm,0,Inv.InvoiceDate),0) as DATE), ''dd.MM.yyyy'' ) ) as InvDayCount 
			from Sales.Invoices Inv 		
			CROSS APPLY (Select CustomerName as substr
						FROM Sales.Customers c where c.CustomerID = Inv.CustomerID and [CustomerCategoryID] =3 and [BuyingGroupID] is not null
						) cros	) 
			AS SourceTable PIVOT (	SUM (SourceTable.InvDayCount) 	FOR SourceTable.substr in('
	+substring(@firmsString,1,len(@firmsString)-1) + '
	) ) as PivotTable order by PivotTable.InvDate';

Select @query
exec(@query)

--Альтернативный вариант
--DECLARE @query nvarchar(MAX)
SET @query = N'
SELECT * 
FROM (
   SELECT 
       (FORMAT(DATEFROMPARTS(YEAR(i.InvoiceDate), MONTH(i.InvoiceDate), 1), ''dd.MM.yyyy'')) as InvoiceMonth,
       CustomerName,
       i.InvoiceID
   FROM Sales.Invoices as i
   JOIN Sales.Customers as c on c.CustomerID = i.CustomerID
) as tbl
PIVOT (
   COUNT(InvoiceID)
   FOR [CustomerName] IN ( '+substring(@firmsString,1,len(@firmsString)-1) +')
) as pvt
ORDER BY InvoiceMonth; '

EXEC (@query)


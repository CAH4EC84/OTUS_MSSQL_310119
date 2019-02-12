
/*
[WideWorldImporters].[Warehouse].[StockItems] ITEM
[WideWorldImporters].[Sales].[OrderLines] LINE
[WideWorldImporters].[Application].[People] PEOP
[WideWorldImporters].[Purchasing].[PurchaseOrders] ORD
[WideWorldImporters].[Application].[DeliveryMethods] DelMeth
[WideWorldImporters].[Application].[People] WORK
[WideWorldImporters].[Sales].[Orders] ORD
*/

-- 1. Все товары, в которых в название есть пометка urgent или название начинается с Animal
Select StockItemName
FROM [WideWorldImporters].[Warehouse].[StockItems]
where  StockItemName like ('%urgent%') or StockItemName like ('Animal%') 

--2. Поставщиков, у которых не было сделано ни одного заказа (потом покажем как это делать через подзапрос, сейчас сделайте через JOIN)
Select SupplierName 
FROM [WideWorldImporters].[Purchasing].[Suppliers] SUP
	LEFT JOIN [WideWorldImporters].[Purchasing].[PurchaseOrders] ORD ON SUP.SupplierID = ORD.SupplierID
WHERE ORD.SupplierID is NULL


/*3. Продажи с названием месяца, в котором была продажа, номером квартала, к которому относится продажа, 
включите также к какой трети года относится дата - каждая треть по 4 месяца, 
дата забора заказа должна быть задана, 
с ценой товара более 100$ либо количество единиц товара более 20. 
Добавьте вариант этого запроса с постраничной выборкой пропустив первую 1000 и отобразив следующие 100 записей. 
Соритровка должна быть по номеру квартала, трети года, дате продажи. 
*/

Select 
	ORD.OrderID,
	DATENAME( month,ORD.OrderDate) as [Month],
	DATEPART (quarter, ORD.OrderDate) as [Quarter], 
	((DATEPART (month , ORD.OrderDate) -1) / 4 ) + 1 as [Third] --наверняка есть что то другое 
FROM Sales.Orders ORD
	JOIN Sales.OrderLines LIN on ORD.OrderID = LIN.OrderID
WHERE (ORD.PickingCompletedWhen is not NULL) 
	and  (LIN.UnitPrice > 100 or LIN.Quantity>20)
ORDER BY DATEPART (quarter, ORD.OrderDate),((DATEPART (month , ORD.OrderDate) -1) / 4 ) + 1,ORD.OrderDate
OFFSET 1000 ROWS FETCH NEXT 100  ROWS ONLY


--4.Заказы поставщикам, которые были исполнены за 2014й год с доставкой Road Freight или Post, 
--	добавьте название поставщика, имя контактного лица принимавшего заказ

Select
	PUR.PurchaseOrderID,
	SUP.SupplierName,
	DelMeth.DeliveryMethodName,
	PEOP.FullName
FROM [WideWorldImporters].[Purchasing].[PurchaseOrders] PUR
	JOIN [WideWorldImporters].[Application].[DeliveryMethods] DelMeth on PUR.DeliveryMethodID = DelMeth.DeliveryMethodID
	JOIN [WideWorldImporters].[Purchasing].[Suppliers] SUP on Pur.SupplierID =SUP.SupplierID
	JOIN [WideWorldImporters].[Application].[People] PEOP on PUR.ContactPersonID = PEOP.PersonID
WHERE PUR.IsOrderFinalized = 1 
	and PUR.OrderDate between '20140101' and '20141231'
	and DelMeth.DeliveryMethodName in ('Road Freight','Post')


--5. 10 последних по дате продаж с именем клиента и именем сотрудника, который оформил заказ.
Select TOP (10)
	ORD.OrderDate,
	WORK.FullName as Worker,
	CUST.CustomerName as Client
FROM [WideWorldImporters].[Sales].[Orders] ORD
	JOIN [WideWorldImporters].[Application].[People] WORK on ORD.SalespersonPersonID = WORK.PersonID 
	JOIN [WideWorldImporters].[Sales].[Customers] CUST on ORD.CustomerId = CUST.CustomerID
order by OrderID desc

--6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар Chocolate frogs 250g


Select DISTINCT
    Cust.CustomerID,
	CUST.CustomerName,
	Cust.PhoneNumber
FROM [WideWorldImporters].[Sales].[Customers] CUST 
	JOIN [WideWorldImporters].[Sales].[Orders] ORD on ORD.CustomerId = CUST.CustomerID
	JOIN[WideWorldImporters].[Sales].[OrderLines] LINE on ORD.OrderID = LINE.OrderID
	JOIN [WideWorldImporters].[Warehouse].[StockItems] ITEM on LINE.StockItemID = ITEM.StockItemID
WHERE StockItemName = 'Chocolate frogs 250g'
order by CUST.CustomerName

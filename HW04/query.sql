-- Сделайте 2 варианта запросов: через вложенный запрос | через WITH (для производных таблиц) 

--1. Выберите сотрудников, которые являются продажниками, и еще не сделали ни одной продажи.
--Есть таблица Invoices а есть таблица Orders, я подозреваю что продажи фиксируются в Ордерзах.
Select FullName 
from [Application].[People]
where IsSalesperson = 1 
	and NOT EXISTS  (Select DISTINCT SalespersonPersonID FROM [Sales].Invoices)

;WITH SalersCTE (pid) as (
	Select DISTINCT  SalespersonPersonID FROM [Sales].Invoices
) 
Select FullName 
from Application.People 
where IsSalesperson=1 and PersonID not in (Select pid from SalersCTE);

--2. Выберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса. 
Select StockItemID,StockItemName,UnitPrice
from [Warehouse].[StockItems] 
where UnitPrice = (Select min(UnitPrice) from [Warehouse].[StockItems])

Select StockItemID,StockItemName,UnitPrice
from [Warehouse].[StockItems] 
where UnitPrice <=ALL (Select top (1) UnitPrice from [Warehouse].[StockItems] order by UnitPrice)

--3. Выберите всех клиентов у которых было 5 максимальных оплат из [Sales].[CustomerTransactions] представьте 3 способа (в том числе с CTE)
Select TOP 5 
	C.CustomerID,C.CustomerName,MAX(T.TransactionAmount) as MaxPayed
from Sales.Customers C join [Sales].[CustomerTransactions]  T on C.CustomerID = T.CustomerID
GROUP BY  C.CustomerID,C.CustomerName
order by MaxPayed desc

--Можно из СТЕ получить агрегированные данные.
;WITH MaxPayedCTE as (
	Select TOP 5 CustomerID,MAX(TransactionAmount) as MaxPayed
	from [Sales].[CustomerTransactions] 
	GROUP BY CustomerID
	order by MAX(TransactionAmount) desc
)
Select C.CustomerID,C.CustomerName,CTE.MaxPayed 
from Sales.Customers C join MaxPayedCTE CTE on C.CustomerID = CTE.CustomerID

--3 способ что-то туго придумывается
Select C.CustomerID,C.CustomerName
from Sales.Customers  C 
where C.CustomerID in (	Select TOP 5 CustomerID as MaxPayed
	from [Sales].[CustomerTransactions] 
	GROUP BY CustomerID
	order by MAX(TransactionAmount) desc)

--4. Выберите города (ид и название), в которые были доставлены товары входящие в тройку самых дорогих товаров,  а также Имя сотрудника, который осуществлял упаковку заказов
-- в описании задания возможно ошибка "Имя сотрудника, который осуществлял упаковку" возможно = "Имя сотрудника, который получал заказ (PickedByPersonId)"

Select DISTINCT Cities.CityID,Cities.CityName,P.FullName
from (--Покупатель и фактический получатель заказа
	Select DISTINCT CustomerID,PickedByPersonID 
	from Sales.Orders 
	where OrderID in (--Заказы содержащие 3 самые дорогие позиции
		Select OrderID  
		from Sales.OrderLines 
		where StockItemID in (--три самые дорогии позиции
			Select TOP 3 StockItemID
			from Warehouse.StockItems 
			group by StockItemID 
			order by max(UnitPrice) desc
		)
	)
) as CustomerIdPickerId 
JOIN Sales.Customers C on CustomerIdPickerId.CustomerID = C.CustomerID
JOIN Application.People P on CustomerIdPickerId.PickedByPersonID = P.PersonID
JOIN Application.Cities on C.DeliveryCityID = Cities.CityID
order by Cities.CityID

--CTE
;WITH MaxPrice as (
	Select TOP 3 StockItemID
		from Warehouse.StockItems 
		group by StockItemID 
		order by max(UnitPrice) desc
)
Select DISTINCT Cities.CityID,Cities.CityName,P.FullName
FROM Sales.OrderLines OL 
	JOIN MaxPrice on OL.StockItemID = MaxPrice.StockItemID
	JOIN Sales.Orders O on OL.OrderID = O.OrderID
	JOIN Sales.Customers C on O.CustomerID = C.CustomerID
	JOIN Application.People P on O.PickedByPersonID = P.PersonID
	JOIN Application.Cities on C.DeliveryCityID = Cities.CityID
order by Cities.CityID



--5. Объясните, что делает и оптимизируйте запрос

SELECT 
Invoices.InvoiceID,Invoices.InvoiceDate
,(SELECT People.FullName
	FROM Application.People
	WHERE People.PersonID = Invoices.SalespersonPersonID
) AS SalesPersonName
,SalesTotals.TotalSumm AS TotalSummByInvoice
,(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
	FROM Sales.OrderLines
	WHERE OrderLines.OrderId = (--Полученые заказы для которых есть накладные
		SELECT Orders.OrderId 
		FROM Sales.Orders
		WHERE Orders.PickingCompletedWhen IS NOT NULL	
		AND Orders.OrderId = Invoices.OrderId)	
) AS TotalSummForPickedItems

FROM Sales.Invoices  
JOIN (--Накладные сумма которых более 27000
	SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000
) AS SalesTotals
ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC



/*Запрос выбирает 
	Для накладных Sales.InvoiceLines по которым  (SUM(Quantity*UnitPrice) > 27000) нужно
	1) Номер накладной -> Invoices.InvoiceID
	2) Дата накладной -> Invoices.InvoiceDate
	3) Имя менеджера сделавшего продажу -> SalesPersonName (вложенный в Select )
	4) Общая сумма накладной -> TotalSummByInvoice (JOIN)
	5) Фактическая сумма ЗАБРАННЫХ (PickingCompletedWhen IS NOT NULL) позиций из заказа SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) -> TotalSummForPickedItems (вложенный в Select)

Выносим в CTE список подходящих накладных выбираем полный набор полей из Invoces + InvocesLines , что бы при первом взгляде сразу были понятны исходные данные.


;With 
InvoicesInfo (InvoiceId,OrderID,InvoiceDate,SalespersonPersonID,TotalSumm) as (
	SELECT I.InvoiceId,I.OrderID,I.InvoiceDate, I.SalespersonPersonID,SUM(L.Quantity*L.UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines L JOIN Sales.Invoices I on L.InvoiceID = I.InvoiceID
	GROUP BY I.InvoiceId,I.InvoiceDate,I.SalespersonPersonID,I.OrderID 
	HAVING SUM(Quantity*UnitPrice) > 27000),  
TotalSummForPickedItems  as (
	SELECT InvoicesInfo.orderId,SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) as TotalPickSumm
	FROM Sales.OrderLines 
	join  Sales.Orders on OrderLines.OrderID = Orders.OrderID
	join InvoicesInfo on Orders.OrderID = InvoicesInfo.orderId
	WHERE Orders.PickingCompletedWhen IS NOT NULL 
	GROUP BY InvoicesInfo.orderId
)
Select InvoicesInfo.InvoiceId,
	InvoicesInfo.InvoiceDate, 
	People.FullName,InvoicesInfo.TotalSumm AS TotalSummByInvoice,
	TotalSummForPickedItems.TotalPickSumm as TotalSummForPickedItems
from InvoicesInfo 
join Application.People on People.PersonID = InvoicesInfo.SalespersonPersonID
join TotalSummForPickedItems on TotalSummForPickedItems.OrderID = InvoicesInfo.OrderID

Быстродействие становится меньше чем исходный запрос.
Для того что бы не гонять CTE по кругу формируем временную таблицу формируем временную таблицу для наших данных из InvoicesInfo
*/


IF OBJECT_ID('tempdb..##TMP_InvoicesInfo') IS NOT NULL DROP TABLE ##TMP_InvoicesInfo

SELECT I.InvoiceId,I.OrderID,I.InvoiceDate, I.SalespersonPersonID,SUM(L.Quantity*L.UnitPrice) AS TotalSumm
	INTO ##TMP_InvoicesInfo
	FROM Sales.InvoiceLines L JOIN Sales.Invoices I on L.InvoiceID = I.InvoiceID
	GROUP BY I.InvoiceId,I.InvoiceDate,I.SalespersonPersonID,I.OrderID 
	HAVING SUM(Quantity*UnitPrice) > 27000

;With 
 TotalSummForPickedItems  as (
	SELECT InvoicesInfo.orderId,SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) as TotalPickSumm
	FROM Sales.OrderLines 
	join  Sales.Orders on OrderLines.OrderID = Orders.OrderID
	join ##TMP_InvoicesInfo InvoicesInfo on Orders.OrderID = InvoicesInfo.orderId
	WHERE Orders.PickingCompletedWhen IS NOT NULL 
	GROUP BY InvoicesInfo.orderId
)
Select InvoicesInfo.InvoiceId,
	InvoicesInfo.InvoiceDate, 
	People.FullName,InvoicesInfo.TotalSumm AS TotalSummByInvoice,
	TotalSummForPickedItems.TotalPickSumm as TotalSummForPickedItems
from  ##TMP_InvoicesInfo InvoicesInfo 
join Application.People on People.PersonID = InvoicesInfo.SalespersonPersonID
join TotalSummForPickedItems on TotalSummForPickedItems.OrderID = InvoicesInfo.OrderID
ORDER BY TotalSummByInvoice DESC




--1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Select 
 W.StockItemName,
 AVG(L.UnitPrice) as AvgPrice,
 YEAR(O.OrderDate) as OrdYEar,
 MONTH(O.OrderDate) as OrdMonth,
 SUM(L.UnitPrice * Quantity)  as TotalMonthSumm
FROM [Sales].[OrderLines] L 
	inner JOIN Sales.Orders O on  L.OrderID = O.OrderID
	inner join Warehouse.StockItems W on L.StockItemID = W.StockItemID
Group by  W.StockItemName, YEAR(O.OrderDate),MONTH(O.OrderDate)
order by  W.StockItemName,OrdYear,OrdMonth

--2. Отобразить все месяцы, где общая сумма продаж превысила 10 000  (10 000 маловато)
Select 
 YEAR(O.OrderDate) as OrdYEar,
 MONTH(O.OrderDate) as OrdMonth
 --,Sum(UnitPrice * Quantity) as TotalSumm
FROM [Sales].[OrderLines] L 
	inner JOIN Sales.Orders O on  L.OrderID = O.OrderID
GROUP BY YEAR(O.OrderDate),MONTH(O.OrderDate)
HAVING Sum(UnitPrice * Quantity)> 10000
order by OrdYear,OrdMonth

--3. Вывести сумму продаж, дату первой продажи и количество проданного по месяцам, по товарам, продажи которых менее 50 ед в месяц. (50 маловато)
Select 
	W.StockItemName,
	SUM(L.Quantity * L.UnitPrice) as TotalSumm,
	MIN(O.OrderDate) as firstSaleDate,
	SUM(Quantity) as saledQuantity,
	YEAR(O.OrderDate) as Years,
	MONTH(O.OrderDate) as Months
FROM [Sales].[OrderLines] L 
	inner JOIN Sales.Orders O on  L.OrderID = O.OrderID
	inner join Warehouse.StockItems W on L.StockItemID = W.StockItemID
GROUP BY W.StockItemName,YEAR(O.OrderDate),MONTH(O.OrderDate)
HAVING SUM(Quantity) < 50
order by W.StockItemName,Years,Months


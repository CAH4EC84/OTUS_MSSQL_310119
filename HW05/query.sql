--1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Select 
 [Description],
 AVG(UnitPrice) as AvgPrice,
 MONTH(O.OrderDate) as OrdMonth,
 SUM(UnitPrice * Quantity)  as TotalMonthSumm
FROM [Sales].[OrderLines] L 
	inner JOIN Sales.Orders O on  L.OrderID = O.OrderID
Group by  [Description],MONTH(O.OrderDate)
order by  [Description],OrdMonth


--2. Отобразить все месяцы, где общая сумма продаж превысила 10 000  (10 000 маловато)
Select 
 MONTH(O.OrderDate) as OrdMonth
 --,Sum(UnitPrice * Quantity) as TotalSumm
FROM [Sales].[OrderLines] L 
	inner JOIN Sales.Orders O on  L.OrderID = O.OrderID
GROUP BY MONTH(O.OrderDate)
HAVING Sum(UnitPrice * Quantity)> 10000
order by OrdMonth

--3. Вывести сумму продаж, дату первой продажи и количество проданного по месяцам, по товарам, продажи которых менее 50 ед в месяц. (50 маловато)
Select 
	L.[Description],
	SUM(L.Quantity * L.UnitPrice) as TotalSumm,
	MIN(O.OrderDate) as firstSaleDate,
	SUM(Quantity) as saledQuantity,
	MONTH(O.OrderDate) as Months
FROM [Sales].[OrderLines] L 
	inner JOIN Sales.Orders O on  L.OrderID = O.OrderID
GROUP BY [Description],MONTH(O.OrderDate)
HAVING SUM(Quantity) < 50
order by [Description],Months

--В задании указано по месяцам, в реальности по месяцам и годам т.к таблица содержит данные за 4 года и одинаковые месяца сгруппируются.
Select 
	L.[Description],
	SUM(L.Quantity * L.UnitPrice) as TotalSumm,
	MIN(O.OrderDate) as firstSaleDate,
	SUM(Quantity) as saledQuantity,
	MONTH(O.OrderDate) as Months,
	YEAR(O.OrderDate) as Years
FROM [Sales].[OrderLines] L 
	inner JOIN Sales.Orders O on  L.OrderID = O.OrderID
GROUP BY [Description],MONTH(O.OrderDate),YEAR(O.OrderDate) 
HAVING SUM(Quantity) < 100
order by [Description],Months,Years



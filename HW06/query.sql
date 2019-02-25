/*
1.Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки)
Выведите id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом
Пример 
Дата продажи Нарастающий итог по месяцу
2015-01-29	4801725.31
2015-01-30	4801725.31
2015-01-31	4801725.31
2015-02-01	9626342.98
2015-02-02	9626342.98
2015-02-03	9626342.98
Продажи можно взять из таблицы Invoices.
Сделать 2 варианта запроса - через windows function и без них. Написать какой быстрее выполняется, сравнить по set statistics time on;
*/

--Оконная функция
Select 
	Inv.InvoiceID,
	Cust.CustomerName,
	Inv.InvoiceDate,
	Trans.AmountExcludingTax,
	SUM(Trans.AmountExcludingTax) OVER (ORDER BY YEAR(Inv.InvoiceDate), MONTH(Inv.InvoiceDate)) as risingMonthsSumm
from Sales.Invoices Inv
	JOIN Sales.CustomerTransactions Trans on Inv.InvoiceID = Trans.InvoiceID
	JOIN Sales.Customers Cust on Inv.CustomerID = Cust.CustomerID
Where InvoiceDate >= '01.01.2015'
order by Inv.InvoiceDate

--Замечательно задание, сразу наглядно демонстрирующее удобство оконных функций.
--Как прозрачно для последущего чтения написать этот запрос с такой детализацией мне не понятно
-- наверняка есть какой-то гуд практис на сей счет и было бы класно его увидеть т.к вариант ниже имеет убийственно быстродейсвтие да и первая строчка пустой идет.

--Через CTE вычисляем сумму для 1го дня месяца и первого ида.
;WITH RisingSumm  as(
	Select 
		MIN(Inv.InvoiceID) as MonthFirstInvId,
		SUM(T.AmountExcludingTax) as MonthSum 
	FROM Sales.Invoices Inv
		JOIN Sales.CustomerTransactions as T  on Inv.InvoiceID = T.InvoiceID
	Where Inv.InvoiceDate >= '01.01.2015' 
	GROUP BY YEAR(Inv.InvoiceDate) , MONTH(Inv.InvoiceDate) 
) Select 
	Inv.InvoiceID,
	Cust.CustomerName,
	Inv.InvoiceDate,
	Trans.AmountExcludingTax,
	(Select SUM(MonthSum) from RisingSumm where  RisingSumm.MonthFirstInvId < INV.InvoiceID ) as risingMonthsSumm
from Sales.Invoices Inv
	JOIN Sales.CustomerTransactions Trans on Inv.InvoiceID = Trans.InvoiceID
	JOIN Sales.Customers Cust on Inv.CustomerID = Cust.CustomerID
Where InvoiceDate >= '01.01.2015'
order by Inv.InvoiceID,Inv.InvoiceDate

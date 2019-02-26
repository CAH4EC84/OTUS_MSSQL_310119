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



--2. Вывести список 2х самых популярных продуктов (по кол-ву проданных) 
--в каждом месяце за 2016й год (по 2 самых популярных продукта в каждом месяце)

WITH MostPupolar_CTE as (
Select TOP 100 percent
	MONTH(O.OrderDate) as [Month],
	L.StockItemID,
	SUM(L.Quantity) as TotalQ,
	ROW_NUMBER() OVER (PARTITION BY MONTH(O.OrderDate) order by  SUM(L.Quantity) desc) as SallesRank
from Sales.OrderLines L
	JOIN Sales.Orders O on L.OrderID = O.OrderID
WHERE O.OrderDate between '20160101' and '20170101'
GROUP BY MONTH(O.OrderDate),L.StockItemID
order by [Month],TotalQ desc,L.StockItemID
) 
Select * from MostPupolar_CTE where SallesRank <3


/*
3. Функции одним запросом
Посчитайте по таблице товаров, в вывод также должен попасть ид товара, название, брэнд и цена
пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
посчитайте общее количество товаров и выведете полем в этом же запросе
посчитайте общее количество товаров в зависимости от первой буквы названия товара
отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
предыдущий ид товара с тем же порядком отображения (по имени)
названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
сформируйте 30 групп товаров по полю вес товара на 1 шт
Для этой задачи НЕ нужно писать аналог без аналитических функций
*/

Select 
	Items.StockItemID,Items.StockItemName,Items.Brand,Items.UnitPrice 
	-- так чтобы при изменении буквы алфавита нумерация начиналась заново 
	-- пример неоднозначного задания (изменения первой  | любой буквы буквы ???)
	,ROW_NUMBER() OVER (PARTITION BY Items.StockItemName order by Items.StockItemName ) as AnyLetterChangeRank
	,ROW_NUMBER() OVER (PARTITION BY LEFT(Items.StockItemName,1) order by Items.StockItemName ) as FirstLetterChangeRank
	--посчитайте общее количество товаров 
	,COUNT(*) OVER() as TotalItemsCount
	--посчитайте общее количество товаров в зависимости от первой буквы названия товара
	,COUNT(*) OVER(PARTITION BY LEFT(Items.StockItemName,1)) as FirstLetterItemsCount
	--отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
	,LEAD(Items.StockItemID) OVER (ORDER BY Items.StockItemName) as NextItemId
	--предыдущий ид товара с тем же порядком отображения (по имени)
	,LAG(Items.StockItemID) OVER (ORDER BY Items.StockItemName) as PrevItemId
	--названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
	,LAG(Items.StockItemName,2,'NO ITEMS') OVER (ORDER BY Items.StockItemName) as Lag2ItemName
	--сформируйте 30 групп товаров по полю вес товара на 1 шт
	,NTILE(30) OVER (ORDER BY Items.TypicalWeightPerUnit ) as WeightGroups
from Warehouse.StockItems Items
order by Items.StockItemName

--4. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал
--В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки

Select tmp.PersonID,tmp.FullName,tmp.CustomerID,tmp.CustomerName,tmp.InvoiceDate,tmp.TransactionAmount 
from (
	Select P.PersonID,P.FullName,C.CustomerID,C.CustomerName,I.InvoiceDate,Trans.TransactionAmount
	-- Номер строки сортировка по иду счета (т.к в 1 день может бытьмного продаж), позволит выбрать последний заказ из внешнего запроса
		,ROW_NUMBER() OVER (Partition by P.PersonID order by I.InvoiceID desc ) as RowN
	FROM Sales.Invoices I 
		join Sales.Customers C on I.CustomerID = C.CustomerID
		join Application.People P on I.SalespersonPersonID = P.PersonID
		join Sales.CustomerTransactions Trans on I.InvoiceID = Trans.InvoiceID
) as tmp
where RowN = 1

--5. Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
--В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки

Select CustomerID,CustomerName,StockItemID,UnitPrice,InvoiceDate
from 
(
	Select I.CustomerID,C.CustomerName,L.StockItemID,L.UnitPrice,I.InvoiceDate
		--DENSE не пропускает ранги.
		,DENSE_RANK() OVER (PARTITION BY I.CustomerID ORDER BY L.UnitPrice  desc) as MostExpenItems
	FROM Sales.InvoiceLines L
		JOIN Sales.Invoices I on L.InvoiceID=I.InvoiceID
		JOIN Sales.Customers C on I.CustomerID = C.CustomerID
)tmp
where MostExpenItems < 3

--Bonus из предыдущей темы
--Напишите запрос, который выбирает 10 клиентов, которые сделали больше 30 заказов и последний заказ был не позднее апреля 2016.
Select DISTINCT TOP 10 
	OC.CustomerID
from Sales.Invoices I
	JOIN (
		Select DISTINCT I.CustomerID,	COUNT(I.InvoiceID) OVER (PARTITION BY I.CustomerID) as orderCount from Sales.Invoices I 
	) OC ON I.CustomerID = OC.CustomerID
--которые сделали больше 30 заказов и последний заказ был не позднее апреля 2016
Where OC.orderCount > 30 and I.InvoiceDate < '20160501' 


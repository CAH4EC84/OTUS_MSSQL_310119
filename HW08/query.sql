/*
1. Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
Название клиента
МесяцГод Количество покупок

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys
имя клиента нужно поменять так чтобы осталось только уточнение 
например исходное Tailspin Toys (Gasport, NY) - вы выводите в имени только Gasport,NY
дата должна иметь формат dd.mm.yyyy например 25.12.2019

Например, как должны выглядеть результаты:
InvoiceMonth	Peeples Valley, AZ	Medicine Lodge, KS	Gasport, NY	Sylvanite, MT	Jessie, ND
01.01.2013	3	1	4	2	2
01.02.2013	7	3	4	2	1

*/

Select FORMAT(PivotTable.InvDate, 'dd.MM.yyyy' )
	,[Sylvanite, MT],[Peeples Valley, AZ],[Medicine Lodge, KS],[Gasport, NY],[Jessie, ND]
FROM
	(Select DISTINCT  
	 CAST (DATEADD(mm,DATEDIFF(mm,0,Inv.InvoiceDate),0) as DATE) as InvDate,
		cros.substr,
		COUNT(*) OVER (Partition by Inv.CustomerID,FORMAT( CAST (DATEADD(mm,DATEDIFF(mm,0,Inv.InvoiceDate),0) as DATE), 'dd.MM.yyyy' ) ) as InvDayCount
		from Sales.Invoices Inv 
		CROSS APPLY (Select substring(CustomerName, CHARINDEX('(',CustomerName)+1,CHARINDEX(')',CustomerName) - CHARINDEX('(',CustomerName)-1 ) as substr
			FROM Sales.Customers c where c.CustomerID = Inv.CustomerID) cros
	where CustomerID  between 2 and 6  
	--order by 1
	) AS SourceTable
PIVOT (
	SUM (SourceTable.InvDayCount) 
	FOR SourceTable.substr in([Sylvanite, MT],[Peeples Valley, AZ],[Medicine Lodge, KS],[Gasport, NY],[Jessie, ND]) ) as PivotTable
order by PivotTable.InvDate


/*
2. Для всех клиентов с именем, в котором есть Tailspin Toys
вывести все адреса, которые есть в таблице в одной колоке
*/

Select CustomerName,Addr,[Goto]
FROM
	(Select CustomerName, DeliveryAddressLine1,DeliveryAddressLine2 from Sales.Customers where CustomerName like '%Tailspin Toys%' )  tmp
UNPIVOT (
	[Goto] FOR Addr in (DeliveryAddressLine1,DeliveryAddressLine2)
) as unpvt



/*
3. В таблице стран есть поля с кодом страны цифровым и буквенным
сделайте выборку ИД страны, название, код - чтобы в поле был либо цифровой либо буквенный код
Пример выдачи
CountryId	CountryName	Code
1	Afghanistan	AFG
1	Afghanistan	4
3	Albania	ALB
3	Albania	8
*/

Select CountryID,CountryName,CODE
FROM
	(Select CountryID,CountryName,CAST(IsoNumericCode as NVARCHAR(3)) as IsoNumericCode,IsoAlpha3Code from [Application].[Countries] ) tmp
UNPIVOT (
	CODE for AddrType in (IsoNumericCode,IsoAlpha3Code)
) as unpvt


/*

4. Перепишите ДЗ из оконных функций через CROSS APPLY 
Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки
*/

Select C.CustomerID,C.CustomerName, TopLines.*
from  Sales.Customers C
	CROSS APPLY (
		Select TOP 2  L.StockItemID,L.UnitPrice,I.InvoiceDate  
		from Sales.InvoiceLines L 
			JOIN Sales.Invoices I on L.InvoiceID=I.InvoiceID
		WHERE I.CustomerID = C.CustomerID
		Order by L.UnitPrice desc
	) TopLines	
order by C.CustomerID 


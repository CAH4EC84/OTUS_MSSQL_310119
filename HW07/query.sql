/*
1. Напишите запрос с временной таблицей и перепишите его с табличной переменной. Сравните планы. 
Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
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
15-01 - 4401699.25
15-02 -8597018.50
16-05 76624666.00
*/
--Временная таблица

IF OBJECT_ID('tempdb..#TabTmpRisingSumm') is NOT NULL DROP TABLE #TabTmpRisingSumm

Select --Это временная таблица 
	CAST (DATEADD(mm,DATEDIFF(mm,0,Inv.InvoiceDate),0) as DATE) as DateToJoin --Лекция 8 отличный решение с датой позволяет вывести быстродействие на уровень оконных функций
	,SUM(T.AmountExcludingTax) as MonthSum 
INTO #TabTmpRisingSumm
FROM Sales.Invoices Inv
	JOIN Sales.CustomerTransactions as T  on Inv.InvoiceID = T.InvoiceID
Where Inv.InvoiceDate >= '01.01.2015' 
GROUP BY CAST (DATEADD(mm,DATEDIFF(mm,0,Inv.InvoiceDate),0) as DATE)

Select 
	Inv.InvoiceID,
	Cust.CustomerName,
	Inv.InvoiceDate,
	Trans.AmountExcludingTax,
	SUM(RS.MonthSum) as risingMonthsSumm
from Sales.Invoices Inv
	JOIN Sales.CustomerTransactions Trans on Inv.InvoiceID = Trans.InvoiceID
	JOIN Sales.Customers Cust on Inv.CustomerID = Cust.CustomerID
	join #TabTmpRisingSumm RS on Rs.DateToJoin <= CAST (DATEADD(mm,DATEDIFF(mm,0,Inv.InvoiceDate),0) as DATE)
Where InvoiceDate >= '01.01.2015'
GROUP BY 	Inv.InvoiceID,	Cust.CustomerName,	Inv.InvoiceDate,	Inv.InvoiceDate,	Trans.AmountExcludingTax
order by Inv.InvoiceID,Inv.InvoiceDate



--Табличная переменная
DECLARE @TabVarRisingSumm as Table (
		DateToJOin DATE,
		MonthSum DECIMAL(18,2)
)
Insert INTO @TabVarRisingSumm (DateToJOin,MonthSum) --Это табличная переменная
	Select 
		CAST (DATEADD(mm,DATEDIFF(mm,0,Inv.InvoiceDate),0) as DATE) as DateToJoin 
		,SUM(T.AmountExcludingTax) as MonthSum 
	FROM Sales.Invoices Inv
		JOIN Sales.CustomerTransactions as T  on Inv.InvoiceID = T.InvoiceID
	Where Inv.InvoiceDate >= '01.01.2015' 
	GROUP BY CAST (DATEADD(mm,DATEDIFF(mm,0,Inv.InvoiceDate),0) as DATE)
 Select 
	Inv.InvoiceID,
	Cust.CustomerName,
	Inv.InvoiceDate,
	Trans.AmountExcludingTax,
	SUM(RS.MonthSum) as risingMonthsSumm
from Sales.Invoices Inv
	JOIN Sales.CustomerTransactions Trans on Inv.InvoiceID = Trans.InvoiceID
	JOIN Sales.Customers Cust on Inv.CustomerID = Cust.CustomerID
	join @TabVarRisingSumm RS on Rs.DateToJoin <= CAST (DATEADD(mm,DATEDIFF(mm,0,Inv.InvoiceDate),0) as DATE)
Where InvoiceDate >= '01.01.2015'
GROUP BY 	Inv.InvoiceID,	Cust.CustomerName,	Inv.InvoiceDate,	Inv.InvoiceDate,	Trans.AmountExcludingTax
order by Inv.InvoiceID,Inv.InvoiceDate


/*2. Написать рекурсивный CTE sql запрос и заполнить им временную таблицу и табличную переменную
CREATE TABLE dbo.MyEmployees 
( 
EmployeeID smallint NOT NULL, 
FirstName nvarchar(30) NOT NULL, 
LastName nvarchar(40) NOT NULL, 
Title nvarchar(50) NOT NULL, 
DeptID smallint NOT NULL, 
ManagerID int NULL, 
CONSTRAINT PK_EmployeeID PRIMARY KEY CLUSTERED (EmployeeID ASC) 
); 
INSERT INTO dbo.MyEmployees VALUES 
(1, N'Ken', N'Sánchez', N'Chief Executive Officer',16,NULL) 
,(273, N'Brian', N'Welcker', N'Vice President of Sales',3,1) 
,(274, N'Stephen', N'Jiang', N'North American Sales Manager',3,273) 
,(275, N'Michael', N'Blythe', N'Sales Representative',3,274) 
,(276, N'Linda', N'Mitchell', N'Sales Representative',3,274) 
,(285, N'Syed', N'Abbas', N'Pacific Sales Manager',3,273) 
,(286, N'Lynn', N'Tsoflias', N'Sales Representative',3,285) 
,(16, N'David',N'Bradley', N'Marketing Manager', 4, 273) 
,(23, N'Mary', N'Gibson', N'Marketing Specialist', 4, 16); 
Результат вывода рекурсивного CTE:
EmployeeID EMP.Firstname Title EmployeeLevel
1	Ken Sánchez	Chief Executive Officer	1
273	| Brian Welcker	Vice President of Sales	2
16	| | David Bradley	Marketing Manager	3
23	| | | Mary Gibson	Marketing Specialist	4
274	| | Stephen Jiang	North American Sales Manager	3
276	| | | Linda Mitchell	Sales Representative	4
275	| | | Michael Blythe	Sales Representative	4
285	| | Syed Abbas	Pacific Sales Manager	3
286	| | | Lynn Tsoflias	Sales Representative	4
*/

;With RecursCTE AS (
--[Anchor]
Select 
	EMP.EmployeeID, 
	CAST(EMP.Firstname + ' '+ EMP.Lastname as VARCHAR(255)) as [Name] ,
	EMP.Title, EMP.ManagerID, 
	1 as EmployeeLevel
from dbo.MyEmployees EMP
WHERE ManagerID IS NULL

UNION ALL
--[RecursiveSubQuery]
Select 
	EMP.EmployeeID,
	CAST(REPLICATE('| ',EmployeeLevel) + EMP.Firstname + ' '+ EMP.Lastname  as VARCHAR(255)) as [Name] ,
	EMP.Title, EMP.ManagerID,
	RecursCTE.EmployeeLevel+1
from dbo.MyEmployees EMP 
	join RecursCTE on EMP.ManagerID = RecursCTE.EmployeeID

)
Select EmployeeID,NAME,Title,EmployeeLevel 
from RecursCTE

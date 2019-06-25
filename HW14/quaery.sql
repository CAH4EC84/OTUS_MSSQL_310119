--1) Написать функцию возвращающую Клиента с набольшей суммой покупки.
USE WideWorldImporters
IF OBJECT_ID (N'FN_topBuyer',N'IF') IS NOT NULL DROP FUNCTION FN_topBuyer
GO
;CREATE FUNCTION FN_topBuyer (@rowsCount int)
RETURNS TABLE
AS RETURN ( 
	SELECT DISTINCT c.CustomerName,       
		   SUM (l.[Quantity] * l.[UnitPrice]) OVER (PARTITION BY c.CustomerName ) AS totalInvSumm
	FROM [Sales].[InvoiceLines] l
		 INNER JOIN Sales.Invoices i ON i.InvoiceID = l.InvoiceID
		 INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
	ORDER BY 2 DESC
	OFFSET 0 ROWS FETCH NEXT @rowsCount ROWS ONLY
)
Select * from FN_topBuyer(5)

/*2) Написать хранимую процедуру с входящим параметром
СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines*/

IF OBJECT_ID (N'SP_customerSum',N'p') IS NOT NULL DROP PROCEDURE SP_customerSum
GO
CREATE PROCEDURE SP_customerSum @CustId int
AS
	SELECT DISTINCT c.CustomerName,c.CustomerID,       
		   SUM (l.[Quantity] * l.[UnitPrice]) OVER (PARTITION BY c.CustomerName ) AS totalInvSumm
	FROM [Sales].[InvoiceLines] l
		 INNER JOIN Sales.Invoices i ON i.InvoiceID = l.InvoiceID
		 INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
	Where c.CustomerID = @CustId
EXEC SP_customerSum 10

--3) Cоздать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему
IF OBJECT_ID (N'FN_compare',N'IF') IS NOT NULL DROP FUNCTION FN_compare
GO
CREATE FUNCTION FN_compare(@minQuantity int,@description nvarchar(max))
RETURNS TABLE
AS RETURN (
	SELECT * FROM [Sales].[InvoiceLines] i
	WHERE i.Quantity > @minQuantity AND i.Description LIKE @description
)

SELECT * FROM FN_compare (10,'%t-shirt%')


IF OBJECT_ID (N'SP_compare',N'p') IS NOT NULL DROP PROCEDURE SP_compare
GO
CREATE PROCEDURE SP_compare @minQuantity int, @description nvarchar(max)
AS	
SELECT * FROM [Sales].[InvoiceLines] i
WHERE i.Quantity > @minQuantity AND i.Description LIKE @description



EXEC SP_compare 10,'%t-shirt%'
SELECT * FROM FN_compare (10,'%t-shirt%')
--Разницу в производительности не увидел, может быть надо другой запрос по сложнее.
--А так отличия в использовании хранимки для автоматизации переодических задач, функции для параметризированого DML
--К примеру функции могут использоваться с DML типа UPDATE DELETE, но не могут переопределять параметры и вызывать хранимки.

--4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
IF OBJECT_ID (N'FN_customersSums',N'IF') IS NOT NULL DROP FUNCTION FN_customersSums
GO
CREATE FUNCTION FN_customersSums (@CustId int)
RETURNS TABLE
AS RETURN (
	SELECT DISTINCT c.CustomerName,c.CustomerID,       
		   SUM (l.[Quantity] * l.[UnitPrice]) OVER (PARTITION BY c.CustomerName ) AS totalInvSumm
	FROM [Sales].[InvoiceLines] l
		 INNER JOIN Sales.Invoices i ON i.InvoiceID = l.InvoiceID
		 INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
	Where c.CustomerID = @CustId
)
 
Select FN_customersSums.*,c.PhoneNumber
FROM  sales.Customers c
CROSS APPLY FN_customersSums(c.CustomerId)
WHERE c.CustomerID < 5

/*
Во всех процедурах, в описании укажите для преподавателям
5) какой уровень изоляции нужен и почему. 
*/
-- Т.к мы не задавали для процедур уровень изоляции то используется дефолтный 
--READ COMMITTED — это уровень изоляции по умолчанию в SQL Server.
--Еще как вариат можно использовать snapshot что бы получить точные данные на момент старта процедуры.

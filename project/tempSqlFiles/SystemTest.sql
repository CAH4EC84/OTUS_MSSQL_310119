--1 Получаем список пользователей проверяем их рабочие директории на наличие новых заданий, если такие есть добавляем их в очередь выполнения.
--TRUNCATE TABLE [reports].[usersReportsTask]

DECLARE @path nvarchar(max)
DECLARE usersCursor CURSOR FOR
SELECT [requestPath] FROM reports.users u WHERE u.recState = 1

OPEN usersCursor
FETCH NEXT FROM usersCursor INTO @path

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC [dbo].[SP_readUserTask] @path
	FETCH NEXT FROM usersCursor INTO @path
END
CLOSE usersCursor
DEALLOCATE usersCursor




--2  Проверяет наличие новых заданий в очереди, устанавливает им статус в Работе (recState=2).

--UPDATE [otusProject].[reports].[usersReportsTask] SET [reports].[usersReportsTask].recState = 1, [reports].[usersReportsTask].errorMessage ='' WHERE id = 4


WHILE (SELECT count(*) FROM reports.usersReportsTask WHERE reports.usersReportsTask.recState =1 ) > 0
BEGIN

	EXEC [dbo].[SP_executeUserTask] --Вызываем обработчик очереди заданий
	WAITFOR DELAY '00:00:03' --Задержка в 5 секунд
	SELECT * FROM [otusProject].[reports].[usersReportsTask]
END


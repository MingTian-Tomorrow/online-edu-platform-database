-- 3号负责；先完成全部模块安装及 90_seed.sql。测试修改均回滚。
USE OnlineEducationSQL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N'li.demo@example.test');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N'语文');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status='PAID');
IF @o IS NULL THROW 52000,N'请先安装并加载演示数据',1;

BEGIN TRY
 BEGIN TRAN;
 DECLARE @new bigint; EXEC dbo.usp_CreateOrder @s,@c,@new OUTPUT;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51003 THROW;
 PRINT N'PASS: 重复下单';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N'失败事务残留退款记录',1;
GO
DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N'li.demo@example.test');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N'语文');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status='PAID');
IF @o IS NULL THROW 52000,N'请先安装并加载演示数据',1;

BEGIN TRY
 BEGIN TRAN;
 EXEC dbo.usp_CancelOrder @s,@o;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51007 THROW;
 PRINT N'PASS: 非法取消';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N'失败事务残留退款记录',1;
GO

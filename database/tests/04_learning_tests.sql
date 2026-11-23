-- 4号负责；先完成全部模块安装及 90_seed.sql。测试修改均回滚。
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

BEGIN TRAN;
EXEC dbo.usp_ReportProgress @s,@l,10;
IF (SELECT progress_percent FROM dbo.learning_progress WHERE student_id=@s AND lesson_id=@l)<>40 THROW 52002,N'进度不应回退',1;
ROLLBACK;
PRINT N'PASS: 进度不回退';

GO
DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N'li.demo@example.test');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N'语文');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status='PAID');
IF @o IS NULL THROW 52000,N'请先安装并加载演示数据',1;

BEGIN TRY
 BEGIN TRAN;
 SET @s=(SELECT student_id FROM dbo.student WHERE email=N'wang.demo@example.test'); SET @l=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id JOIN dbo.course c ON c.course_id=ch.course_id WHERE c.course_title=N'数学'); EXEC dbo.usp_ReportProgress @s,@l,50;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51009 THROW;
 PRINT N'PASS: 未购不能学习';
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
 EXEC dbo.usp_ReportProgress @s,@l,101;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51008 THROW;
 PRINT N'PASS: 进度超过100';
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
 EXEC dbo.usp_ReportProgress @s,@l,NULL;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51008 THROW;
 PRINT N'PASS: 进度为空';
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
 EXEC dbo.usp_ReportProgress @s,@l,-1;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51008 THROW;
 PRINT N'PASS: 负进度';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N'失败事务残留退款记录',1;
GO

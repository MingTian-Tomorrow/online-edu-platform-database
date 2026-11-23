-- 6号负责；先完成全部模块安装及 90_seed.sql。测试修改均回滚。
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
 EXEC dbo.usp_ReviewCourse @s,@c,5;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51013 THROW;
 PRINT N'PASS: 重复评价';
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
 EXEC dbo.usp_ReviewCourse @s,@c,0;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51010 THROW;
 PRINT N'PASS: 非法评分';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N'失败事务残留退款记录',1;
GO
DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N'li.demo@example.test');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N'语文');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status='PAID');
IF @o IS NULL THROW 52000,N'请先安装并加载演示数据',1;

DECLARE @maxBuyers int=(SELECT MAX(learner_count) FROM dbo.v_course_completion cc JOIN dbo.course c ON c.course_id=cc.course_id WHERE c.is_active=1);
DECLARE @expected decimal(7,2)=40.0*4/NULLIF(@maxBuyers,0)+30.0*4.5/5+0.30*25;
IF NOT EXISTS(SELECT 1 FROM dbo.v_hot_courses WHERE course_id=@c AND purchase_count=4 AND avg_rating=4.5 AND completion_rate=25 AND hot_score=@expected) THROW 52009,N'热门排行分量或总分不符合演示基准',1;
PRINT N'PASS: 热门排行计算';
GO

-- 7号负责；先完成全部模块安装及 90_seed.sql。测试修改均回滚。
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
EXEC dbo.usp_RefundOrder @s,@o,N'边界：恰好20%允许退款';
EXEC dbo.usp_RefundOrder @s,@o,N'幂等重试';
IF (SELECT COUNT(*) FROM dbo.refund_record WHERE order_id=@o)<>1 THROW 52003,N'退款不幂等',1;
IF EXISTS(SELECT 1 FROM dbo.v_enrollment WHERE student_id=@s AND course_id=@c) THROW 52004,N'退款后仍有学习资格',1;
IF (SELECT status FROM dbo.order_info WHERE order_id=@o)<>'REFUNDED' THROW 52005,N'订单状态未更新',1;
ROLLBACK;
PRINT N'PASS: 阈值边界、原子退款、幂等、撤销资格';
GO
DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N'li.demo@example.test');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N'语文');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status='PAID');
IF @o IS NULL THROW 52000,N'请先安装并加载演示数据',1;

BEGIN TRY
 BEGIN TRAN;
 SET @s=(SELECT student_id FROM dbo.student WHERE email=N'wang.demo@example.test'); EXEC dbo.usp_RefundOrder @s,@o;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51004 THROW;
 PRINT N'PASS: 错误订单所有人';
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
 EXEC dbo.usp_ReportProgress @s,@l,40.02; EXEC dbo.usp_RefundOrder @s,@o;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51017 THROW;
 PRINT N'PASS: 超阈值回滚';
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
 EXEC dbo.usp_RefundOrder @s,@o; EXEC dbo.usp_ReportProgress @s,@l,60;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51009 THROW;
 PRINT N'PASS: 退款后禁止学习';
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
 EXEC dbo.usp_RefundOrder @s,@o; EXEC dbo.usp_ReviewCourse @s,@c,5;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51012 THROW;
 PRINT N'PASS: 退款后禁止评价';
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
 UPDATE dbo.order_info SET total_amount=total_amount+1 WHERE order_id=@o; EXEC dbo.usp_RefundOrder @s,@o;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51006 THROW;
 PRINT N'PASS: 金额异常回滚';
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
 UPDATE dbo.order_info SET status='PENDING',paid_at=NULL WHERE order_id=@o; EXEC dbo.usp_RefundOrder @s,@o;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51015 THROW;
 PRINT N'PASS: 未支付不可退款';
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
 UPDATE dbo.order_info SET total_amount=0 WHERE order_id=@o; EXEC dbo.usp_RefundOrder @s,@o;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N'没有抛出预期业务错误',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51015 THROW;
 PRINT N'PASS: 零金额不可退款';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N'失败事务残留退款记录',1;
GO

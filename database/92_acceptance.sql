-- GENERATED: edit tests/*.sql, then run tools/build-bundles.ps1.
-- Requires a complete installation and the unchanged demo baseline.
USE OnlineEducationSQL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
 -- SOURCE: tests/02_course_tests.sql
 EXEC sys.sp_executesql N'-- 2号：课程基础资料维护与目录连接验证，完成后回滚。
USE OnlineEducationSQL;';
 EXEC sys.sp_executesql N'-- 管理员使用 DML 管理基础资料；示例最终回滚，可反复执行。
SET XACT_ABORT ON;
BEGIN TRAN;
INSERT dbo.teacher(teacher_name,title) VALUES(N''示例讲师'',N''讲师'');
DECLARE @t int=SCOPE_IDENTITY();
INSERT dbo.course(course_title,teacher_id,price,description) VALUES(N''新课程'',@t,99,N''管理示例'');
DECLARE @c int=SCOPE_IDENTITY();
INSERT dbo.chapter(course_id,chapter_title,sort_order) VALUES(@c,N''第一章'',1);
DECLARE @ch int=SCOPE_IDENTITY();
INSERT dbo.lesson(chapter_id,lesson_title,sort_order,duration_seconds,video_url)
VALUES(@ch,N''第一课'',1,600,N''https://example.test/new.mp4'');
UPDATE dbo.course SET price=129,description=N''更新课程资料'' WHERE course_id=@c;
UPDATE dbo.course SET is_active=0 WHERE course_id=@c;
IF NOT EXISTS(SELECT 1 FROM dbo.v_course_catalog WHERE course_id=@c AND chapter_id=@ch AND price=129 AND is_active=0 AND lesson_id IS NOT NULL) THROW 52011,N''课程目录维护结果错误'',1;
-- 没有业务记录的内容可按子表到父表删除；已有记录由外键保护，建议下架。
DELETE dbo.lesson WHERE chapter_id=@ch;
DELETE dbo.chapter WHERE chapter_id=@ch;
DELETE dbo.course WHERE course_id=@c;
DELETE dbo.teacher WHERE teacher_id=@t;
IF EXISTS(SELECT 1 FROM dbo.course WHERE course_id=@c) THROW 52010,N''示例课程未删除'',1;
ROLLBACK;
PRINT N''PASS: 课程目录增改下架删除'';';
 -- SOURCE: tests/03_order_tests.sql
 EXEC sys.sp_executesql N'-- 3号负责；先完成全部模块安装及 90_seed.sql。测试修改均回滚。
USE OnlineEducationSQL;';
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
SET XACT_ABORT ON;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 DECLARE @new bigint; EXEC dbo.usp_CreateOrder @s,@c,@new OUTPUT;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51003 THROW;
 PRINT N''PASS: 重复下单'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 EXEC dbo.usp_CancelOrder @s,@o;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51007 THROW;
 PRINT N''PASS: 非法取消'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 -- SOURCE: tests/04_learning_tests.sql
 EXEC sys.sp_executesql N'-- 4号负责；先完成全部模块安装及 90_seed.sql。测试修改均回滚。
USE OnlineEducationSQL;';
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
SET XACT_ABORT ON;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRAN;
EXEC dbo.usp_ReportProgress @s,@l,10;
IF (SELECT progress_percent FROM dbo.learning_progress WHERE student_id=@s AND lesson_id=@l)<>40 THROW 52002,N''进度不应回退'',1;
ROLLBACK;
PRINT N''PASS: 进度不回退'';';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 SET @s=(SELECT student_id FROM dbo.student WHERE email=N''wang.demo@example.test''); SET @l=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id JOIN dbo.course c ON c.course_id=ch.course_id WHERE c.course_title=N''数学''); EXEC dbo.usp_ReportProgress @s,@l,50;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51009 THROW;
 PRINT N''PASS: 未购不能学习'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 EXEC dbo.usp_ReportProgress @s,@l,101;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51008 THROW;
 PRINT N''PASS: 进度超过100'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 EXEC dbo.usp_ReportProgress @s,@l,NULL;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51008 THROW;
 PRINT N''PASS: 进度为空'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 EXEC dbo.usp_ReportProgress @s,@l,-1;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51008 THROW;
 PRINT N''PASS: 负进度'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 -- SOURCE: tests/05_completion_tests.sql
 EXEC sys.sp_executesql N'-- 5号负责；先完成全部模块安装及 90_seed.sql。测试修改均回滚。
USE OnlineEducationSQL;';
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
SET XACT_ABORT ON;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

IF NOT EXISTS(SELECT 1 FROM dbo.v_course_completion WHERE course_id=@c AND learner_count=4 AND completed_learners=1 AND completion_rate=25) THROW 52001,N''完成率基准不正确'',1;
PRINT N''PASS: 完成率包含未观看学员'';';
 -- SOURCE: tests/06_review_ranking_tests.sql
 EXEC sys.sp_executesql N'-- 6号负责；先完成全部模块安装及 90_seed.sql。测试修改均回滚。
USE OnlineEducationSQL;';
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
SET XACT_ABORT ON;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 EXEC dbo.usp_ReviewCourse @s,@c,5;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51013 THROW;
 PRINT N''PASS: 重复评价'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 EXEC dbo.usp_ReviewCourse @s,@c,0;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51010 THROW;
 PRINT N''PASS: 非法评分'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

DECLARE @maxBuyers int=(SELECT MAX(learner_count) FROM dbo.v_course_completion cc JOIN dbo.course c ON c.course_id=cc.course_id WHERE c.is_active=1);
DECLARE @expected decimal(7,2)=40.0*4/NULLIF(@maxBuyers,0)+30.0*4.5/5+0.30*25;
IF NOT EXISTS(SELECT 1 FROM dbo.v_hot_courses WHERE course_id=@c AND purchase_count=4 AND avg_rating=4.5 AND completion_rate=25 AND hot_score=@expected) THROW 52009,N''热门排行分量或总分不符合演示基准'',1;
PRINT N''PASS: 热门排行计算'';';
 -- SOURCE: tests/07_refund_tests.sql
 EXEC sys.sp_executesql N'-- 7号负责；先完成全部模块安装及 90_seed.sql。测试修改均回滚。
USE OnlineEducationSQL;';
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
SET XACT_ABORT ON;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRAN;
EXEC dbo.usp_RefundOrder @s,@o,N''边界：恰好20%允许退款'';
EXEC dbo.usp_RefundOrder @s,@o,N''幂等重试'';
IF (SELECT COUNT(*) FROM dbo.refund_record WHERE order_id=@o)<>1 THROW 52003,N''退款不幂等'',1;
IF EXISTS(SELECT 1 FROM dbo.v_enrollment WHERE student_id=@s AND course_id=@c) THROW 52004,N''退款后仍有学习资格'',1;
IF (SELECT status FROM dbo.order_info WHERE order_id=@o)<>''REFUNDED'' THROW 52005,N''订单状态未更新'',1;
ROLLBACK;
PRINT N''PASS: 阈值边界、原子退款、幂等、撤销资格'';';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 SET @s=(SELECT student_id FROM dbo.student WHERE email=N''wang.demo@example.test''); EXEC dbo.usp_RefundOrder @s,@o;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51004 THROW;
 PRINT N''PASS: 错误订单所有人'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 EXEC dbo.usp_ReportProgress @s,@l,40.02; EXEC dbo.usp_RefundOrder @s,@o;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51017 THROW;
 PRINT N''PASS: 超阈值回滚'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 EXEC dbo.usp_RefundOrder @s,@o; EXEC dbo.usp_ReportProgress @s,@l,60;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51009 THROW;
 PRINT N''PASS: 退款后禁止学习'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 EXEC dbo.usp_RefundOrder @s,@o; EXEC dbo.usp_ReviewCourse @s,@c,5;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51012 THROW;
 PRINT N''PASS: 退款后禁止评价'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 UPDATE dbo.order_info SET total_amount=total_amount+1 WHERE order_id=@o; EXEC dbo.usp_RefundOrder @s,@o;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51006 THROW;
 PRINT N''PASS: 金额异常回滚'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 UPDATE dbo.order_info SET status=''PENDING'',paid_at=NULL WHERE order_id=@o; EXEC dbo.usp_RefundOrder @s,@o;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51015 THROW;
 PRINT N''PASS: 未支付不可退款'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRY
 BEGIN TRAN;
 UPDATE dbo.order_info SET total_amount=0 WHERE order_id=@o; EXEC dbo.usp_RefundOrder @s,@o;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW 52999,N''没有抛出预期业务错误'',1;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF ERROR_NUMBER()<>51015 THROW;
 PRINT N''PASS: 零金额不可退款'';
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@o) THROW 52006,N''失败事务残留退款记录'',1;';
 -- SOURCE: tests/09_integration_tests.sql
 EXEC sys.sp_executesql N'-- 8号负责；先完成全部模块安装及 90_seed.sql。测试修改均回滚。
USE OnlineEducationSQL;';
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
SET XACT_ABORT ON;';
 EXEC sys.sp_executesql N'DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N''li.demo@example.test'');
DECLARE @c int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N''语文'');
DECLARE @l int=(SELECT MIN(l.lesson_id) FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id WHERE ch.course_id=@c);
DECLARE @o bigint=(SELECT MIN(o.order_id) FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id WHERE o.student_id=@s AND i.course_id=@c AND o.status=''PAID'');
IF @o IS NULL THROW 52000,N''请先安装并加载演示数据'',1;

BEGIN TRAN;
INSERT dbo.student(student_name,email) VALUES(N''自测学员'',N''test.transaction@example.test'');
SET @s=SCOPE_IDENTITY();
EXEC dbo.usp_CreateOrder @s,@c,@o OUTPUT;
EXEC dbo.usp_CancelOrder @s,@o;
IF (SELECT status FROM dbo.order_info WHERE order_id=@o)<>''CANCELLED'' THROW 52007,N''取消失败'',1;
EXEC dbo.usp_CreateOrder @s,@c,@o OUTPUT;
EXEC dbo.usp_PayOrder @s,@o;
EXEC dbo.usp_PayOrder @s,@o;
EXEC dbo.usp_ReportProgress @s,@l,100;
EXEC dbo.usp_ReviewCourse @s,@c,5,N''测试'';
IF NOT EXISTS(SELECT 1 FROM dbo.course_review WHERE student_id=@s AND course_id=@c) THROW 52008,N''评价未保存'',1;
ROLLBACK;
PRINT N''PASS: 新建、取消、重新下单、支付幂等、学习、评价'';';
 -- SOURCE: tests/10_dataset_tests.sql
 EXEC sys.sp_executesql N'-- 8号集成验收：丰富演示数据的关系和业务状态，纯查询，不修改数据。
USE OnlineEducationSQL;';
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
IF (SELECT COUNT(DISTINCT teacher_id) FROM dbo.course WHERE course_title IN(N''语文'',N''数学'',N''英语'',N''物理'',N''化学'',N''生物'',N''政治'',N''历史'',N''地理''))<>9
 THROW 52050,N''九门课程应分别关联九位讲师'',1;
PRINT N''PASS: 九门课程的讲师分配'';';
 EXEC sys.sp_executesql N'IF (SELECT COUNT(*) FROM dbo.student WHERE email LIKE N''cohort[0-9][0-9].demo@example.test'')<>20
 THROW 52051,N''扩展学员应为20人'',1;
IF EXISTS(
 SELECT s.student_id FROM dbo.student s
 LEFT JOIN dbo.order_info o ON o.student_id=s.student_id
 LEFT JOIN dbo.order_item i ON i.order_id=o.order_id
 WHERE s.email LIKE N''cohort[0-9][0-9].demo@example.test''
 GROUP BY s.student_id HAVING COUNT(DISTINCT o.order_id)<>3 OR COUNT(DISTINCT i.course_id)<>3)
 THROW 52052,N''每位扩展学员应跨选三门课'',1;
PRINT N''PASS: 二十名扩展学员跨课程选课'';';
 EXEC sys.sp_executesql N'DECLARE @states TABLE(status varchar(10),expected int);
INSERT @states VALUES(''PAID'',42),(''PENDING'',6),(''CANCELLED'',6),(''REFUNDED'',6);
IF EXISTS(SELECT 1 FROM @states x OUTER APPLY(
 SELECT COUNT(*) n FROM dbo.order_info o JOIN dbo.student s ON s.student_id=o.student_id
 WHERE s.email LIKE N''cohort[0-9][0-9].demo@example.test'' AND o.status=x.status) a WHERE a.n<>x.expected)
 THROW 52053,N''扩展订单状态分布不符合基准'',1;
PRINT N''PASS: 待支付、支付、取消、退款四种订单状态'';';
 EXEC sys.sp_executesql N'IF NOT EXISTS(SELECT 1 FROM dbo.v_student_course_progress p JOIN dbo.student s ON s.student_id=p.student_id WHERE s.email LIKE N''cohort[0-9][0-9].demo@example.test'' AND p.progress_percent=0)
 OR NOT EXISTS(SELECT 1 FROM dbo.v_student_course_progress p JOIN dbo.student s ON s.student_id=p.student_id WHERE s.email LIKE N''cohort[0-9][0-9].demo@example.test'' AND p.progress_percent BETWEEN 1 AND 99)
 OR NOT EXISTS(SELECT 1 FROM dbo.v_student_course_progress p JOIN dbo.student s ON s.student_id=p.student_id WHERE s.email LIKE N''cohort[0-9][0-9].demo@example.test'' AND p.is_completed=1)
 THROW 52054,N''缺少未开始、部分学习或全部完成案例'',1;
IF EXISTS(SELECT 1 FROM dbo.order_info o JOIN dbo.student s ON s.student_id=o.student_id
 LEFT JOIN dbo.refund_record r ON r.order_id=o.order_id
 WHERE s.email LIKE N''cohort[0-9][0-9].demo@example.test'' AND
 (o.paid_at<o.created_at OR (o.status=''REFUNDED'' AND (r.refund_id IS NULL OR r.refund_amount<>o.total_amount OR r.processed_at<o.paid_at))))
 THROW 52055,N''扩展订单金额或时间关系异常'',1;
PRINT N''PASS: 多种学习阶段与退款记录一致性'';';
 PRINT N'ALL TESTS PASSED';
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
GO

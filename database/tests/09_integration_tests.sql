-- 8号负责；先完成全部模块安装及 90_seed.sql。测试修改均回滚。
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
INSERT dbo.student(student_name,email) VALUES(N'自测学员',N'test.transaction@example.test');
SET @s=SCOPE_IDENTITY();
EXEC dbo.usp_CreateOrder @s,@c,@o OUTPUT;
EXEC dbo.usp_CancelOrder @s,@o;
IF (SELECT status FROM dbo.order_info WHERE order_id=@o)<>'CANCELLED' THROW 52007,N'取消失败',1;
EXEC dbo.usp_CreateOrder @s,@c,@o OUTPUT;
EXEC dbo.usp_PayOrder @s,@o;
EXEC dbo.usp_PayOrder @s,@o;
EXEC dbo.usp_ReportProgress @s,@l,100;
EXEC dbo.usp_ReviewCourse @s,@c,5,N'测试';
IF NOT EXISTS(SELECT 1 FROM dbo.course_review WHERE student_id=@s AND course_id=@c) THROW 52008,N'评价未保存',1;
ROLLBACK;
PRINT N'PASS: 新建、取消、重新下单、支付幂等、学习、评价';

GO

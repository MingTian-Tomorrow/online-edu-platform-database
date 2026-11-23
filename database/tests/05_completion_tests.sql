-- 5号负责；先完成全部模块安装及 90_seed.sql。测试修改均回滚。
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

IF NOT EXISTS(SELECT 1 FROM dbo.v_course_completion WHERE course_id=@c AND learner_count=4 AND completed_learners=1 AND completion_rate=25) THROW 52001,N'完成率基准不正确',1;
PRINT N'PASS: 完成率包含未观看学员';

GO

-- 8号集成验收：丰富演示数据的关系和业务状态，纯查询，不修改数据。
USE OnlineEducationSQL;
GO
SET NOCOUNT ON;
IF (SELECT COUNT(DISTINCT teacher_id) FROM dbo.course WHERE course_title IN(N'语文',N'数学',N'英语',N'物理',N'化学',N'生物',N'政治',N'历史',N'地理'))<>9
 THROW 52050,N'九门课程应分别关联九位讲师',1;
PRINT N'PASS: 九门课程的讲师分配';
GO
IF (SELECT COUNT(*) FROM dbo.student WHERE email LIKE N'cohort[0-9][0-9].demo@example.test')<>20
 THROW 52051,N'扩展学员应为20人',1;
IF EXISTS(
 SELECT s.student_id FROM dbo.student s
 LEFT JOIN dbo.order_info o ON o.student_id=s.student_id
 LEFT JOIN dbo.order_item i ON i.order_id=o.order_id
 WHERE s.email LIKE N'cohort[0-9][0-9].demo@example.test'
 GROUP BY s.student_id HAVING COUNT(DISTINCT o.order_id)<>3 OR COUNT(DISTINCT i.course_id)<>3)
 THROW 52052,N'每位扩展学员应跨选三门课',1;
PRINT N'PASS: 二十名扩展学员跨课程选课';
GO
DECLARE @states TABLE(status varchar(10),expected int);
INSERT @states VALUES('PAID',42),('PENDING',6),('CANCELLED',6),('REFUNDED',6);
IF EXISTS(SELECT 1 FROM @states x OUTER APPLY(
 SELECT COUNT(*) n FROM dbo.order_info o JOIN dbo.student s ON s.student_id=o.student_id
 WHERE s.email LIKE N'cohort[0-9][0-9].demo@example.test' AND o.status=x.status) a WHERE a.n<>x.expected)
 THROW 52053,N'扩展订单状态分布不符合基准',1;
PRINT N'PASS: 待支付、支付、取消、退款四种订单状态';
GO
IF NOT EXISTS(SELECT 1 FROM dbo.v_student_course_progress p JOIN dbo.student s ON s.student_id=p.student_id WHERE s.email LIKE N'cohort[0-9][0-9].demo@example.test' AND p.progress_percent=0)
 OR NOT EXISTS(SELECT 1 FROM dbo.v_student_course_progress p JOIN dbo.student s ON s.student_id=p.student_id WHERE s.email LIKE N'cohort[0-9][0-9].demo@example.test' AND p.progress_percent BETWEEN 1 AND 99)
 OR NOT EXISTS(SELECT 1 FROM dbo.v_student_course_progress p JOIN dbo.student s ON s.student_id=p.student_id WHERE s.email LIKE N'cohort[0-9][0-9].demo@example.test' AND p.is_completed=1)
 THROW 52054,N'缺少未开始、部分学习或全部完成案例',1;
IF EXISTS(SELECT 1 FROM dbo.order_info o JOIN dbo.student s ON s.student_id=o.student_id
 LEFT JOIN dbo.refund_record r ON r.order_id=o.order_id
 WHERE s.email LIKE N'cohort[0-9][0-9].demo@example.test' AND
 (o.paid_at<o.created_at OR (o.status='REFUNDED' AND (r.refund_id IS NULL OR r.refund_amount<>o.total_amount OR r.processed_at<o.paid_at))))
 THROW 52055,N'扩展订单金额或时间关系异常',1;
PRINT N'PASS: 多种学习阶段与退款记录一致性';
GO

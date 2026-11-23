USE OnlineEducationSQL;
GO
-- 1. 九位讲师的授课分工，以及课程—章节—课时三级结构。
SELECT t.teacher_id,t.teacher_name,t.title,t.bio,c.course_title,c.price
FROM dbo.teacher t LEFT JOIN dbo.course c ON c.teacher_id=t.teacher_id ORDER BY t.teacher_id,c.course_id;
-- 各课程的章节和课时数量，英语暂未发布课时，保留空课程边界案例。
SELECT c.course_title,COUNT(DISTINCT ch.chapter_id) chapter_count,COUNT(l.lesson_id) lesson_count
FROM dbo.course c LEFT JOIN dbo.chapter ch ON ch.course_id=c.course_id
LEFT JOIN dbo.lesson l ON l.chapter_id=ch.chapter_id GROUP BY c.course_id,c.course_title ORDER BY c.course_id;
SELECT * FROM dbo.v_course_catalog ORDER BY course_id,chapter_order,lesson_order;
SELECT * FROM dbo.student;
SELECT o.*,i.course_id,i.unit_price FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id;
-- 多状态订单：待支付6、取消6、已支付47、已退款7（初始演示基准）。
SELECT status,COUNT(*) order_count,SUM(total_amount) total_amount FROM dbo.order_info GROUP BY status;
-- 跨课程选课：扩展学员每人三门，包括待支付和取消等历史记录。
SELECT s.student_name,c.course_title,o.status,o.total_amount,o.created_at,o.paid_at
FROM dbo.student s JOIN dbo.order_info o ON o.student_id=s.student_id
JOIN dbo.order_item i ON i.order_id=o.order_id JOIN dbo.course c ON c.course_id=i.course_id
WHERE s.email LIKE N'cohort[0-9][0-9].demo@example.test' ORDER BY s.student_id,c.course_id;
-- 2. 学员 + 课时 + 百分比 + 最后观看时间。
SELECT s.student_name,l.lesson_title,p.* FROM dbo.learning_progress p
JOIN dbo.student s ON s.student_id=p.student_id JOIN dbo.lesson l ON l.lesson_id=p.lesson_id;
SELECT * FROM dbo.course_review;
-- 3. 语文保留4人中1人完成的25%案例；其余科目有不同完成率。
SELECT * FROM dbo.v_course_completion;
-- 4. 购买量 40% + 评分 30% + 完课率 30%，展示各分量和总分。
SELECT * FROM dbo.v_hot_courses ORDER BY rank_no;
-- 5. 成功退款的持久记录，以及超阈值失败（不改变订单）。
SELECT * FROM dbo.refund_record;
DECLARE @s int=(SELECT student_id FROM dbo.student WHERE email=N'zhao.demo@example.test');
DECLARE @o bigint=(SELECT MIN(order_id) FROM dbo.order_info WHERE student_id=@s AND status='PAID');
BEGIN TRY
 EXEC dbo.usp_RefundOrder @s,@o,N'演示：30% 大于默认 20%，应拒绝';
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>51017 THROW;
 SELECT ERROR_NUMBER() error_number,ERROR_MESSAGE() expected_rejection;
END CATCH;
SELECT * FROM dbo.order_info WHERE order_id=@o;
-- 6. 两种索引优化目标查询。SSMS 按 Ctrl+M 包含实际执行计划。
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
DECLARE @student int=(SELECT student_id FROM dbo.student WHERE email=N'zhang.demo@example.test');
DECLARE @course int=(SELECT MIN(course_id) FROM dbo.course WHERE course_title=N'语文');
EXEC dbo.usp_StudentCourses @student;
EXEC dbo.usp_CourseStudents @course;
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
SELECT OBJECT_NAME(object_id) table_name,name index_name FROM sys.indexes
WHERE object_id IN(OBJECT_ID('dbo.order_info'),OBJECT_ID('dbo.order_item'),OBJECT_ID('dbo.learning_progress'),OBJECT_ID('dbo.chapter'),OBJECT_ID('dbo.lesson'));
GO

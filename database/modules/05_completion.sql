-- 5号：课程完成率。依赖 04 的学员课程汇总视图。
-- 此文件为模块源文件；修改后用 tools/build-bundles.ps1 同步统一入口。
USE OnlineEducationSQL;
GO
CREATE OR ALTER VIEW dbo.v_course_completion AS
SELECT c.course_id,c.course_title,COUNT(p.student_id) learner_count,
 COALESCE(SUM(p.is_completed),0) completed_learners,
 CAST(COALESCE(100.0*SUM(p.is_completed)/NULLIF(COUNT(p.student_id),0),0) AS decimal(5,2)) completion_rate
FROM dbo.course c LEFT JOIN dbo.v_student_course_progress p ON p.course_id=c.course_id
GROUP BY c.course_id,c.course_title;
GO

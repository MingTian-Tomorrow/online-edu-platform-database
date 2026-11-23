-- 2号：课程三级目录。依赖 01；管理演示见 examples/02_course_admin.sql。
-- 此文件为模块源文件；修改后用 tools/build-bundles.ps1 同步统一入口。
USE OnlineEducationSQL;
GO
CREATE OR ALTER VIEW dbo.v_course_catalog AS
SELECT c.course_id,c.course_title,t.teacher_name,c.price,c.is_active,
       ch.chapter_id,ch.chapter_title,ch.sort_order chapter_order,
       l.lesson_id,l.lesson_title,l.sort_order lesson_order,l.duration_seconds,l.video_url
FROM dbo.course c JOIN dbo.teacher t ON t.teacher_id=c.teacher_id
LEFT JOIN dbo.chapter ch ON ch.course_id=c.course_id
LEFT JOIN dbo.lesson l ON l.chapter_id=ch.chapter_id;
GO

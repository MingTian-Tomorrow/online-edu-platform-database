-- 2号：课程基础资料维护与目录连接验证，完成后回滚。
USE OnlineEducationSQL;
GO
-- 管理员使用 DML 管理基础资料；示例最终回滚，可反复执行。
SET XACT_ABORT ON;
BEGIN TRAN;
INSERT dbo.teacher(teacher_name,title) VALUES(N'示例讲师',N'讲师');
DECLARE @t int=SCOPE_IDENTITY();
INSERT dbo.course(course_title,teacher_id,price,description) VALUES(N'新课程',@t,99,N'管理示例');
DECLARE @c int=SCOPE_IDENTITY();
INSERT dbo.chapter(course_id,chapter_title,sort_order) VALUES(@c,N'第一章',1);
DECLARE @ch int=SCOPE_IDENTITY();
INSERT dbo.lesson(chapter_id,lesson_title,sort_order,duration_seconds,video_url)
VALUES(@ch,N'第一课',1,600,N'https://example.test/new.mp4');
UPDATE dbo.course SET price=129,description=N'更新课程资料' WHERE course_id=@c;
UPDATE dbo.course SET is_active=0 WHERE course_id=@c;
IF NOT EXISTS(SELECT 1 FROM dbo.v_course_catalog WHERE course_id=@c AND chapter_id=@ch AND price=129 AND is_active=0 AND lesson_id IS NOT NULL) THROW 52011,N'课程目录维护结果错误',1;
-- 没有业务记录的内容可按子表到父表删除；已有记录由外键保护，建议下架。
DELETE dbo.lesson WHERE chapter_id=@ch;
DELETE dbo.chapter WHERE chapter_id=@ch;
DELETE dbo.course WHERE course_id=@c;
DELETE dbo.teacher WHERE teacher_id=@t;
IF EXISTS(SELECT 1 FROM dbo.course WHERE course_id=@c) THROW 52010,N'示例课程未删除',1;
ROLLBACK;
PRINT N'PASS: 课程目录增改下架删除';
GO

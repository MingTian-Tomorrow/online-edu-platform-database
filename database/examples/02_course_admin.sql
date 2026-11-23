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
SELECT * FROM dbo.v_course_catalog WHERE course_id=@c;
-- 没有业务记录的内容可按子表到父表删除；已有记录由外键保护，建议下架。
DELETE dbo.lesson WHERE chapter_id=@ch;
DELETE dbo.chapter WHERE chapter_id=@ch;
DELETE dbo.course WHERE course_id=@c;
DELETE dbo.teacher WHERE teacher_id=@t;
ROLLBACK;
GO

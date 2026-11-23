-- 4号：学习进度、学员课程汇总及双向查询。依赖 01、03。
-- 此文件为模块源文件；修改后用 tools/build-bundles.ps1 同步统一入口。
USE OnlineEducationSQL;
GO
-- 每课时等权；未观看课时按 0，空课程永不算完成。
CREATE OR ALTER VIEW dbo.v_student_course_progress AS
SELECT e.student_id,e.course_id,COUNT(l.lesson_id) total_lessons,
 SUM(CASE WHEN p.progress_percent=100 THEN 1 ELSE 0 END) completed_lessons,
 CAST(COALESCE(SUM(p.progress_percent)/NULLIF(COUNT(l.lesson_id),0),0) AS decimal(5,2)) progress_percent,
 MAX(p.last_watched_at) last_watched_at,
 CASE WHEN COUNT(l.lesson_id)>0 AND COUNT(l.lesson_id)=SUM(CASE WHEN p.progress_percent=100 THEN 1 ELSE 0 END) THEN 1 ELSE 0 END is_completed
FROM dbo.v_enrollment e
LEFT JOIN dbo.chapter ch ON ch.course_id=e.course_id
LEFT JOIN dbo.lesson l ON l.chapter_id=ch.chapter_id
LEFT JOIN dbo.learning_progress p ON p.student_id=e.student_id AND p.lesson_id=l.lesson_id
GROUP BY e.student_id,e.course_id;
GO
CREATE OR ALTER PROCEDURE dbo.usp_ReportProgress
 @StudentId int,@LessonId int,@Progress decimal(5,2)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRAN;
  IF @Progress IS NULL OR @Progress<0 OR @Progress>100 THROW 51008,N'进度必须在 0 到 100 之间',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.student WITH(UPDLOCK,HOLDLOCK) WHERE student_id=@StudentId)
   THROW 51001,N'学员不存在',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id
     JOIN dbo.v_enrollment e ON e.course_id=ch.course_id AND e.student_id=@StudentId WHERE l.lesson_id=@LessonId)
   THROW 51009,N'课时不存在、未购买或已退款',1;
  UPDATE dbo.learning_progress SET progress_percent=CASE WHEN @Progress>progress_percent THEN @Progress ELSE progress_percent END,
   last_watched_at=SYSDATETIME() WHERE student_id=@StudentId AND lesson_id=@LessonId;
  IF @@ROWCOUNT=0 INSERT dbo.learning_progress(student_id,lesson_id,progress_percent) VALUES(@StudentId,@LessonId,@Progress);
  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_StudentCourses @StudentId int AS
BEGIN
 SET NOCOUNT ON;
 SELECT c.course_title,t.teacher_name,p.*
 FROM dbo.v_student_course_progress p JOIN dbo.course c ON c.course_id=p.course_id
 JOIN dbo.teacher t ON t.teacher_id=c.teacher_id WHERE p.student_id=@StudentId ORDER BY p.course_id;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_CourseStudents @CourseId int AS
BEGIN
 SET NOCOUNT ON;
 SELECT s.student_name,p.* FROM dbo.v_student_course_progress p
 JOIN dbo.student s ON s.student_id=p.student_id WHERE p.course_id=@CourseId ORDER BY p.student_id;
 -- 第二个结果集包含未开始课时及最后观看时间。
 SELECT e.student_id,s.student_name,l.lesson_id,l.lesson_title,COALESCE(p.progress_percent,0) progress_percent,p.last_watched_at
 FROM dbo.v_enrollment e JOIN dbo.student s ON s.student_id=e.student_id
 JOIN dbo.chapter ch ON ch.course_id=e.course_id JOIN dbo.lesson l ON l.chapter_id=ch.chapter_id
 LEFT JOIN dbo.learning_progress p ON p.student_id=e.student_id AND p.lesson_id=l.lesson_id
 WHERE e.course_id=@CourseId ORDER BY e.student_id,ch.sort_order,l.sort_order;
END;
GO

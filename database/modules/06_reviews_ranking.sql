-- 6号：评价规则与热门排行。依赖 03、05。
-- 此文件为模块源文件；修改后用 tools/build-bundles.ps1 同步统一入口。
USE OnlineEducationSQL;
GO
CREATE OR ALTER PROCEDURE dbo.usp_ReviewCourse
 @StudentId int,@CourseId int,@Rating tinyint,@Content nvarchar(max)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRAN;
  IF @Rating IS NULL OR @Rating NOT BETWEEN 1 AND 5 THROW 51010,N'评分必须为 1 到 5',1;
  IF DATALENGTH(@Content)>2000 THROW 51011,N'评论最多 1000 个 UTF-16 字符',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.student WITH(UPDLOCK,HOLDLOCK) WHERE student_id=@StudentId)
   THROW 51001,N'学员不存在',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.v_enrollment WHERE student_id=@StudentId AND course_id=@CourseId)
   THROW 51012,N'仅有效已购学员可以评价',1;
  IF EXISTS(SELECT 1 FROM dbo.course_review WHERE student_id=@StudentId AND course_id=@CourseId)
   THROW 51013,N'每名学员每门课程只能评价一次',1;
  INSERT dbo.course_review(student_id,course_id,rating,content) VALUES(@StudentId,@CourseId,@Rating,@Content);
  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER VIEW dbo.v_hot_courses AS
WITH metrics AS (
 SELECT c.course_id,c.course_title,c.is_active,cc.learner_count purchase_count,cc.completion_rate,
 COALESCE(r.avg_rating,0) avg_rating,COALESCE(r.review_count,0) review_count
 FROM dbo.course c JOIN dbo.v_course_completion cc ON cc.course_id=c.course_id
 OUTER APPLY(SELECT AVG(CAST(r.rating AS decimal(10,4))) avg_rating,COUNT(*) review_count
   FROM dbo.course_review r JOIN dbo.v_enrollment e ON e.student_id=r.student_id AND e.course_id=r.course_id
   WHERE r.course_id=c.course_id) r
), scores AS (
 SELECT *,CAST(40.0*purchase_count/NULLIF(MAX(purchase_count) OVER(),0)
              +30.0*avg_rating/5.0+0.30*completion_rate AS decimal(7,2)) raw_score
 FROM metrics WHERE is_active=1
)
SELECT ROW_NUMBER() OVER(ORDER BY COALESCE(raw_score,0) DESC,purchase_count DESC,course_id) rank_no,
 course_id,course_title,purchase_count,avg_rating,review_count,completion_rate,COALESCE(raw_score,0) hot_score
FROM scores;
GO

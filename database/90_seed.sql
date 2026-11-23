USE OnlineEducationSQL;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM dbo.student WHERE email=N'zhang.demo@example.test')
BEGIN
BEGIN TRY
 BEGIN TRAN;
 INSERT dbo.teacher(teacher_name,title,bio) VALUES(N'陈老师',N'课程讲师',N'中学课程演示教学');
 DECLARE @t int=SCOPE_IDENTITY();
 INSERT dbo.course(course_title,teacher_id,price) VALUES(N'语文',@t,199);
 DECLARE @c1 int=SCOPE_IDENTITY();
 INSERT dbo.course(course_title,teacher_id,price) VALUES(N'数学',@t,299);
 DECLARE @c2 int=SCOPE_IDENTITY();
 INSERT dbo.course(course_title,teacher_id,price) VALUES(N'英语',@t,99);
 INSERT dbo.chapter(course_id,chapter_title,sort_order) VALUES(@c1,N'基础知识',1);
 DECLARE @ch int=SCOPE_IDENTITY();
 INSERT dbo.lesson(chapter_id,lesson_title,sort_order,duration_seconds,video_url)
 VALUES(@ch,N'字词与句子',1,600,N'https://example.test/video/tables.mp4');
 DECLARE @l1 int=SCOPE_IDENTITY();
 INSERT dbo.chapter(course_id,chapter_title,sort_order) VALUES(@c1,N'阅读与表达',2);
 SET @ch=SCOPE_IDENTITY();
 INSERT dbo.lesson(chapter_id,lesson_title,sort_order,duration_seconds,video_url)
 VALUES(@ch,N'阅读理解',1,900,N'https://example.test/video/transactions.mp4');
 DECLARE @l2 int=SCOPE_IDENTITY();
 INSERT dbo.chapter(course_id,chapter_title,sort_order) VALUES(@c2,N'数学基础',1);
 SET @ch=SCOPE_IDENTITY();
 INSERT dbo.lesson(chapter_id,lesson_title,sort_order,duration_seconds,video_url)
 VALUES(@ch,N'基础练习',1,1200,N'https://example.test/video/index.mp4');
 DECLARE @l3 int=SCOPE_IDENTITY();
 INSERT dbo.student(student_name,email) VALUES(N'张同学',N'zhang.demo@example.test');
 DECLARE @s1 int=SCOPE_IDENTITY();
 INSERT dbo.student(student_name,email) VALUES(N'李同学',N'li.demo@example.test');
 DECLARE @s2 int=SCOPE_IDENTITY();
 INSERT dbo.student(student_name,email) VALUES(N'王同学',N'wang.demo@example.test');
 DECLARE @s3 int=SCOPE_IDENTITY();
 INSERT dbo.student(student_name,email) VALUES(N'赵同学',N'zhao.demo@example.test');
 DECLARE @s4 int=SCOPE_IDENTITY(),@o bigint;
 EXEC dbo.usp_CreateOrder @s1,@c1,@o OUTPUT;
 EXEC dbo.usp_PayOrder @s1,@o;
 EXEC dbo.usp_ReportProgress @s1,@l1,100;
 EXEC dbo.usp_ReportProgress @s1,@l2,100;
 EXEC dbo.usp_ReviewCourse @s1,@c1,5,N'结构清楚，已完成全部课时。';
 EXEC dbo.usp_CreateOrder @s2,@c1,@o OUTPUT;
 EXEC dbo.usp_PayOrder @s2,@o;
 EXEC dbo.usp_ReportProgress @s2,@l1,40;
 EXEC dbo.usp_ReviewCourse @s2,@c1,4,N'正在学习。';
 EXEC dbo.usp_CreateOrder @s3,@c1,@o OUTPUT;
 EXEC dbo.usp_PayOrder @s3,@o;
 EXEC dbo.usp_CreateOrder @s4,@c1,@o OUTPUT;
 EXEC dbo.usp_PayOrder @s4,@o;
 EXEC dbo.usp_ReportProgress @s4,@l1,60;
 EXEC dbo.usp_CreateOrder @s1,@c2,@o OUTPUT;
 EXEC dbo.usp_PayOrder @s1,@o;
 EXEC dbo.usp_ReportProgress @s1,@l3,100;
 EXEC dbo.usp_ReviewCourse @s1,@c2,5,N'解题过程讲解很好。';
 EXEC dbo.usp_CreateOrder @s2,@c2,@o OUTPUT;
 EXEC dbo.usp_PayOrder @s2,@o;
 EXEC dbo.usp_RefundOrder @s2,@o,N'演示：未开始学习可退款';
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
END;
GO
-- 将上一版演示课程改名，保留主键及全部订单、进度和评价。
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRAN;
 DECLARE @names TABLE(old_title nvarchar(200),new_title nvarchar(200));
 INSERT @names VALUES(N'SQL Server 数据库基础',N'语文'),(N'T-SQL 进阶',N'数学'),(N'数据库设计（待更新课时）',N'英语');
 IF EXISTS(SELECT 1 FROM dbo.course c JOIN @names n ON n.old_title=c.course_title
   JOIN dbo.course d ON d.course_title=n.new_title)
  THROW 52020,N'新旧演示课程名称同时存在，请人工核对，避免错误合并',1;
 UPDATE c SET course_title=n.new_title FROM dbo.course c JOIN @names n ON n.old_title=c.course_title;
 UPDATE ch SET chapter_title=CASE ch.chapter_title WHEN N'数据库入门' THEN N'基础知识' WHEN N'业务实现' THEN N'阅读与表达' WHEN N'查询优化' THEN N'数学基础' END
 FROM dbo.chapter ch JOIN dbo.course c ON c.course_id=ch.course_id
 WHERE c.course_title IN(N'语文',N'数学') AND ch.chapter_title IN(N'数据库入门',N'业务实现',N'查询优化');
 UPDATE l SET lesson_title=CASE l.lesson_title WHEN N'表与约束' THEN N'字词与句子' WHEN N'事务与存储过程' THEN N'阅读理解' WHEN N'索引与执行计划' THEN N'基础练习' END
 FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id JOIN dbo.course c ON c.course_id=ch.course_id
 WHERE c.course_title IN(N'语文',N'数学') AND l.lesson_title IN(N'表与约束',N'事务与存储过程',N'索引与执行计划');
 DECLARE @teacher int=(SELECT TOP(1) teacher_id FROM dbo.course WHERE course_title=N'语文' ORDER BY course_id);
 IF @teacher IS NULL THROW 52021,N'缺少语文演示课程，无法补充科目',1;
 UPDATE dbo.teacher SET title=N'课程讲师',bio=N'中学课程演示教学' WHERE teacher_id=@teacher AND title=N'数据库讲师';
 DECLARE @subjects TABLE(subject_name nvarchar(20));
 INSERT @subjects VALUES(N'物理'),(N'化学'),(N'生物'),(N'政治'),(N'历史'),(N'地理');
 INSERT dbo.course(course_title,teacher_id,price)
 SELECT subject_name,@teacher,99 FROM @subjects s WHERE NOT EXISTS(SELECT 1 FROM dbo.course c WHERE c.course_title=s.subject_name);
 INSERT dbo.chapter(course_id,chapter_title,sort_order)
 SELECT c.course_id,N'基础知识',1 FROM dbo.course c JOIN @subjects s ON s.subject_name=c.course_title
 WHERE NOT EXISTS(SELECT 1 FROM dbo.chapter ch WHERE ch.course_id=c.course_id);
 INSERT dbo.lesson(chapter_id,lesson_title,sort_order,duration_seconds,video_url)
 SELECT ch.chapter_id,N'入门第一课',1,600,N'https://example.test/video/intro.mp4'
 FROM dbo.chapter ch JOIN dbo.course c ON c.course_id=ch.course_id JOIN @subjects s ON s.subject_name=c.course_title
 WHERE ch.sort_order=1 AND NOT EXISTS(SELECT 1 FROM dbo.lesson l WHERE l.chapter_id=ch.chapter_id);
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
GO

-- 第二版演示数据：9 位讲师、24 名学员、9 门课程、21 章、39 课时。
-- 扩展数据通过业务过程创建；版本标记与数据同一事务提交，重复执行不重复灌入。
-- 仅修改已知演示课程资料，不清空已有业务记录。
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'education_demo_rich_v2')
BEGIN
 BEGIN TRY
  BEGIN TRAN;
  DECLARE @teachers TABLE(subject_name nvarchar(20),teacher_name nvarchar(100),title nvarchar(100),bio nvarchar(1000));
  INSERT @teachers VALUES
  (N'语文',N'陈老师',N'语文高级教师',N'负责阅读理解与写作教学'),
  (N'数学',N'周老师',N'数学骨干教师',N'负责代数、几何与解题训练'),
  (N'英语',N'林老师',N'英语教师',N'负责词汇、语法与听说训练'),
  (N'物理',N'吴老师',N'物理高级教师',N'负责力学、电学与实验教学'),
  (N'化学',N'郑老师',N'化学教师',N'负责物质性质与实验安全'),
  (N'生物',N'王老师',N'生物骨干教师',N'负责细胞、遗传与生态教学'),
  (N'政治',N'孙老师',N'政治教师',N'负责公民素养与社会生活教学'),
  (N'历史',N'赵老师',N'历史高级教师',N'负责中国史与世界史教学'),
  (N'地理',N'何老师',N'地理教师',N'负责自然地理与区域地理教学');
  IF EXISTS(SELECT subject_name FROM @teachers x LEFT JOIN dbo.course c ON c.course_title=x.subject_name GROUP BY subject_name HAVING COUNT(c.course_id)<>1)
   THROW 52040,N'九门演示课程缺失或重名，请先核对课程数据',1;
  INSERT dbo.teacher(teacher_name,title,bio)
  SELECT teacher_name,title,bio FROM @teachers x WHERE NOT EXISTS(SELECT 1 FROM dbo.teacher t WHERE t.teacher_name=x.teacher_name);
  IF EXISTS(SELECT x.teacher_name FROM @teachers x JOIN dbo.teacher t ON t.teacher_name=x.teacher_name GROUP BY x.teacher_name HAVING COUNT(*)<>1)
   THROW 52041,N'演示讲师重名，请先核对讲师数据',1;
  UPDATE t SET title=x.title,bio=x.bio FROM dbo.teacher t JOIN @teachers x ON x.teacher_name=t.teacher_name;
  UPDATE c SET teacher_id=t.teacher_id,description=x.bio
  FROM dbo.course c JOIN @teachers x ON x.subject_name=c.course_title JOIN dbo.teacher t ON t.teacher_name=x.teacher_name;
  DECLARE @content TABLE(subject_name nvarchar(20),chapter_no int,chapter_title nvarchar(200),lesson1 nvarchar(200),lesson2 nvarchar(200));
  INSERT @content VALUES
  (N'物理',1,N'力与运动',N'速度与路程',N'力的作用'),
  (N'物理',2,N'光与热',N'光的反射',N'温度与热量'),
  (N'物理',3,N'电学基础',N'电路连接',N'电流与电压'),
  (N'化学',1,N'物质与变化',N'物质的分类',N'物理变化与化学变化'),
  (N'化学',2,N'空气与水',N'空气的组成',N'水的净化'),
  (N'化学',3,N'实验基础',N'实验仪器',N'实验操作与安全'),
  (N'生物',1,N'细胞与生命',N'认识细胞',N'细胞的结构'),
  (N'生物',2,N'遗传与变异',N'遗传现象',N'基因与性状'),
  (N'生物',3,N'生态与环境',N'食物链',N'生态系统'),
  (N'政治',1,N'成长与责任',N'认识自己',N'承担责任'),
  (N'政治',2,N'规则与法治',N'社会规则',N'法律与生活'),
  (N'政治',3,N'社会与发展',N'参与公共生活',N'理解社会发展'),
  (N'历史',1,N'中国古代史',N'早期文明',N'统一国家的发展'),
  (N'历史',2,N'中国近现代史',N'近代社会变迁',N'现代中国建设'),
  (N'历史',3,N'世界历史',N'古代世界文明',N'近代世界发展'),
  (N'地理',1,N'地球与地图',N'经纬线',N'地图的阅读'),
  (N'地理',2,N'自然环境',N'天气与气候',N'地形与河流'),
  (N'地理',3,N'区域地理',N'认识中国区域',N'认识世界区域');
  INSERT dbo.chapter(course_id,chapter_title,sort_order)
  SELECT c.course_id,x.chapter_title,x.chapter_no FROM @content x JOIN dbo.course c ON c.course_title=x.subject_name
  WHERE NOT EXISTS(SELECT 1 FROM dbo.chapter ch WHERE ch.course_id=c.course_id AND ch.sort_order=x.chapter_no);
  UPDATE ch SET chapter_title=x.chapter_title FROM dbo.chapter ch JOIN dbo.course c ON c.course_id=ch.course_id
  JOIN @content x ON x.subject_name=c.course_title AND x.chapter_no=ch.sort_order;
  INSERT dbo.lesson(chapter_id,lesson_title,sort_order,duration_seconds,video_url)
  SELECT ch.chapter_id,l.title,l.n,600+x.chapter_no*120+l.n*60,N'https://example.test/video/subject-lesson.mp4'
  FROM @content x JOIN dbo.course c ON c.course_title=x.subject_name
  JOIN dbo.chapter ch ON ch.course_id=c.course_id AND ch.sort_order=x.chapter_no
  CROSS APPLY(VALUES(1,x.lesson1),(2,x.lesson2)) l(n,title)
  WHERE NOT EXISTS(SELECT 1 FROM dbo.lesson old WHERE old.chapter_id=ch.chapter_id AND old.sort_order=l.n);
  UPDATE l SET lesson_title=CASE l.sort_order WHEN 1 THEN x.lesson1 ELSE x.lesson2 END,
   duration_seconds=600+x.chapter_no*120+l.sort_order*60
  FROM dbo.lesson l JOIN dbo.chapter ch ON ch.chapter_id=l.chapter_id JOIN dbo.course c ON c.course_id=ch.course_id
  JOIN @content x ON x.subject_name=c.course_title AND x.chapter_no=ch.sort_order WHERE l.sort_order IN(1,2);
  UPDATE c SET price=CASE c.course_title WHEN N'物理' THEN 259 WHEN N'化学' THEN 239 WHEN N'生物' THEN 189 WHEN N'政治' THEN 129 WHEN N'历史' THEN 169 WHEN N'地理' THEN 159 ELSE price END
  FROM dbo.course c WHERE course_title IN(N'物理',N'化学',N'生物',N'政治',N'历史',N'地理');
  DECLARE @students TABLE(n int PRIMARY KEY,student_name nvarchar(100),email nvarchar(254));
  INSERT @students VALUES
  (1,N'刘一诺',N'cohort01.demo@example.test'),
  (2,N'杨子涵',N'cohort02.demo@example.test'),
  (3,N'黄思远',N'cohort03.demo@example.test'),
  (4,N'陈雨桐',N'cohort04.demo@example.test'),
  (5,N'周梓轩',N'cohort05.demo@example.test'),
  (6,N'吴欣怡',N'cohort06.demo@example.test'),
  (7,N'徐浩然',N'cohort07.demo@example.test'),
  (8,N'孙诗涵',N'cohort08.demo@example.test'),
  (9,N'马宇航',N'cohort09.demo@example.test'),
  (10,N'朱可欣',N'cohort10.demo@example.test'),
  (11,N'胡嘉宁',N'cohort11.demo@example.test'),
  (12,N'郭晨曦',N'cohort12.demo@example.test'),
  (13,N'何书瑶',N'cohort13.demo@example.test'),
  (14,N'高俊杰',N'cohort14.demo@example.test'),
  (15,N'林沐阳',N'cohort15.demo@example.test'),
  (16,N'罗思琪',N'cohort16.demo@example.test'),
  (17,N'郑博文',N'cohort17.demo@example.test'),
  (18,N'梁若溪',N'cohort18.demo@example.test'),
  (19,N'谢星辰',N'cohort19.demo@example.test'),
  (20,N'宋安然',N'cohort20.demo@example.test');
  INSERT dbo.student(student_name,email,created_at)
  SELECT student_name,email,DATEADD(day,n,CONVERT(datetime2,'20261001')) FROM @students x
  WHERE NOT EXISTS(SELECT 1 FROM dbo.student s WHERE s.email=x.email);
  DECLARE @subjects TABLE(n int PRIMARY KEY,subject_name nvarchar(20));
  INSERT @subjects VALUES(0,N'物理'),(1,N'化学'),(2,N'生物'),(3,N'政治'),(4,N'历史'),(5,N'地理');
  DECLARE @seq int,@student int,@course int,@order bigint,@kind int,@mode int,@lesson int,@pct decimal(5,2),@rating tinyint,@created datetime2;
  DECLARE orders_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT (x.n-1)*3+k.n,s.student_id,c.course_id,DATEADD(minute,k.n*15,DATEADD(day,x.n,CONVERT(datetime2,'20261001')))
  FROM @students x JOIN dbo.student s ON s.email=x.email CROSS JOIN(VALUES(0),(1),(2)) k(n)
  JOIN @subjects d ON d.n=(x.n+k.n*2)%6 JOIN dbo.course c ON c.course_title=d.subject_name
  ORDER BY x.n,k.n;
  OPEN orders_cursor;
  FETCH NEXT FROM orders_cursor INTO @seq,@student,@course,@created;
  WHILE @@FETCH_STATUS=0
  BEGIN
   -- 每个新演示学员跨选三门课，种子版本标记防止重复生成历史订单。
   EXEC dbo.usp_CreateOrder @student,@course,@order OUTPUT;
   UPDATE dbo.order_info SET created_at=@created WHERE order_id=@order;
   SET @kind=@seq%10;
   IF @kind=1 EXEC dbo.usp_CancelOrder @student,@order;
   IF @kind>=2
   BEGIN
    EXEC dbo.usp_PayOrder @student,@order;
    UPDATE dbo.order_info SET paid_at=DATEADD(minute,5,@created) WHERE order_id=@order;
    SET @mode=@seq%5;
    DECLARE lessons_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT l.lesson_id,CAST(CASE WHEN @kind=2 THEN CASE WHEN ch.sort_order=1 AND l.sort_order=1 THEN 60 ELSE 0 END
      WHEN @mode=0 THEN 100 WHEN @mode=1 THEN 0
      WHEN @mode=2 THEN CASE WHEN ch.sort_order=1 AND l.sort_order=1 THEN 100 ELSE 0 END
      WHEN @mode=3 THEN 50 ELSE CASE WHEN ch.sort_order<=2 THEN 100 ELSE 25 END END AS decimal(5,2))
    FROM dbo.chapter ch JOIN dbo.lesson l ON l.chapter_id=ch.chapter_id WHERE ch.course_id=@course ORDER BY ch.sort_order,l.sort_order;
    OPEN lessons_cursor;
    FETCH NEXT FROM lessons_cursor INTO @lesson,@pct;
    WHILE @@FETCH_STATUS=0
    BEGIN
     IF @pct>0
     BEGIN
      EXEC dbo.usp_ReportProgress @student,@lesson,@pct;
      UPDATE dbo.learning_progress SET last_watched_at=DATEADD(day,1,@created) WHERE student_id=@student AND lesson_id=@lesson;
     END;
     FETCH NEXT FROM lessons_cursor INTO @lesson,@pct;
    END;
    CLOSE lessons_cursor;
    DEALLOCATE lessons_cursor;
    IF @kind=2
    BEGIN
     EXEC dbo.usp_RefundOrder @student,@order,N'演示：学习安排调整，进度低于退款阈值';
     UPDATE dbo.refund_record SET processed_at=DATEADD(day,2,@created) WHERE order_id=@order;
    END
    ELSE IF @seq%3<>0
    BEGIN
     SET @rating=3+@seq%3;
     EXEC dbo.usp_ReviewCourse @student,@course,@rating,N'讲解清楚，正在结合练习巩固知识。';
     UPDATE dbo.course_review SET created_at=DATEADD(day,2,@created) WHERE student_id=@student AND course_id=@course;
    END;
   END;
   FETCH NEXT FROM orders_cursor INTO @seq,@student,@course,@created;
  END;
  CLOSE orders_cursor;
  DEALLOCATE orders_cursor;
  EXEC sys.sp_addextendedproperty @name=N'education_demo_rich_v2',@value=N'9 teachers; 24 students; 9 courses; 60 additional orders';
  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO

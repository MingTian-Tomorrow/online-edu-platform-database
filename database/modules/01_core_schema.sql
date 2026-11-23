-- 1号：公共表、主外键、约束和索引。共同评审数据结构。
-- 此文件为模块源文件；修改后用 tools/build-bundles.ps1 同步统一入口。
-- SQL Server 2016 SP1+ / SSMS。独立新库，不删除或修改原 OnlineEducationDB。
USE master;
GO
IF DB_ID(N'OnlineEducationSQL') IS NULL
    EXEC(N'CREATE DATABASE OnlineEducationSQL');
GO
USE OnlineEducationSQL;
GO
SET XACT_ABORT ON;
GO
-- 整个建表批次原子执行；重复安装保留数据。
IF OBJECT_ID(N'dbo.schema_version', N'U') IS NULL
BEGIN
 BEGIN TRANSACTION;
 CREATE TABLE dbo.teacher (
   teacher_id int IDENTITY PRIMARY KEY, teacher_name nvarchar(100) NOT NULL,
   title nvarchar(100), bio nvarchar(1000)
 );
 CREATE TABLE dbo.student (
   student_id int IDENTITY PRIMARY KEY, student_name nvarchar(100) NOT NULL,
   email nvarchar(254) NOT NULL UNIQUE, created_at datetime2 NOT NULL DEFAULT SYSDATETIME()
 );
 CREATE TABLE dbo.course (
   course_id int IDENTITY PRIMARY KEY, course_title nvarchar(200) NOT NULL,
   teacher_id int NOT NULL REFERENCES dbo.teacher(teacher_id),
   description nvarchar(1000), price decimal(10,2) NOT NULL CHECK(price>=0),
   is_active bit NOT NULL DEFAULT 1
 );
 CREATE TABLE dbo.chapter (
   chapter_id int IDENTITY PRIMARY KEY, course_id int NOT NULL REFERENCES dbo.course(course_id),
   chapter_title nvarchar(200) NOT NULL, sort_order int NOT NULL CHECK(sort_order>0),
   UNIQUE(course_id,sort_order)
 );
 CREATE TABLE dbo.lesson (
   lesson_id int IDENTITY PRIMARY KEY, chapter_id int NOT NULL REFERENCES dbo.chapter(chapter_id),
   lesson_title nvarchar(200) NOT NULL, sort_order int NOT NULL CHECK(sort_order>0),
   duration_seconds int NOT NULL CHECK(duration_seconds>0), video_url nvarchar(500) NOT NULL,
   UNIQUE(chapter_id,sort_order)
 );
 -- 保留订单主表和明细；下单过程按原 Java 行为一次购买一门课程。
 CREATE TABLE dbo.order_info (
   order_id bigint IDENTITY PRIMARY KEY, order_no uniqueidentifier NOT NULL DEFAULT NEWID() UNIQUE,
   student_id int NOT NULL REFERENCES dbo.student(student_id),
   total_amount decimal(10,2) NOT NULL CHECK(total_amount>=0),
   status varchar(10) NOT NULL DEFAULT 'PENDING' CHECK(status IN('PENDING','PAID','REFUNDED','CANCELLED')),
   created_at datetime2 NOT NULL DEFAULT SYSDATETIME(), paid_at datetime2,
   CHECK((status IN('PENDING','CANCELLED') AND paid_at IS NULL) OR (status IN('PAID','REFUNDED') AND paid_at IS NOT NULL))
 );
 CREATE TABLE dbo.order_item (
   order_id bigint NOT NULL REFERENCES dbo.order_info(order_id),
   course_id int NOT NULL REFERENCES dbo.course(course_id),
   unit_price decimal(10,2) NOT NULL CHECK(unit_price>=0), PRIMARY KEY(order_id,course_id)
 );
 -- 不冗余存 course_id，从课时和章节外键推导，杜绝跨课程脏记录。
 CREATE TABLE dbo.learning_progress (
   student_id int NOT NULL REFERENCES dbo.student(student_id),
   lesson_id int NOT NULL REFERENCES dbo.lesson(lesson_id),
   progress_percent decimal(5,2) NOT NULL CHECK(progress_percent BETWEEN 0 AND 100),
   last_watched_at datetime2 NOT NULL DEFAULT SYSDATETIME(), PRIMARY KEY(student_id,lesson_id)
 );
 CREATE TABLE dbo.course_review (
   student_id int NOT NULL REFERENCES dbo.student(student_id),
   course_id int NOT NULL REFERENCES dbo.course(course_id),
   rating tinyint NOT NULL CHECK(rating BETWEEN 1 AND 5), content nvarchar(1000),
   created_at datetime2 NOT NULL DEFAULT SYSDATETIME(), PRIMARY KEY(student_id,course_id)
 );
 CREATE TABLE dbo.refund_policy (
   policy_id int NOT NULL PRIMARY KEY CHECK(policy_id=1),
   max_progress_percent decimal(5,2) NOT NULL CHECK(max_progress_percent BETWEEN 0 AND 100)
 );
 INSERT dbo.refund_policy VALUES(1,20);
 CREATE TABLE dbo.refund_record (
   refund_id bigint IDENTITY PRIMARY KEY,
   order_id bigint NOT NULL UNIQUE REFERENCES dbo.order_info(order_id),
   refund_amount decimal(10,2) NOT NULL CHECK(refund_amount>0), reason nvarchar(500),
   threshold_percent decimal(5,2) NOT NULL, observed_progress decimal(5,2) NOT NULL,
   processed_at datetime2 NOT NULL DEFAULT SYSDATETIME()
 );
 CREATE TABLE dbo.schema_version(version_number int PRIMARY KEY);
 INSERT dbo.schema_version VALUES(1);
 COMMIT;
END;
GO

-- 每个索引单独判断，支持重复运行及补建缺失索引。
-- 条件内使用动态 DDL，避免 SSMS 静态检查将已存在对象标为重复创建。
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.order_info') AND name=N'IX_order_student_status')
    EXEC(N'CREATE INDEX IX_order_student_status ON dbo.order_info(student_id,status) INCLUDE(paid_at,total_amount)');
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.order_item') AND name=N'IX_item_course_order')
    EXEC(N'CREATE INDEX IX_item_course_order ON dbo.order_item(course_id,order_id) INCLUDE(unit_price)');
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.learning_progress') AND name=N'IX_progress_lesson_student')
    EXEC(N'CREATE INDEX IX_progress_lesson_student ON dbo.learning_progress(lesson_id,student_id) INCLUDE(progress_percent,last_watched_at)');
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.course_review') AND name=N'IX_review_course')
    EXEC(N'CREATE INDEX IX_review_course ON dbo.course_review(course_id) INCLUDE(rating)');
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.course') AND name=N'IX_course_teacher')
    EXEC(N'CREATE INDEX IX_course_teacher ON dbo.course(teacher_id) INCLUDE(course_title,price)');
GO

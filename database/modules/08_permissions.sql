-- 8号：角色权限和集成验收。依赖 01～07；不自动绑定登录。
-- 此文件为模块源文件；修改后用 tools/build-bundles.ps1 同步统一入口。
USE OnlineEducationSQL;
GO
USE OnlineEducationSQL;
GO
-- 可选角色，安装时创建但不绑定任何登录。业务操作员通过过程写入，不能直接改订单/进度。
-- 条件内动态创建，避免编辑器将已存在的角色标为重复定义。
IF DATABASE_PRINCIPAL_ID(N'education_operator') IS NULL
    EXEC(N'CREATE ROLE education_operator');
GRANT SELECT ON SCHEMA::dbo TO education_operator;
GRANT EXECUTE ON dbo.usp_CreateOrder TO education_operator;
GRANT EXECUTE ON dbo.usp_PayOrder TO education_operator;
GRANT EXECUTE ON dbo.usp_CancelOrder TO education_operator;
GRANT EXECUTE ON dbo.usp_ReportProgress TO education_operator;
GRANT EXECUTE ON dbo.usp_ReviewCourse TO education_operator;
GRANT EXECUTE ON dbo.usp_RefundOrder TO education_operator;
GRANT EXECUTE ON dbo.usp_StudentCourses TO education_operator;
GRANT EXECUTE ON dbo.usp_CourseStudents TO education_operator;
DENY INSERT,UPDATE,DELETE ON dbo.order_info TO education_operator;
DENY INSERT,UPDATE,DELETE ON dbo.order_item TO education_operator;
DENY INSERT,UPDATE,DELETE ON dbo.learning_progress TO education_operator;
DENY INSERT,UPDATE,DELETE ON dbo.course_review TO education_operator;
DENY INSERT,UPDATE,DELETE ON dbo.refund_record TO education_operator;
DENY INSERT,UPDATE,DELETE ON dbo.refund_policy TO education_operator;
GO

-- 7号：管理员修改阈值的示例，默认回滚，不改变演示基准。
USE OnlineEducationSQL;
GO
BEGIN TRAN;
UPDATE dbo.refund_policy SET max_progress_percent=20 WHERE policy_id=1;
SELECT * FROM dbo.refund_policy;
ROLLBACK;
GO

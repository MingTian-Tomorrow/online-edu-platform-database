-- 7号：退款事务、阈值校验和幂等。依赖 01；与 03、04 约定同一加锁顺序。
-- 此文件为模块源文件；修改后用 tools/build-bundles.ps1 同步统一入口。
USE OnlineEducationSQL;
GO
CREATE OR ALTER PROCEDURE dbo.usp_RefundOrder
 @StudentId int,@OrderId bigint,@Reason nvarchar(max)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRAN;
  IF DATALENGTH(@Reason)>1000 THROW 51014,N'退款原因最多 500 个 UTF-16 字符',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.student WITH(UPDLOCK,HOLDLOCK) WHERE student_id=@StudentId)
   THROW 51001,N'学员不存在',1;
  DECLARE @status varchar(10),@amount decimal(10,2),@threshold decimal(5,2),@progress decimal(18,8);
  SELECT @status=status,@amount=total_amount FROM dbo.order_info WITH(UPDLOCK,HOLDLOCK)
   WHERE order_id=@OrderId AND student_id=@StudentId;
  IF @status IS NULL THROW 51004,N'订单不存在或不属于该学员',1;
  -- 重复调用幂等：只返回已有退款，不再次退款。
  IF @status='REFUNDED' AND EXISTS(SELECT 1 FROM dbo.refund_record WHERE order_id=@OrderId AND refund_amount=@amount)
  BEGIN
   COMMIT;
   SELECT * FROM dbo.refund_record WHERE order_id=@OrderId;
   RETURN;
  END;
  IF @status<>'PAID' OR @amount<=0 THROW 51015,N'仅正金额已支付订单可以退款',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.order_item WHERE order_id=@OrderId)
    OR @amount<>(SELECT SUM(unit_price) FROM dbo.order_item WHERE order_id=@OrderId)
   THROW 51006,N'订单明细与金额不一致',1;
  SELECT @threshold=max_progress_percent FROM dbo.refund_policy WITH(HOLDLOCK) WHERE policy_id=1;
  IF @threshold IS NULL THROW 51016,N'缺少退款策略',1;
  -- 多课程订单逐门核验，取最大值；使用原始精度比较，避免四舍五入放过超限进度。
  SELECT @progress=MAX(x.progress_percent)
  FROM dbo.order_item i
  CROSS APPLY(SELECT COALESCE(AVG(CAST(COALESCE(p.progress_percent,0) AS decimal(18,8))),0) progress_percent
    FROM dbo.chapter ch JOIN dbo.lesson l ON l.chapter_id=ch.chapter_id
    LEFT JOIN dbo.learning_progress p ON p.lesson_id=l.lesson_id AND p.student_id=@StudentId
    WHERE ch.course_id=i.course_id) x
  WHERE i.order_id=@OrderId;
  IF @progress>@threshold THROW 51017,N'学习进度超过退款阈值，不可退款',1;
  INSERT dbo.refund_record(order_id,refund_amount,reason,threshold_percent,observed_progress)
   VALUES(@OrderId,@amount,@Reason,@threshold,@progress);
  UPDATE dbo.order_info SET status='REFUNDED' WHERE order_id=@OrderId;
  COMMIT;
  SELECT * FROM dbo.refund_record WHERE order_id=@OrderId;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO

-- 3号：订单、支付、取消及公共有效选课关系。依赖 01。
-- 此文件为模块源文件；修改后用 tools/build-bundles.ps1 同步统一入口。
USE OnlineEducationSQL;
GO
CREATE OR ALTER VIEW dbo.v_enrollment AS
SELECT DISTINCT o.student_id,i.course_id
FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id
WHERE o.status='PAID';
GO
-- 所有学员写入先锁 student 同一行；支付、进度、评价、退款按相同顺序串行化。
CREATE OR ALTER PROCEDURE dbo.usp_CreateOrder
 @StudentId int,@CourseId int,@OrderId bigint OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRAN;
  IF NOT EXISTS(SELECT 1 FROM dbo.student WITH(UPDLOCK,HOLDLOCK) WHERE student_id=@StudentId)
   THROW 51001,N'学员不存在',1;
  DECLARE @price decimal(10,2);
  SELECT @price=price FROM dbo.course WITH(HOLDLOCK) WHERE course_id=@CourseId AND is_active=1;
  IF @price IS NULL THROW 51002,N'课程不存在或已下架',1;
  IF EXISTS(SELECT 1 FROM dbo.order_info o JOIN dbo.order_item i ON i.order_id=o.order_id
    WHERE o.student_id=@StudentId AND i.course_id=@CourseId AND o.status IN('PENDING','PAID'))
   THROW 51003,N'已有待支付或有效已购订单',1;
  INSERT dbo.order_info(student_id,total_amount) VALUES(@StudentId,@price);
  SET @OrderId=SCOPE_IDENTITY();
  INSERT dbo.order_item VALUES(@OrderId,@CourseId,@price);
  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_PayOrder @StudentId int,@OrderId bigint
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRAN;
  IF NOT EXISTS(SELECT 1 FROM dbo.student WITH(UPDLOCK,HOLDLOCK) WHERE student_id=@StudentId)
   THROW 51001,N'学员不存在',1;
  DECLARE @status varchar(10),@amount decimal(10,2);
  SELECT @status=status,@amount=total_amount FROM dbo.order_info WITH(UPDLOCK,HOLDLOCK)
   WHERE order_id=@OrderId AND student_id=@StudentId;
  IF @status IS NULL THROW 51004,N'订单不存在或不属于该学员',1;
  IF @status NOT IN('PENDING','PAID') THROW 51005,N'订单不可支付',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.order_item WHERE order_id=@OrderId)
    OR @amount<>(SELECT SUM(unit_price) FROM dbo.order_item WHERE order_id=@OrderId)
   THROW 51006,N'订单明细与金额不一致',1;
  UPDATE dbo.order_info SET status='PAID',paid_at=SYSDATETIME() WHERE order_id=@OrderId AND status='PENDING';
  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_CancelOrder @StudentId int,@OrderId bigint
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRAN;
  IF NOT EXISTS(SELECT 1 FROM dbo.student WITH(UPDLOCK,HOLDLOCK) WHERE student_id=@StudentId)
   THROW 51001,N'学员不存在',1;
  UPDATE dbo.order_info SET status='CANCELLED' WHERE order_id=@OrderId AND student_id=@StudentId AND status='PENDING';
  IF @@ROWCOUNT<>1 THROW 51007,N'仅本人待支付订单可取消',1;
  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO

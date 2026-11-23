# 八人模块协作说明

以下是建议的责任分工，不代表已经由八位成员实际完成。每位成员应亲自阅读、修改或验证自己的模块，并保留操作记录。

| 成员 | 主文件（相对于 database） | 负责对象 | 自测/演示 |
| --- | --- | --- | --- |
| 1号 | modules/01_core_schema.sql | 12 张表（含版本标记）、关系约束、索引 | 表结构和外键检查；与各模块共同评审 |
| 2号 | modules/02_course_catalog.sql | v_course_catalog | tests/02_course_tests.sql、examples/02_course_admin.sql |
| 3号 | modules/03_orders.sql | v_enrollment、usp_CreateOrder、usp_PayOrder、usp_CancelOrder | tests/03_order_tests.sql |
| 4号 | modules/04_learning.sql | v_student_course_progress、usp_ReportProgress、usp_StudentCourses、usp_CourseStudents | tests/04_learning_tests.sql；91_demo 中查询计划 |
| 5号 | modules/05_completion.sql | v_course_completion | tests/05_completion_tests.sql |
| 6号 | modules/06_reviews_ranking.sql | usp_ReviewCourse、v_hot_courses | tests/06_review_ranking_tests.sql |
| 7号 | modules/07_refunds.sql | usp_RefundOrder | tests/07_refund_tests.sql、examples/07_refund_policy.sql |
| 8号 | modules/08_permissions.sql | education_operator 角色、授权 | tests/09_integration_tests.sql、tests/10_dataset_tests.sql；整合 92_acceptance |

## 公共内容怎样协作

所有建表语句统一保留在 01，避免每个模块各建一份相同的表。模块负责人提出字段和约束需求，由 1 号协调落地。90_seed 和 91_demo 为团队共享，由 8 号整合，其他成员维护自己负责的示例部分。八位成员各自维护测试，8 号负责把它们集成到验收入口，不承担其他人的全部测试工作。

04 的“学员课程汇总视图”供其两个查询过程和 05 复用；05 专注“课程总体完成率”。这样先执行 04 再执行 05，无需依赖 SQL Server 的存储过程延迟名称解析，也避免循环依赖。

## 安装依赖

- 01：建立公共表、约束及索引。
- 02：依赖 01，建立课程目录。
- 03：依赖 01，建立订单流程和有效选课关系。
- 04：依赖 03 的有效选课关系，建立进度和查询。
- 05：依赖 04 的学员课程汇总。
- 06：依赖 03 的有效选课及 05 的完成率。
- 07：使用公共表；与订单、进度共享学员锁定顺序。
- 08：引用前面全部过程，最后授权。
- 90：调用订单、学习、评价和退款过程生成数据，因此在所有模块之后执行。

## 旧文件对应新位置

| 旧 database/sqlserver 文件 | 新位置 |
| --- | --- |
| 00_install.sql | database/00_install.sql（生成入口） |
| 01_schema.sql | modules/01_core_schema.sql |
| 02_views.sql | 按业务分入 02、03、04、05、06 模块 |
| 03_procedures.sql | 按业务分入 03、04、06、07 模块 |
| 04_seed.sql | 90_seed.sql，并更新为九门学科 |
| 05_demo.sql | 91_demo.sql |
| 06_tests.sql | tests 下各模块及集成测试；由 92_acceptance.sql 统一执行 |
| 07_admin_examples.sql | examples/02_course_admin.sql、examples/07_refund_policy.sql |
| 08_permissions.sql | modules/08_permissions.sql |

模块源文件中每个视图和存储过程只定义一次；00_install 是它们的自动生成发行副本，不是另一个人工维护的实现。92_acceptance 同理。

## 每人汇报前完成

1. 说明本模块的输入、输出、涉及哪些表、依赖谁。
2. 执行自己的测试，并解释一条成功和一条预期失败的结果（统计模块可选两个边界计算）。
3. 保存实际运行的 SQL、结果和问题分析，不把文件归属当作已经完成工作的证明。
4. 修改模块后重新生成入口，再运行自己的测试及完整验收。
5. 数据修改演示使用独立事务，结束后回滚；业务过程异常会回滚调用者外层事务。

所有人都应理解平均学习进度与完成率的区别、PAID 有效购买关系、退款原子性和安装顺序。不要声称执行过未实际运行的性能、权限或并发实验。

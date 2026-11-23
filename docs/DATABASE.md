# 数据库设计与业务口径

## 数据关系

teacher 1:N course；course 1:N chapter；chapter 1:N lesson。
student 1:N order_info；order_info 1:N order_item；course 1:N order_item，构成学员与课程多对多。
student 与 lesson 经 learning_progress 多对多；student 与 course 经 course_review 多对多。
order_info 1:0..1 refund_record；refund_policy 是仅允许 policy_id=1 的配置表。

进度表以 (student_id,lesson_id) 为主键，含百分比及最后观看时间。课程归属由课时→章节推导，避免独立 course_id 和 lesson_id 不一致。评价以 (student_id,course_id) 为主键，评分 1～5。所有业务关系具有外键；已使用资料不可硬删除。

## 统计定义

- 有效学员：PAID 订单的去重购买者。未开始学习计入分母，退款者不计入。
- 课程学习进度：所有课时百分比的等权平均；未观看为 0，与时长无关。
- 完成全部课时：课程至少有一个课时，并且每个课时进度为 100%。
- 课程完成率：完成人数 / 有效学员人数 × 100；无人购买或空课程为 0。
- 热门榜仅包含上架课程。购买量为有效购买人数；评分为有效已购学员历史评价的平均分，无评价为 0。
- 综合分 = 40 × 购买量/榜内最大购买量 + 30 × 平均评分/5 + 0.30 × 完课率百分比。无人购买时为 0；并列按购买量、课程 ID 排序。

## 订单与退款

PENDING → PAID → REFUNDED；PENDING → CANCELLED。订单创建和明细写入同一事务，价格从课程表读取。当前下单过程与原 Java 行为一致，一次购买一门课程；退款校验仍支持逐项处理多课程明细。

同一学员同一课程不能重复创建待支付或有效订单。取消/退款后可以重新下单。历史进度和评价保留，重新购买不会重置；可阻止反复购买重置退款进度。

N 在 refund_policy 中设置，默认 20。整门课程平均学习进度大于 N 拒绝，等于 N 允许。多个课程的订单只要任一课程超限就整单拒绝。判断使用未四舍五入的平均值。空课程平均值为 0。零金额订单可购买、学习，不能产生退款。

退款在同一事务内锁定学员、订单、策略，校验所有权、订单状态、主从金额及进度，插入退款记录后更新订单。退款记录保存当时阈值和进度，order_id 唯一。重复退款返回已有记录。异常使用 THROW 并回滚，不留下半成品。

支付、学习、评价、退款均先以 UPDLOCK/HOLDLOCK 锁定同一 student 行，统一加锁顺序，串行处理该学员的业务操作。进度只递增，防止通过降低进度绕过退款。事务过程失败时回滚整个活动事务，包括调用者外层事务；调用者不应在外层混入无关工作。

业务操作员通过过程写入，不能直接修改业务表；管理员直接 DML 是管理通道，可绕过过程级业务校验，因此展示业务操作应使用过程。课程课时在授课期间应保持稳定；新增课时会改变当前完成率和平均进度，这是按当前课程结构统计的定义。

## 基础资料管理

管理员可用 INSERT/UPDATE/DELETE 管理讲师、学员、课程、章节、课时；外键防止删除被引用资料。参考 database/examples/02_course_admin.sql。下架用 course.is_active=0，下架后禁止新下单，已有学员保留学习资格。

查询入口：v_course_catalog、student、order_info JOIN order_item、course_review、refund_record，以及两个查询过程。

## 索引与执行计划

1. IX_order_student_status(student_id,status) INCLUDE(paid_at,total_amount)：某学员有效课程列表。
2. IX_item_course_order(course_id,order_id) INCLUDE(unit_price)：从课程定位购买订单。
3. learning_progress 的主键 (student_id,lesson_id)：学员课时查询、进度更新。
4. IX_progress_lesson_student(lesson_id,student_id) INCLUDE(progress_percent,last_watched_at)：课程课时反查学员进度。
5. chapter(course_id,sort_order)、lesson(chapter_id,sort_order) 的唯一索引：三级目录连接与排序。
6. IX_review_course、IX_course_teacher：评分聚合、讲师课程检索。

database/91_demo.sql 打开 STATISTICS IO/TIME；SSMS Ctrl+M 查看实际计划。小样本可能选择扫描，这是优化器正常选择，不能宣称一定使用 Seek 或保证加速倍数。若要量化性能，应在相同规模/缓存条件下对比逻辑读取与执行时间。

## 模块归属

建表和索引统一在 modules/01_core_schema.sql。v_enrollment 属于订单模块 03；v_student_course_progress 属于学习模块 04；v_course_completion 属于统计模块 05；评价与排行属于 06；退款属于 07。完整归属及依赖见 TEAM.md。

演示课程名称为语文、数学、英语、物理、化学、生物、政治、历史、地理。业务公式、退款阈值和对象名称不因课程改名而变化。

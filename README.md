# 在线教育学习平台 · 八人模块协作版

项目使用 SQL Server / T-SQL 实现，无 Java 后端或前端。8 个模块各有一位主要负责人；公共表统一维护，业务对象不在多个源模块重复定义。

## SSMS 直接运行

1. 连接 `.\SQLEXPRESS`（本机使用 Windows 身份验证）。
2. 执行 `database/00_install.sql` 全文，建立/更新 `OnlineEducationSQL` 并加载演示数据。无需 SQLCMD 模式。
3. 执行 `database/91_demo.sql`，展示题目全部功能。
4. 执行 `database/92_acceptance.sql`，成功时显示 25 条 PASS 和 ALL TESTS PASSED。

不要把整个目录的所有文件再执行一遍：00 已包含 8 个模块和 90_seed；92 已包含各测试文件。已有 SSMS 解决方案请移除旧 database/sqlserver 路径的文件引用，添加下方新文件。SQL 文件只是脚本，SSMS 解决方案不会另外建立一套数据库。

## 目录与负责人

```text
database/
├─ modules/
│  ├─ 01_core_schema.sql       # 1号：公共表、关系、约束和索引
│  ├─ 02_course_catalog.sql    # 2号：课程目录
│  ├─ 03_orders.sql            # 3号：下单、支付、取消、有效选课
│  ├─ 04_learning.sql          # 4号：进度上报、学员课程汇总和查询
│  ├─ 05_completion.sql        # 5号：课程完成率
│  ├─ 06_reviews_ranking.sql   # 6号：评价、热门排行
│  ├─ 07_refunds.sql           # 7号：退款事务
│  └─ 08_permissions.sql       # 8号：权限、集成验收
├─ tests/                     # 各成员负责的测试，含跨模块集成测试
├─ examples/                  # 课程管理、退款策略的回滚演示
├─ tools/build-bundles.ps1    # 仅合并 SQL 文本，不连接数据库
├─ 00_install.sql             # 自动生成的完整安装入口
├─ 90_seed.sql                # 公共演示数据及旧课程改名
├─ 91_demo.sql                # 题目六项要求的完整展示
└─ 92_acceptance.sql          # 自动生成的统一验收入口
```

详细职责、依赖和旧文件映射见 [docs/TEAM.md](docs/TEAM.md)。数据规则见 [docs/DATABASE.md](docs/DATABASE.md)，验证说明见 [docs/TESTING.md](docs/TESTING.md)。

## 单独开发与同步入口

只修改自己的 `modules/xx_*.sql` 和对应测试。公共表的变更交给 1 号协调；跨模块调用先约定对象名、参数和返回列。修改后在项目根目录执行：

```powershell
& ./database/tools/build-bundles.ps1
& ./database/tools/build-bundles.ps1 -Check
```

工具仅生成或检查 00_install 和 92_acceptance 的文本，不操作数据库；SSMS 使用生成后的 SQL 不需要运行 PowerShell。不要直接编辑生成入口，否则下次生成会覆盖改动。

也可单独按 modules/01～08 的顺序安装，再执行 90_seed。04 定义学员课程汇总视图，05 使用它计算课程总体完成率，因此编号顺序就是依赖顺序。

命令行执行：

```powershell
sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -i database/00_install.sql
sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -i database/91_demo.sql
sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -i database/92_acceptance.sql
```

## 九门演示课程

语文、数学、英语、物理、化学、生物、政治、历史、地理。

- 语文：2 个课时、4 位有效学员、1 位全部完成，完成率 25%，平均评分 4.5。
- 数学：1 个课时、1 位有效学员全部完成，另有一笔历史退款，完成率 100%。
- 英语：保留尚无课时的边界案例，完成率 0%。
- 其余六门：每门 3 章、每章 2 个课时，包含符合学科的课时名称和不同学习阶段。
- 9 位讲师分别负责九科；24 名学员，其中新增的 20 人各选 3 门课程。
- 合计 21 章、39 课时、66 笔订单、197 条课时进度、31 条评价、7 笔成功退款。
- 订单包含待支付 6 笔、已取消 6 笔、有效已支付 47 笔、已退款 7 笔。
- 扩展案例包含未开始、部分完成、全部完成、低进度退款，以及不同价格和日期。

以上数量以未手动修改的演示基准为准。完整讲师对应、数据分布及汇报建议见 [docs/DEMO_DATA.md](docs/DEMO_DATA.md)。

90_seed 会把上一版三门数据库类课程改名，保留 course_id、订单、学习和评价记录；补充其余六门，不清空数据库。若新旧同名目标已同时存在，会报错要求核对，避免擅自合并。丰富数据在一个事务中加载，并使用数据库扩展属性 education_demo_rich_v2 标记完成，重复执行不会再次插入60笔订单。安装和加载演示数据可重复执行，但不会重置用户修改过的进度或评价。不要手动删除版本标记来强制重灌。课程 ID 不一定连续，查询请按实际数据确定。

## 项目范围与备份

支付和退款模拟数据库状态变化，不处理真实资金；视频只保存占位地址。账户由 SQL Server 管理，不包含 Web 登录。操作员角色用于管理全部学员，不提供按学员账号隔离的访问规则。

原数据库 OnlineEducationDB 保持不变。本次数据扩展前的脚本备份在项目同级 online-education-before-rich-data.zip。旧 Java 文件备份在项目同级 online-education-legacy-backup.zip。本次整理前的 SQL 和说明备份在项目同级 online-education-before-modules.zip，可按原相对路径恢复。

最低语法版本 SQL Server 2016 SP1；实际验证环境 SQL Server 2025 Express。SSMS 若只在错误列表看到提示，请查看执行后的消息页确认实际错误；不要为清理编辑器提示而删库。

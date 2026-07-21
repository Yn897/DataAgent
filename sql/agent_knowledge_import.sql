-- 智能体知识库批量导入 SQL
-- 智能体ID: 5
-- 场景：资源治理平台核心数据（bdp_machine_stat_history / container_zone_agg_daily /
--       machine_monitor_group_agg_daily / machine_component_agg_daily）
-- 类型说明：DOCUMENT=背景/SOP/Schema说明，QA=标准问法+SQL示例，FAQ=常见概念问答

-- 如需重新导入，可先删除旧数据：
-- DELETE FROM agent_knowledge WHERE agent_id = 5 AND is_deleted = 0
--   AND title IN (
--     '资源治理四张核心表说明',
--     '资源治理分析标准流程',
--     '资源治理指标体系与字段口径',
--     '查询监控组低利用率机器占比',
--     '查询需要CPU治理的Zone',
--     '查询连续空闲超过N天的机器清单',
--     '按组件对比CPU日均利用率',
--     '查询某产品YARN组件空闲机器数',
--     '查询Zone CPU和内存分配率趋势',
--     '四张核心表分别解决什么问题',
--     '低利用率机器和空闲机器有什么区别',
--     '生产资源统计是否需要排除测试机',
--     'YARN空闲和通用空闲有什么区别'
--   );

INSERT INTO `agent_knowledge` (
  `agent_id`,
  `title`,
  `content`,
  `type`,
  `question`,
  `is_recall`,
  `embedding_status`,
  `file_type`,
  `splitter_type`,
  `created_time`,
  `updated_time`,
  `is_deleted`,
  `is_resource_cleaned`
) VALUES

-- ========== DOCUMENT：背景与 Schema ==========
(
  5,
  '资源治理四张核心表说明',
  '资源治理平台有四张核心日表，分析时必须先选对表：

1) bdp_machine_stat_history（机器明细快照）
- 粒度：date_day + 单机（IP/SN）
- 用途：查某台机器、按IP/机房/产品/监控组筛选、看是否低利用/空闲、看组件部署情况、看连续治理天数
- 关键字段：date_day, ip, sn, product_name, siyuan_monitor_group, is_low_utilization, is_idle_machine, low_util_consecutive_days, idle_machine_consecutive_days, contain_yarn, contain_hdfs, deploy_type, is_test, bdp_own

2) container_zone_agg_daily（Zone日聚合）
- 粒度：date_day + jdos_cluster_name + jdos_cluster_zone
- 用途：Zone维度CPU/内存水位、分配率、是否需要治理
- 关键字段：host_count, total_vcpus, allocatable_vcpus, vcpus_used, cpu_alloc_rate, cpu_need_governance, memory_alloc_rate, memory_need_governance

3) machine_monitor_group_agg_daily（监控组日聚合）
- 粒度：date_day + siyuan_monitor_group + product_name
- 用途：按监控组看机器总数、低利用/空闲数量与占比、CPU/内存/磁盘/网络利用率
- 关键字段：total_machine_count, low_utilization_count, low_utilization_percent, idle_machine_count, idle_machine_percent, avg_cpu_usage

4) machine_component_agg_daily（组件日聚合）
- 粒度：date_day + component + product_name
- 用途：按中间件组件（yarn/hbase/clickhouse/doris等）对比资源利用率与空闲情况
- 关键字段：component, total_machine_count, low_utilization_percent, idle_machine_percent, avg_cpu_usage

选表原则：
- 问“哪台机器/哪些IP” → bdp_machine_stat_history
- 问“哪个Zone需要治理/CPU分配率” → container_zone_agg_daily
- 问“哪个监控组空闲率高” → machine_monitor_group_agg_daily
- 问“哪个组件利用率低” → machine_component_agg_daily
- 时间过滤统一用 date_day。',
  'DOCUMENT',
  NULL,
  1,
  'PENDING',
  'text',
  'token',
  NOW(),
  NOW(),
  0,
  0
),

(
  5,
  '资源治理分析标准流程',
  '进行资源治理分析时，建议按以下标准流程：

步骤1：明确分析维度
- 单机明细 / 监控组 / 组件 / Zone 四选一，不要混表口径。

步骤2：确定时间范围
- 统一使用 date_day 过滤，例如：WHERE date_day BETWEEN ''2026-07-01'' AND ''2026-07-07''。
- 趋势分析按 date_day 分组排序。

步骤3：确定统计对象
- 生产统计通常排除测试机：is_test = -1（仅明细表）。
- BDP自有资源：bdp_own = 1（仅明细表）。

步骤4：选择核心指标
- 规模：total_machine_count / host_count
- 风险：low_utilization_percent / idle_machine_percent
- 水位：cpu_alloc_rate / memory_alloc_rate
- 治理：cpu_need_governance / memory_need_governance
- 持续性：low_util_consecutive_days / idle_machine_consecutive_days

步骤5：下钻路径（推荐）
- 先看聚合表找问题分组（监控组/组件/Zone）
- 再回明细表 bdp_machine_stat_history 查具体 IP/SN 清单

步骤6：输出报告建议包含
- 时间范围、统计口径（是否排除测试机）
- 问题分组TopN（低利用占比/空闲占比/治理Zone数）
- 关键趋势（按天）
- 可治理建议（回收、混部、缩容、迁移）',
  'DOCUMENT',
  NULL,
  1,
  'PENDING',
  'text',
  'token',
  NOW(),
  NOW(),
  0,
  0
),

(
  5,
  '资源治理指标体系与字段口径',
  '资源治理平台常用指标口径如下：

【机器规模】
- 机器总数：machine_monitor_group_agg_daily.total_machine_count 或 machine_component_agg_daily.total_machine_count
- 宿主机数：container_zone_agg_daily.host_count

【低利用与空闲】
- 低利用率机器数：low_utilization_count；占比：low_utilization_percent（%）
- 空闲机器数：idle_machine_count；占比：idle_machine_percent（%）
- 单机标识（明细表）：is_low_utilization=1，is_idle_machine=1

【CPU/内存水位（Zone）】
- CPU分配率 = vcpus_used / allocatable_vcpus，字段 cpu_alloc_rate
- 内存分配率 = memory_mb_used / allocatable_memory_mb，字段 memory_alloc_rate
- 需要治理：cpu_need_governance=1 或 memory_need_governance=1

【利用率（聚合表）】
- CPU日均：avg_cpu_usage（%）
- CPU峰值：peak_cpu_usage（%）
- 内存日均：avg_mem_usage（%）
- 磁盘日均：avg_disk_usage（%）
- 网络吞吐：avg_net_rx_tx_mbps（Mbps）

【利用率（明细表）】
- CPU：avg_cpu / peak_cpu / p50_cpu / max_cpu（%）
- 内存：avg_mem / peak_mem（%）
- 磁盘：avg_disk / peak_disk（%）
- 网络：avg_net_rx、avg_net_tx（MB/s）

【组件维度】
- 是否部署某组件：contain_yarn、contain_hdfs、contain_clickhouse 等（1是，-1否）
- 组件实例规模：xxx_instance_count、xxx_machine_count

【注意】
- 明细表网络单位是 MB/s，聚合表网络单位是 Mbps，不可直接比较数值。
- 空闲机器定义通常严于低利用率机器。',
  'DOCUMENT',
  NULL,
  1,
  'PENDING',
  'text',
  'token',
  NOW(),
  NOW(),
  0,
  0
),

-- ========== QA：标准问法 + SQL 示例 ==========
(
  5,
  '查询监控组低利用率机器占比',
  'SELECT
  date_day,
  siyuan_monitor_group,
  product_name,
  total_machine_count,
  low_utilization_count,
  low_utilization_percent
FROM machine_monitor_group_agg_daily
WHERE date_day = ''2026-07-12''
  AND siyuan_monitor_group = ''目标监控组''
ORDER BY low_utilization_percent DESC;

说明：
1. 低利用率占比直接读 low_utilization_percent，不要自己重算（除非要校验）。
2. 查Top监控组时去掉监控组条件，按 low_utilization_percent DESC LIMIT N。',
  'QA',
  '查询某个监控组在某天的低利用率机器占比',
  1,
  'PENDING',
  'text',
  'token',
  NOW(),
  NOW(),
  0,
  0
),

(
  5,
  '查询需要CPU治理的Zone',
  'SELECT
  date_day,
  jdos_cluster_name,
  jdos_cluster_zone,
  jdos_zone_product_own,
  host_count,
  cpu_alloc_rate,
  cpu_status,
  cpu_governance_reason,
  cpu_low_consecutive_days,
  cpu_high_consecutive_days
FROM container_zone_agg_daily
WHERE date_day = ''2026-07-12''
  AND cpu_need_governance = 1
ORDER BY cpu_alloc_rate ASC;

说明：
1. 需要治理条件：cpu_need_governance = 1。
2. 原因字段：cpu_governance_reason（LOW/HIGH）。
3. 若问“内存需要治理”，改用 memory_need_governance = 1。',
  'QA',
  '查询某天需要CPU治理的Zone列表',
  1,
  'PENDING',
  'text',
  'token',
  NOW(),
  NOW(),
  0,
  0
),

(
  5,
  '查询连续空闲超过N天的机器清单',
  'SELECT
  date_day,
  ip,
  sn,
  product_name,
  siyuan_monitor_group,
  idle_machine_consecutive_days,
  is_idle_machine
FROM bdp_machine_stat_history
WHERE date_day = ''2026-07-12''
  AND is_idle_machine = 1
  AND idle_machine_consecutive_days >= 7
  AND is_test = -1
ORDER BY idle_machine_consecutive_days DESC;

说明：
1. 连续空闲天数看 idle_machine_consecutive_days。
2. 生产口径建议加 is_test = -1 排除测试机。
3. 若问YARN空闲，改用 is_yarn_idle = 1 和 yarn_idle_consecutive_days。',
  'QA',
  '查询连续空闲超过7天的机器有哪些',
  1,
  'PENDING',
  'text',
  'token',
  NOW(),
  NOW(),
  0,
  0
),

(
  5,
  '按组件对比CPU日均利用率',
  'SELECT
  date_day,
  component,
  product_name,
  total_machine_count,
  avg_cpu_usage,
  peak_cpu_usage,
  low_utilization_percent,
  idle_machine_percent
FROM machine_component_agg_daily
WHERE date_day = ''2026-07-12''
ORDER BY avg_cpu_usage ASC;

说明：
1. 组件对比优先用 machine_component_agg_daily。
2. 常见 component：yarn、hbase、clickhouse、doris、flink、kafka。
3. 若指定产品，增加 AND product_name = ''目标产品''。',
  'QA',
  '按组件对比某天的CPU日均利用率',
  1,
  'PENDING',
  'text',
  'token',
  NOW(),
  NOW(),
  0,
  0
),

(
  5,
  '查询某产品YARN组件空闲机器数',
  'SELECT
  date_day,
  component,
  product_name,
  total_machine_count,
  idle_machine_count,
  idle_machine_percent
FROM machine_component_agg_daily
WHERE date_day = ''2026-07-12''
  AND component = ''yarn''
  AND product_name = ''目标产品'';

如需下钻到具体机器：
SELECT ip, sn, siyuan_monitor_group, is_idle_machine, idle_machine_consecutive_days
FROM bdp_machine_stat_history
WHERE date_day = ''2026-07-12''
  AND product_name = ''目标产品''
  AND contain_yarn = 1
  AND is_idle_machine = 1
  AND is_test = -1;',
  'QA',
  '查询某产品YARN组件在某天的空闲机器数',
  1,
  'PENDING',
  'text',
  'token',
  NOW(),
  NOW(),
  0,
  0
),

(
  5,
  '查询Zone CPU和内存分配率趋势',
  'SELECT
  date_day,
  jdos_cluster_name,
  jdos_cluster_zone,
  cpu_alloc_rate,
  memory_alloc_rate,
  cpu_need_governance,
  memory_need_governance
FROM container_zone_agg_daily
WHERE jdos_cluster_name = ''目标集群''
  AND jdos_cluster_zone = ''目标Zone''
  AND date_day BETWEEN ''2026-07-01'' AND ''2026-07-12''
ORDER BY date_day;

说明：
1. Zone趋势分析统一查 container_zone_agg_daily。
2. 可同时观察 cpu_need_governance / memory_need_governance 变化。',
  'QA',
  '查询某个Zone最近一段时间的CPU和内存分配率趋势',
  1,
  'PENDING',
  'text',
  'token',
  NOW(),
  NOW(),
  0,
  0
),

-- ========== FAQ：概念问答 ==========
(
  5,
  '四张核心表分别解决什么问题',
  '四张表按分析粒度分工：
1. bdp_machine_stat_history：单机明细（IP/SN级），用于清单和下钻。
2. container_zone_agg_daily：Zone资源水位与治理（CPU/内存分配率、是否需治理）。
3. machine_monitor_group_agg_daily：监控组大盘（机器数、低利用/空闲占比、利用率）。
4. machine_component_agg_daily：组件大盘（yarn/hbase/clickhouse/doris等）。

经验法则：
- 先聚合找问题，再明细找机器。',
  'FAQ',
  '资源治理平台四张核心表分别用来做什么？',
  1,
  'PENDING',
  'text',
  'token',
  NOW(),
  NOW(),
  0,
  0
),

(
  5,
  '低利用率机器和空闲机器有什么区别',
  '低利用率机器：资源有使用但长期偏低，字段 is_low_utilization=1，连续天数 low_util_consecutive_days。
空闲机器：基本无负载，更偏向可回收，字段 is_idle_machine=1，连续天数 idle_machine_consecutive_days。

在聚合表中：
- 低利用：low_utilization_count / low_utilization_percent
- 空闲：idle_machine_count / idle_machine_percent

治理上通常优先关注空闲机器，其次关注低利用率机器。',
  'FAQ',
  '低利用率机器和空闲机器有什么区别？',
  1,
  'PENDING',
  'text',
  'token',
  NOW(),
  NOW(),
  0,
  0
),

(
  5,
  '生产资源统计是否需要排除测试机',
  '需要。生产资源治理统计建议排除测试机：
- 明细表条件：is_test = -1
- 若只分析BDP自有：再加 bdp_own = 1

除非用户明确说“包含测试机”，否则默认按生产口径统计。',
  'FAQ',
  '做生产资源统计时要不要排除测试机？',
  1,
  'PENDING',
  'text',
  'token',
  NOW(),
  NOW(),
  0,
  0
),

(
  5,
  'YARN空闲和通用空闲有什么区别',
  '通用空闲：is_idle_machine=1，表示机器整体空闲。
YARN空闲：is_yarn_idle=1，仅表示YARN维度空闲，连续天数看 yarn_idle_consecutive_days。

当用户明确提到“YARN空闲/NodeManager空闲”时，应使用 is_yarn_idle 相关字段，而不是仅用 is_idle_machine。',
  'FAQ',
  'YARN空闲和通用空闲机器有什么区别？',
  1,
  'PENDING',
  'text',
  'token',
  NOW(),
  NOW(),
  0,
  0
);

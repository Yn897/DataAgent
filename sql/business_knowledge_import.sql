-- 业务知识批量导入 SQL
-- 智能体ID: 5
-- 关联数据表: bdp_machine_stat_history, container_zone_agg_daily, machine_monitor_group_agg_daily, machine_component_agg_daily
-- 说明：业务知识用于定义指标公式、业务术语和选表口径；字段映射请用语义模型

-- 如需重新导入，可先删除旧数据：
-- DELETE FROM business_knowledge WHERE agent_id = 5 AND is_deleted = 0
--   AND business_term IN (
--     '低利用率机器','空闲机器','CPU分配率','内存分配率','CPU需要治理','内存需要治理',
--     '机器总数','低利用率机器占比','空闲机器占比','CPU日均利用率','CPU峰值利用率',
--     '内存日均利用率','磁盘日均利用率','网络吞吐','机器明细快照','Zone资源统计',
--     '监控组资源统计','组件资源统计','YARN空闲','HDFS空闲','低利用连续天数',
--     '空闲连续天数','JDOS集群Zone','思源监控组','组件类型','BDP自有机器',
--     '是否测试机','部署类型'
--   );

INSERT INTO `business_knowledge` (
  `business_term`,
  `description`,
  `synonyms`,
  `is_recall`,
  `agent_id`,
  `created_time`,
  `updated_time`,
  `embedding_status`,
  `is_deleted`
) VALUES

-- ========== 核心治理指标 ==========
(
  '低利用率机器',
  '低利用率机器指资源利用率长期偏低、可优先回收或混部的机器。在明细表 bdp_machine_stat_history 中用 is_low_utilization=1 标识；统计天数看 low_util_consecutive_days。在日聚合表 machine_monitor_group_agg_daily / machine_component_agg_daily 中，用 low_utilization_count 统计台数，用 low_utilization_percent 统计占比（单位%）。查询“有多少低利用机器/低利用占比”时优先用聚合表；查询具体哪台机器低利用时用明细表，条件：is_low_utilization = 1。',
  '低利用机器,低负载机器,低水位机器,资源空闲偏高机器,low utilization',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '空闲机器',
  '空闲机器指基本无业务负载、可回收或下线的机器。明细表 bdp_machine_stat_history 用 is_idle_machine=1 标识，连续空闲天数看 idle_machine_consecutive_days。聚合表 machine_monitor_group_agg_daily / machine_component_agg_daily 用 idle_machine_count、idle_machine_percent 统计。注意：空闲机器通常比“低利用率机器”更严格；问“空闲机器数/空闲率”用聚合表，问“哪些IP空闲”用明细表过滤 is_idle_machine = 1。',
  '闲置机器,空闲机,idle机器,无负载机器,可回收机器',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  'CPU分配率',
  'CPU分配率 = 已使用CPU核数 / 可分配CPU核数 × 100%。对应表 container_zone_agg_daily 的字段 cpu_alloc_rate（单位%），分子是 vcpus_used，分母是 allocatable_vcpus。用于判断 Zone 维度 CPU 是否过低或过高，常配合 cpu_status、cpu_need_governance、cpu_governance_reason 做治理分析。',
  'CPU利用率,CPU使用率,vCPU分配率,CPU占用率',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '内存分配率',
  '内存分配率 = 已使用内存 / 可分配内存 × 100%。对应表 container_zone_agg_daily 的字段 memory_alloc_rate（单位%），分子是 memory_mb_used，分母是 allocatable_memory_mb。用于 Zone 维度内存水位判断，常配合 memory_status、memory_need_governance、memory_governance_reason 使用。',
  '内存利用率,内存使用率,MEM分配率,内存占用率',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  'CPU需要治理',
  'CPU需要治理表示该 Zone 的 CPU 分配率连续偏低或偏高，达到治理阈值。对应 container_zone_agg_daily.cpu_need_governance=1。治理原因看 cpu_governance_reason（常见 LOW/HIGH）；连续低/高天数分别看 cpu_low_consecutive_days、cpu_high_consecutive_days。查询“哪些 Zone 需要 CPU 治理”时过滤 cpu_need_governance = 1。',
  'CPU治理,CPU待治理,CPU告警治理,CPU资源治理',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '内存需要治理',
  '内存需要治理表示该 Zone 的内存分配率连续偏低或偏高。对应 container_zone_agg_daily.memory_need_governance=1。原因看 memory_governance_reason（LOW/HIGH）；连续天数看 memory_low_consecutive_days、memory_high_consecutive_days。查询“需要内存治理的 Zone”时过滤 memory_need_governance = 1。',
  '内存治理,内存待治理,MEM治理,内存资源治理',
  1, 5, NOW(), NOW(), 'PENDING', 0
),

-- ========== 常用统计指标 ==========
(
  '机器总数',
  '机器总数是纳入统计口径的物理机/宿主机数量。监控组维度用 machine_monitor_group_agg_daily.total_machine_count；组件维度用 machine_component_agg_daily.total_machine_count；Zone 维度宿主机数用 container_zone_agg_daily.host_count。不要混用三张聚合表的口径。',
  '总机器数,主机总数,机器台数,host数',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '低利用率机器占比',
  '低利用率机器占比 = 低利用率机器数 / 机器总数 × 100%。对应聚合表字段 low_utilization_percent（单位%）。监控组维度查 machine_monitor_group_agg_daily，组件维度查 machine_component_agg_daily。',
  '低利用占比,低负载占比,低水位占比',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '空闲机器占比',
  '空闲机器占比 = 空闲机器数 / 机器总数 × 100%。对应聚合表字段 idle_machine_percent（单位%）。监控组维度查 machine_monitor_group_agg_daily，组件维度查 machine_component_agg_daily。',
  '空闲占比,闲置占比,idle占比',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  'CPU日均利用率',
  'CPU日均利用率是当天 CPU 使用率的平均值，单位%。明细表 bdp_machine_stat_history 可用 avg_cpu 或 avg_cpu_usage_percent_day；监控组/组件聚合表用 avg_cpu_usage。问单机明细用明细表，问分组均值用聚合表。',
  '平均CPU利用率,日均CPU,CPU均值,avg CPU',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  'CPU峰值利用率',
  'CPU峰值利用率是当天 CPU 使用率的峰值，单位%。明细表用 peak_cpu；聚合表用 peak_cpu_usage。分析瓶颈、容量风险时优先看峰值，而不是日均值。',
  '峰值CPU,CPU峰值,peak CPU,CPU最高利用率',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '内存日均利用率',
  '内存日均利用率是当天内存使用率平均值，单位%。明细表用 avg_mem；聚合表用 avg_mem_usage。',
  '平均内存利用率,日均内存,内存均值,avg MEM',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '磁盘日均利用率',
  '磁盘日均利用率是当天磁盘使用率平均值，单位%。明细表用 avg_disk；聚合表用 avg_disk_usage。',
  '平均磁盘利用率,日均磁盘,磁盘均值,avg disk',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '网络吞吐',
  '网络吞吐表示机器网络流量大小。明细表区分入网/出网：avg_net_rx、avg_net_tx 等，单位 MB/s。聚合表用 avg_net_rx_tx_mbps、peak_net_rx_tx_mbps 等表示收发合计吞吐，单位 Mbps。注意明细与聚合的单位不同，不要直接横向对比数值。',
  '网络流量,带宽占用,网络速率,收发吞吐',
  1, 5, NOW(), NOW(), 'PENDING', 0
),

-- ========== 选表口径（非常重要） ==========
(
  '机器明细快照',
  '机器明细快照对应表 bdp_machine_stat_history，按天记录单机维度指标与属性（IP、SN、机房、产品、部署类型、是否低利用/空闲、各组件实例数、CPU/内存/磁盘/网络等）。适用于：查某台机器、按IP/SN/机房/产品筛选、看组件是否部署、看连续空闲/低利用天数。不适合直接做大盘占比汇总（应优先用聚合表）。时间字段用 date_day。',
  '机器明细表,单机快照,bdp_machine_stat_history,机器历史表',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  'Zone资源统计',
  'Zone资源统计对应表 container_zone_agg_daily，按天聚合 JDOS 集群 Zone 的宿主机数、CPU/内存总量、可分配量、已用量、分配率及治理状态。适用于：Zone 水位、CPU/内存是否需要治理、连续高低负载天数。维度字段主要是 date_day、jdos_cluster_name、jdos_cluster_zone、jdos_zone_product_own。不要用这张表查单机 IP。',
  'Zone日聚合,容器Zone统计,container_zone_agg_daily,Zone水位',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '监控组资源统计',
  '监控组资源统计对应表 machine_monitor_group_agg_daily，按天 + 思源监控组 + 产品聚合机器总数、低利用/空闲数量与占比，以及 CPU/内存/磁盘/网络利用率。适用于：按监控组看大盘利用率、空闲率和低利用率。维度字段：date_day、siyuan_monitor_group、product_name。',
  '监控组日聚合,思源监控组统计,machine_monitor_group_agg_daily,监控组水位',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '组件资源统计',
  '组件资源统计对应表 machine_component_agg_daily，按天 + 组件类型 + 产品聚合机器数、低利用/空闲占比及资源利用率。组件类型 component 常见值：yarn、hbase、clickhouse、doris 等。适用于：按中间件/组件对比资源利用率与空闲情况。不要用它查 Zone 治理状态。',
  '组件日聚合,中间件资源统计,machine_component_agg_daily,组件水位',
  1, 5, NOW(), NOW(), 'PENDING', 0
),

-- ========== 组件 / 平台专有术语 ==========
(
  'YARN空闲',
  'YARN空闲表示机器在 YARN 维度判定为空闲。明细表字段：is_yarn_idle=1，连续空闲天数 yarn_idle_consecutive_days；低利用对应 is_yarn_low_util、yarn_low_util_consecutive_days。分析“YARN空闲机器”应过滤 is_yarn_idle = 1，而不是只用通用 is_idle_machine。',
  'Yarn空闲,YARN闲置,NM空闲',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  'HDFS空闲',
  'HDFS空闲表示机器在 HDFS 维度判定为空闲。明细表字段：is_hdfs_idle=1，连续空闲天数 hdfs_idle_consecutive_days；低利用对应 is_hdfs_low_util、hdfs_low_util_consecutive_days。分析 HDFS 存储节点空闲时用这组字段。',
  'HDFS闲置,HDFS低负载,NameNode相关空闲请勿混淆',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '低利用连续天数',
  '低利用连续天数表示机器持续处于低利用率状态的天数。通用口径用 bdp_machine_stat_history.low_util_consecutive_days；YARN/HDFS 分别用 yarn_low_util_consecutive_days、hdfs_low_util_consecutive_days。Zone 维度 CPU/内存低负载连续天数分别用 cpu_low_consecutive_days、memory_low_consecutive_days。',
  '连续低利用天数,低负载持续天数,低水位连续天',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '空闲连续天数',
  '空闲连续天数表示机器持续空闲的天数。通用口径用 idle_machine_consecutive_days；YARN/HDFS 分别用 yarn_idle_consecutive_days、hdfs_idle_consecutive_days。常用于筛选“连续空闲超过N天可回收”的机器。',
  '连续空闲天数,闲置持续天数,idle连续天',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  'JDOS集群Zone',
  'JDOS集群Zone是容器集群的可用区/分区标识。字段 jdos_cluster_zone，常与 jdos_cluster_name、jdos_zone_product_own 一起使用。Zone 资源水位、CPU/内存治理分析应查 container_zone_agg_daily；单机上的 Zone 归属可在 bdp_machine_stat_history 中查看。',
  'Zone,集群Zone,JDOS Zone,可用区',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '思源监控组',
  '思源监控组是思源平台定义的机器分组名称，字段 siyuan_monitor_group。按监控组看利用率/空闲率用 machine_monitor_group_agg_daily；查某监控组下有哪些机器用 bdp_machine_stat_history 过滤 siyuan_monitor_group。',
  '监控组,siyuan监控组,monitor group',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '组件类型',
  '组件类型表示机器部署的大数据/中间件组件，字段 component（聚合表）或明细表中的 contain_xxx / xxx_instance_count。常见值包括 yarn、hbase、clickhouse、doris、flink、kafka 等。按组件对比资源用 machine_component_agg_daily；判断单机是否部署某组件用明细表 contain_xxx=1 或对应 instance_count>0。',
  '中间件类型,组件,component,服务组件',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  'BDP自有机器',
  'BDP自有机器表示机器归属 BDP。明细表字段 bdp_own：1=BDP自有，2=非自有。统计 BDP 自有机器资源或空闲情况时加条件 bdp_own = 1。',
  'BDP归属,自有机器,BDP机器',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '是否测试机',
  '是否测试机用于区分测试与生产机器。明细表字段 is_test：1=测试机，-1=非测试机。生产资源统计通常应排除测试机：is_test = -1 或 is_test <> 1。',
  '测试机器,测试环境机器,is_test',
  1, 5, NOW(), NOW(), 'PENDING', 0
),
(
  '部署类型',
  '部署类型描述机器部署方式。明细表字段 deploy_type：1=物理机，2=虚拟机，3=容器JDOS，4=混合JDOS，5=其他。分析容器化占比或物理机规模时用该字段分组统计。',
  '部署方式,deploy_type,交付形态',
  1, 5, NOW(), NOW(), 'PENDING', 0
);

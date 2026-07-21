/*
 * Copyright 2026 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

<template>
	<section class="page-shell">
		<header class="d-flex align-center justify-space-between mb-6">
			<div>
				<h1 class="text-h4 font-weight-bold mb-1" style="color: #1565c0">
					知识与配置批量导入
				</h1>
				<p class="text-body-2 text-medium-emphasis">
					支持「资源治理示例一键导入（可预览）」与「下载模板后自行上传」两种方式。
				</p>
			</div>
		</header>

		<v-card variant="flat" border class="rounded-lg mb-4 pa-4">
			<v-select
				v-model="selectedAgentId"
				:items="agentOptions"
				item-title="label"
				item-value="id"
				label="目标智能体（必选）"
				variant="outlined"
				density="compact"
				hide-details
				style="max-width: 420px"
			/>
		</v-card>

		<v-card variant="flat" border class="rounded-lg">
			<v-tabs v-model="activeTab" color="primary" class="px-2">
				<v-tab value="semantic">语义模型</v-tab>
				<v-tab value="business">业务知识</v-tab>
				<v-tab value="agent">智能体知识库</v-tab>
				<v-tab value="prompt">提示词配置</v-tab>
			</v-tabs>

			<v-divider />

			<v-tabs-window v-model="activeTab">
				<!-- 语义模型 -->
				<v-tabs-window-item value="semantic">
					<div class="pa-6">
						<v-alert type="info" variant="tonal" class="mb-4" density="compact">
							示例包来自资源治理四张核心表字段映射，写入当前选中智能体。
						</v-alert>
						<div class="d-flex flex-wrap ga-3 mb-6">
							<v-btn
								color="primary"
								prepend-icon="mdi-lightning-bolt"
								class="text-none"
								:loading="previewLoading"
								:disabled="!canImport"
								@click="openSamplePreview('semantic')"
							>
								一键导入资源治理示例
							</v-btn>
						</div>
						<v-divider class="mb-4" />
						<p class="text-body-2 text-medium-emphasis mb-4">
							或下载 Excel 模板，自行填写后上传。
						</p>
						<div class="d-flex flex-wrap ga-3 mb-4">
							<v-btn
								variant="outlined"
								prepend-icon="mdi-download"
								class="text-none"
								@click="downloadSemanticTemplate"
							>
								下载 Excel 模板
							</v-btn>
							<v-file-input
								v-model="semanticFile"
								accept=".xlsx,.xls"
								label="选择 Excel 文件"
								variant="outlined"
								density="compact"
								hide-details
								prepend-icon="mdi-file-excel"
								style="max-width: 360px"
								show-size
							/>
							<v-btn
								color="blue-darken-2"
								class="text-none"
								:loading="loading"
								:disabled="!canImport"
								@click="runSemanticImport"
							>
								上传并导入
							</v-btn>
						</div>
					</div>
				</v-tabs-window-item>

				<!-- 业务知识 -->
				<v-tabs-window-item value="business">
					<div class="pa-6">
						<v-alert type="info" variant="tonal" class="mb-4" density="compact">
							示例包含资源治理指标与口径术语；默认导入后同步向量库。
						</v-alert>
						<div class="d-flex flex-wrap ga-3 mb-6 align-center">
							<v-btn
								color="primary"
								prepend-icon="mdi-lightning-bolt"
								class="text-none"
								:loading="previewLoading"
								:disabled="!canImport"
								@click="openSamplePreview('business')"
							>
								一键导入资源治理示例
							</v-btn>
							<v-switch
								v-model="syncBusinessVector"
								label="导入后同步向量库"
								color="primary"
								hide-details
								density="compact"
							/>
						</div>
						<v-divider class="mb-4" />
						<p class="text-body-2 text-medium-emphasis mb-4">
							或下载 / 粘贴 JSON，自行上传导入。
						</p>
						<div class="d-flex flex-wrap ga-3 mb-4">
							<v-btn
								variant="outlined"
								prepend-icon="mdi-file-download-outline"
								class="text-none"
								@click="downloadJsonTemplate('business')"
							>
								下载 JSON 模板
							</v-btn>
							<v-file-input
								v-model="businessFile"
								accept=".json"
								label="选择 JSON 文件"
								variant="outlined"
								density="compact"
								hide-details
								style="max-width: 360px"
								show-size
								@update:model-value="onJsonFile('business', $event)"
							/>
							<v-btn
								color="blue-darken-2"
								class="text-none"
								:loading="loading"
								:disabled="!canImport"
								@click="runBusinessImport"
							>
								上传并导入
							</v-btn>
						</div>
						<v-textarea
							v-model="businessJson"
							label="JSON 内容"
							variant="outlined"
							rows="10"
							auto-grow
						/>
					</div>
				</v-tabs-window-item>

				<!-- 智能体知识 -->
				<v-tabs-window-item value="agent">
					<div class="pa-6">
						<v-alert type="info" variant="tonal" class="mb-4" density="compact">
							示例含 DOCUMENT / QA /
							FAQ；导入后会自动触发向量化（异步，稍后在知识库页查看状态）。
						</v-alert>
						<div class="d-flex flex-wrap ga-3 mb-6">
							<v-btn
								color="primary"
								prepend-icon="mdi-lightning-bolt"
								class="text-none"
								:loading="previewLoading"
								:disabled="!canImport"
								@click="openSamplePreview('agent')"
							>
								一键导入资源治理示例
							</v-btn>
						</div>
						<v-divider class="mb-4" />
						<p class="text-body-2 text-medium-emphasis mb-4">
							或下载 / 粘贴 JSON，自行上传导入。
						</p>
						<div class="d-flex flex-wrap ga-3 mb-4">
							<v-btn
								variant="outlined"
								prepend-icon="mdi-file-download-outline"
								class="text-none"
								@click="downloadJsonTemplate('agent')"
							>
								下载 JSON 模板
							</v-btn>
							<v-file-input
								v-model="agentFile"
								accept=".json"
								label="选择 JSON 文件"
								variant="outlined"
								density="compact"
								hide-details
								style="max-width: 360px"
								show-size
								@update:model-value="onJsonFile('agent', $event)"
							/>
							<v-btn
								color="blue-darken-2"
								class="text-none"
								:loading="loading"
								:disabled="!canImport"
								@click="runAgentImport"
							>
								上传并导入
							</v-btn>
						</div>
						<v-textarea
							v-model="agentJson"
							label="JSON 内容"
							variant="outlined"
							rows="10"
							auto-grow
						/>
					</div>
				</v-tabs-window-item>

				<!-- 提示词 -->
				<v-tabs-window-item value="prompt">
					<div class="pa-6">
						<v-alert type="info" variant="tonal" class="mb-4" density="compact">
							示例覆盖 sql-generator / planner / report-generator /
							general-chat；只写库，不进向量库。
						</v-alert>
						<div class="d-flex flex-wrap ga-3 mb-6">
							<v-btn
								color="primary"
								prepend-icon="mdi-lightning-bolt"
								class="text-none"
								:loading="previewLoading"
								:disabled="!canImport"
								@click="openSamplePreview('prompt')"
							>
								一键导入资源治理示例
							</v-btn>
						</div>
						<v-divider class="mb-4" />
						<p class="text-body-2 text-medium-emphasis mb-4">
							或下载 / 粘贴 JSON，自行上传导入。
						</p>
						<div class="d-flex flex-wrap ga-3 mb-4">
							<v-btn
								variant="outlined"
								prepend-icon="mdi-file-download-outline"
								class="text-none"
								@click="downloadJsonTemplate('prompt')"
							>
								下载 JSON 模板
							</v-btn>
							<v-file-input
								v-model="promptFile"
								accept=".json"
								label="选择 JSON 文件"
								variant="outlined"
								density="compact"
								hide-details
								style="max-width: 360px"
								show-size
								@update:model-value="onJsonFile('prompt', $event)"
							/>
							<v-btn
								color="blue-darken-2"
								class="text-none"
								:loading="loading"
								:disabled="!canImport"
								@click="runPromptImport"
							>
								上传并导入
							</v-btn>
						</div>
						<v-textarea
							v-model="promptJson"
							label="JSON 内容"
							variant="outlined"
							rows="10"
							auto-grow
						/>
					</div>
				</v-tabs-window-item>
			</v-tabs-window>
		</v-card>

		<v-card
			v-if="lastResult"
			variant="flat"
			border
			class="rounded-lg mt-4 pa-4"
		>
			<div class="text-subtitle-1 font-weight-medium mb-2">最近导入结果</div>
			<div class="text-body-2 mb-2">
				总数 {{ lastResult.total }}，成功
				{{ lastResult.successCount }}，失败 {{ lastResult.failCount }}
			</div>
			<ul
				v-if="lastResult.errors?.length"
				class="text-body-2 text-error pl-4"
			>
				<li v-for="(err, idx) in lastResult.errors.slice(0, 20)" :key="idx">
					{{ err }}
				</li>
			</ul>
			<div
				v-if="(lastResult.errors?.length || 0) > 20"
				class="text-caption text-medium-emphasis mt-1"
			>
				仅显示前 20 条错误…
			</div>
		</v-card>

		<!-- 示例预览弹窗 -->
		<v-dialog v-model="previewDialog" max-width="720">
			<v-card>
				<v-card-title class="d-flex align-center justify-space-between">
					<span>确认导入示例到智能体 #{{ selectedAgentId }}</span>
					<v-btn icon="mdi-close" variant="text" @click="previewDialog = false" />
				</v-card-title>
				<v-card-text>
					<div class="text-body-2 mb-3">
						<strong>{{ previewPack?.name }}</strong>
						· 共 {{ previewPack?.count || 0 }} 条，将写入当前选中智能体。
					</div>
					<v-list
						density="compact"
						class="border rounded"
						style="max-height: 360px; overflow: auto"
					>
						<v-list-item
							v-for="(title, idx) in previewPack?.titles || []"
							:key="idx"
						>
							<template #prepend>
								<span class="text-caption text-medium-emphasis mr-2"
									>{{ idx + 1 }}.</span
								>
							</template>
							<v-list-item-title class="text-body-2">{{
								title
							}}</v-list-item-title>
						</v-list-item>
					</v-list>
				</v-card-text>
				<v-card-actions class="px-4 pb-4">
					<v-spacer />
					<v-btn
						variant="text"
						class="text-none"
						@click="previewDialog = false"
					>
						取消
					</v-btn>
					<v-btn
						color="primary"
						class="text-none"
						:loading="loading"
						@click="confirmSampleImport"
					>
						确认导入
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</section>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import agentService from '~/services/agent/index';
import configImportService, {
	type BatchImportResult,
	type SampleKind,
	type SamplePackMeta,
} from '~/services/configImport/index';
import type { SemanticModelImportItem } from '~/services/semanticModel/index';

const { $tip } = useNuxtApp();

const activeTab = ref('semantic');
const selectedAgentId = ref<number | null>(null);
const agentOptions = ref<{ id: number; label: string }[]>([]);
const loading = ref(false);
const previewLoading = ref(false);
const lastResult = ref<BatchImportResult | null>(null);

const previewDialog = ref(false);
const previewPack = ref<SamplePackMeta | null>(null);

const semanticFile = ref<File[] | File | null>(null);
const businessFile = ref<File[] | File | null>(null);
const agentFile = ref<File[] | File | null>(null);
const promptFile = ref<File[] | File | null>(null);

const syncBusinessVector = ref(true);
const businessJson = ref('');
const agentJson = ref('');
const promptJson = ref('');

const canImport = computed(() => !!selectedAgentId.value && !loading.value);

const TEMPLATES = {
	business: {
		items: [
			{
				businessTerm: '低利用率机器',
				description: 'CPU日均利用率低于阈值且满足连续天数条件的机器',
				synonyms: '低负载机器,低效机器',
				isRecall: true,
			},
		],
	},
	agent: {
		items: [
			{
				title: '四张核心表说明',
				type: 'DOCUMENT',
				content: '资源治理平台有四张核心日表……',
				isRecall: true,
				splitterType: 'token',
			},
			{
				title: '查询低利用率机器占比',
				type: 'QA',
				question: '某个监控组低利用率机器占比是多少',
				content:
					'使用 machine_monitor_group_agg_daily，按 date_day 与监控组过滤……',
				isRecall: true,
			},
		],
	},
	prompt: {
		items: [
			{
				name: 'SQL生成增强',
				promptType: 'sql-generator',
				optimizationPrompt: '生成 SQL 时优先参考业务知识中的指标口径……',
				enabled: true,
				priority: 10,
				displayOrder: 1,
				description: '示例提示词',
			},
		],
	},
};

function pickFile(model: File[] | File | null): File | null {
	if (!model) return null;
	return Array.isArray(model) ? (model[0] ?? null) : model;
}

function parseItemsJson(raw: string): unknown[] {
	const parsed = JSON.parse(raw);
	if (Array.isArray(parsed)) return parsed;
	if (parsed && Array.isArray(parsed.items)) return parsed.items;
	throw new Error('JSON 需为数组，或包含 items 数组的对象');
}

async function loadAgents() {
	const list = await agentService.list();
	agentOptions.value = (list || [])
		.filter((a) => a.id != null)
		.map((a) => ({
			id: a.id as number,
			label: `${a.name || '未命名'} (#${a.id})`,
		}));
	if (!selectedAgentId.value && agentOptions.value.length) {
		selectedAgentId.value = agentOptions.value[0].id;
	}
}

async function downloadSemanticTemplate() {
	try {
		await configImportService.downloadSemanticTemplate();
		$tip('模板下载成功');
	} catch {
		$tip('模板下载失败', { color: 'error' });
	}
}

function downloadJsonTemplate(kind: 'business' | 'agent' | 'prompt') {
	const blob = new Blob([JSON.stringify(TEMPLATES[kind], null, 2)], {
		type: 'application/json',
	});
	const url = URL.createObjectURL(blob);
	const a = document.createElement('a');
	a.href = url;
	a.download = `${kind}-import-template.json`;
	a.click();
	URL.revokeObjectURL(url);
}

async function onJsonFile(
	kind: 'business' | 'agent' | 'prompt',
	model: File[] | File | null,
) {
	const file = pickFile(model);
	if (!file) return;
	const text = await file.text();
	if (kind === 'business') businessJson.value = text;
	if (kind === 'agent') agentJson.value = text;
	if (kind === 'prompt') promptJson.value = text;
}

function showResult(result: BatchImportResult) {
	lastResult.value = result;
	$tip(`导入完成：成功 ${result.successCount}，失败 ${result.failCount}`);
}

async function openSamplePreview(kind: SampleKind) {
	if (!selectedAgentId.value) {
		$tip('请先选择智能体', { color: 'warning' });
		return;
	}
	previewLoading.value = true;
	try {
		previewPack.value = await configImportService.loadSamplePack(kind);
		previewDialog.value = true;
	} catch (e) {
		$tip(e instanceof Error ? e.message : '加载示例失败', { color: 'error' });
	} finally {
		previewLoading.value = false;
	}
}

async function confirmSampleImport() {
	if (!selectedAgentId.value || !previewPack.value) return;
	const { kind, items } = previewPack.value;
	loading.value = true;
	try {
		let result: BatchImportResult;
		if (kind === 'semantic') {
			result = await configImportService.importSemanticModels(
				selectedAgentId.value,
				items as SemanticModelImportItem[],
			);
		} else if (kind === 'business') {
			result = await configImportService.importBusinessKnowledge(
				selectedAgentId.value,
				items as never[],
				syncBusinessVector.value,
			);
		} else if (kind === 'agent') {
			result = await configImportService.importAgentKnowledge(
				selectedAgentId.value,
				items as never[],
			);
		} else {
			result = await configImportService.importPromptConfig(
				selectedAgentId.value,
				items as never[],
			);
		}
		previewDialog.value = false;
		showResult(result);
	} catch (e) {
		$tip(e instanceof Error ? e.message : '示例导入失败', { color: 'error' });
	} finally {
		loading.value = false;
	}
}

async function runSemanticImport() {
	if (!selectedAgentId.value) return;
	const file = pickFile(semanticFile.value);
	if (!file) {
		$tip('请先选择 Excel 文件', { color: 'warning' });
		return;
	}
	loading.value = true;
	try {
		const result = await configImportService.importSemanticExcel(
			file,
			selectedAgentId.value,
		);
		showResult(result);
	} catch (e) {
		$tip(e instanceof Error ? e.message : '语义模型导入失败', { color: 'error' });
	} finally {
		loading.value = false;
	}
}

async function runBusinessImport() {
	if (!selectedAgentId.value) return;
	loading.value = true;
	try {
		const items = parseItemsJson(businessJson.value) as never[];
		const result = await configImportService.importBusinessKnowledge(
			selectedAgentId.value,
			items,
			syncBusinessVector.value,
		);
		showResult(result);
	} catch (e) {
		$tip(e instanceof Error ? e.message : '业务知识导入失败', { color: 'error' });
	} finally {
		loading.value = false;
	}
}

async function runAgentImport() {
	if (!selectedAgentId.value) return;
	loading.value = true;
	try {
		const items = parseItemsJson(agentJson.value) as never[];
		const result = await configImportService.importAgentKnowledge(
			selectedAgentId.value,
			items,
		);
		showResult(result);
	} catch (e) {
		$tip(e instanceof Error ? e.message : '智能体知识导入失败', {
			color: 'error',
		});
	} finally {
		loading.value = false;
	}
}

async function runPromptImport() {
	if (!selectedAgentId.value) return;
	loading.value = true;
	try {
		const items = parseItemsJson(promptJson.value) as never[];
		const result = await configImportService.importPromptConfig(
			selectedAgentId.value,
			items,
		);
		showResult(result);
	} catch (e) {
		$tip(e instanceof Error ? e.message : '提示词导入失败', { color: 'error' });
	} finally {
		loading.value = false;
	}
}

onMounted(() => {
	businessJson.value = JSON.stringify(TEMPLATES.business, null, 2);
	agentJson.value = JSON.stringify(TEMPLATES.agent, null, 2);
	promptJson.value = JSON.stringify(TEMPLATES.prompt, null, 2);
	loadAgents();
});
</script>

<style scoped></style>

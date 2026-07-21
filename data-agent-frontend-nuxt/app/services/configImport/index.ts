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

/**
 * @description 知识与配置批量导入服务
 */

import axios from 'axios';
import type { ApiResponse } from '~/services/common/index';
import semanticModelService, {
  type SemanticModelImportItem,
} from '~/services/semanticModel/index';

export interface BatchImportResult {
  total: number;
  successCount: number;
  failCount: number;
  errors?: string[];
}

export interface BusinessKnowledgeImportItem {
  businessTerm: string;
  description: string;
  synonyms?: string;
  isRecall?: boolean;
}

export interface AgentKnowledgeImportItem {
  title: string;
  type: 'DOCUMENT' | 'QA' | 'FAQ' | string;
  question?: string;
  content: string;
  isRecall?: boolean;
  splitterType?: string;
}

export interface PromptConfigImportItem {
  id?: string;
  name: string;
  promptType: string;
  optimizationPrompt: string;
  enabled?: boolean;
  description?: string;
  creator?: string;
  priority?: number;
  displayOrder?: number;
}

export type SampleKind = 'semantic' | 'business' | 'agent' | 'prompt';

export interface SamplePackMeta {
  kind: SampleKind;
  name: string;
  count: number;
  titles: string[];
  items: unknown[];
}

const SAMPLE_URLS: Record<SampleKind, string> = {
  semantic: '/samples/resource-governance/semantic-models.json',
  business: '/samples/resource-governance/business-knowledge.json',
  agent: '/samples/resource-governance/agent-knowledge.json',
  prompt: '/samples/resource-governance/prompt-config.json',
};

function emptyResult(): BatchImportResult {
  return { total: 0, successCount: 0, failCount: 0, errors: [] };
}

function titlesOf(kind: SampleKind, items: Record<string, unknown>[]): string[] {
  return items.map((item, idx) => {
    if (kind === 'semantic') {
      return `${item.tableName}.${item.columnName}（${item.businessName || '-'}）`;
    }
    if (kind === 'business') {
      return String(item.businessTerm || `未命名${idx + 1}`);
    }
    if (kind === 'agent') {
      return `${item.type || ''} · ${item.title || `未命名${idx + 1}`}`;
    }
    return `${item.promptType || ''} · ${item.name || `未命名${idx + 1}`}`;
  });
}

class ConfigImportService {
  async importSemanticExcel(file: File, agentId: number): Promise<BatchImportResult> {
    return semanticModelService.importExcel(file, agentId);
  }

  async importSemanticModels(
    agentId: number,
    items: SemanticModelImportItem[],
  ): Promise<BatchImportResult> {
    return semanticModelService.batchImport({ agentId, items });
  }

  async downloadSemanticTemplate(): Promise<void> {
    return semanticModelService.downloadTemplate();
  }

  async importBusinessKnowledge(
    agentId: number,
    items: BusinessKnowledgeImportItem[],
    syncVector = true,
  ): Promise<BatchImportResult> {
    const response = await axios.post<ApiResponse<BatchImportResult>>(
      '/api/business-knowledge/batch-import',
      { agentId, items, syncVector },
    );
    return response.data.data || emptyResult();
  }

  async importAgentKnowledge(
    agentId: number,
    items: AgentKnowledgeImportItem[],
  ): Promise<BatchImportResult> {
    const response = await axios.post<ApiResponse<BatchImportResult>>(
      '/api/agent-knowledge/batch-import',
      { agentId, items },
    );
    return response.data.data || emptyResult();
  }

  async importPromptConfig(
    agentId: number,
    items: PromptConfigImportItem[],
  ): Promise<BatchImportResult> {
    const response = await axios.post<{
      success: boolean;
      data?: BatchImportResult;
    }>('/api/prompt-config/batch-import', { agentId, items });
    return response.data.data || emptyResult();
  }

  async loadSamplePack(kind: SampleKind): Promise<SamplePackMeta> {
    const response = await fetch(SAMPLE_URLS[kind]);
    if (!response.ok) {
      throw new Error(`加载示例失败: ${response.status}`);
    }
    const data = await response.json();
    const items = Array.isArray(data) ? data : data.items || [];
    return {
      kind,
      name: data.name || '资源治理示例包',
      count: items.length,
      titles: titlesOf(kind, items),
      items,
    };
  }
}

export const configImportService = new ConfigImportService();
export default configImportService;

/*
 * Copyright 2024-2026 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.alibaba.cloud.ai.dataagent.dto.knowledge.agentknowledge;

import com.alibaba.cloud.ai.dataagent.annotation.InEnum;
import com.alibaba.cloud.ai.dataagent.enums.KnowledgeType;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AgentKnowledgeImportItem {

	@NotBlank(message = "标题不能为空")
	private String title;

	@NotBlank(message = "类型不能为空")
	@InEnum(value = KnowledgeType.class, method = "getCode", message = "type只能是DOCUMENT/QA/FAQ之一")
	private String type;

	/** QA/FAQ 必填；DOCUMENT 可空 */
	private String question;

	/** DOCUMENT 文本内容，或 QA/FAQ 答案 */
	@NotBlank(message = "内容不能为空")
	private String content;

	@Builder.Default
	private Boolean isRecall = true;

	@Builder.Default
	private String splitterType = "token";

}

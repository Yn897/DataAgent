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
package com.alibaba.cloud.ai.dataagent.dto.prompt;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PromptConfigImportItem {

	/** 传入则更新，不传则新建 */
	private String id;

	@NotBlank(message = "名称不能为空")
	private String name;

	@NotBlank(message = "提示词类型不能为空")
	private String promptType;

	@NotBlank(message = "提示词内容不能为空")
	private String optimizationPrompt;

	@Builder.Default
	private Boolean enabled = true;

	private String description;

	private String creator;

	@Builder.Default
	private Integer priority = 0;

	@Builder.Default
	private Integer displayOrder = 0;

}

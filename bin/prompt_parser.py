#!/usr/bin/env python3
"""
CommandAI Markdown Prompt Parser
解析 Markdown 格式的自定义提示词配置文件
"""

import re
import os
from typing import Dict, Optional


class MarkdownPromptParser:
    """Markdown 格式的 Prompt 配置解析器"""
    
    def __init__(self, config_path: str):
        self.config_path = config_path
        self.prompts = {}
        self._load_prompts()
    
    def _load_prompts(self):
        """从 Markdown 文件加载提示词配置"""
        if not os.path.exists(self.config_path):
            return
        
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 解析四种主要的提示词类型
            self.prompts = {
                'correction_system_prompt': self._extract_correction_prompt(content),
                'translation_system_prompt': self._extract_translation_prompt(content),
                'completion_system_prompt': self._extract_completion_prompt(content),
                'explanation_system_prompt': self._extract_explanation_prompt(content)
            }
            
        except Exception as e:
            print(f"警告: 无法解析 Markdown 配置文件 {self.config_path}: {e}")
    
    def _extract_correction_prompt(self, content: str) -> Optional[str]:
        """提取命令纠错提示词"""
        # 查找 "## 🔧 命令纠错提示词" 部分
        pattern = r'## 🔧 命令纠错提示词.*?\*\*当前配置\*\*:\s*```([^`]+?)```'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            return match.group(1).strip()
        
        # 备用模式：查找任何包含 "命令纠错" 的代码块
        pattern = r'命令纠错.*?```([^`]+?)```'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            return match.group(1).strip()
        
        return None
    
    def _extract_translation_prompt(self, content: str) -> Optional[str]:
        """提取自然语言转命令提示词"""
        # 查找 "## 🌐 自然语言转命令提示词" 部分
        pattern = r'## 🌐 自然语言转命令提示词.*?\*\*当前配置\*\*:\s*```([^`]+?)```'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            return match.group(1).strip()
        
        # 备用模式：查找任何包含 "自然语言" 的代码块
        pattern = r'自然语言.*?```([^`]+?)```'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            return match.group(1).strip()
        
        return None
    
    def _extract_completion_prompt(self, content: str) -> Optional[str]:
        """提取智能补全提示词"""
        # 查找 "## 🔍 智能补全提示词" 部分
        pattern = r'## 🔍 智能补全提示词.*?\*\*当前配置\*\*:\s*```([^`]+?)```'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            return match.group(1).strip()
        
        # 备用模式：查找任何包含 "智能补全" 的代码块
        pattern = r'智能补全.*?```([^`]+?)```'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            return match.group(1).strip()
        
        return None
    
    def _extract_explanation_prompt(self, content: str) -> Optional[str]:
        """提取命令解释提示词"""
        # 查找 "## 📖 命令解释提示词" 部分
        pattern = r'## 📖 命令解释提示词.*?\*\*当前配置\*\*:\s*```([^`]+?)```'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            return match.group(1).strip()
        
        # 备用模式：查找任何包含 "命令解释" 的代码块
        pattern = r'命令解释.*?```([^`]+?)```'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            return match.group(1).strip()
        
        return None
    
    def get_prompt(self, prompt_type: str, fallback: str = "") -> str:
        """获取指定类型的提示词，如果不存在则返回 fallback"""
        return self.prompts.get(prompt_type, fallback)
    
    def has_prompt(self, prompt_type: str) -> bool:
        """检查是否存在指定类型的提示词"""
        return prompt_type in self.prompts and self.prompts[prompt_type] is not None
    
    def list_available_prompts(self) -> Dict[str, bool]:
        """列出所有可用的提示词类型"""
        return {
            'correction_system_prompt': self.has_prompt('correction_system_prompt'),
            'translation_system_prompt': self.has_prompt('translation_system_prompt'),
            'completion_system_prompt': self.has_prompt('completion_system_prompt'),
            'explanation_system_prompt': self.has_prompt('explanation_system_prompt')
        }


def test_parser():
    """测试解析器功能"""
    import tempfile
    
    # 创建测试 Markdown 内容
    test_content = """
# CommandAI 自定义提示词配置

## 🔧 命令纠错提示词

**当前配置**:

```
你是一位经验丰富的系统管理员。请帮助修复失败的命令。
规则：
1. 分析错误信息
2. 提供准确的修正命令
3. 标记危险操作
```

## 🌐 自然语言转命令提示词

**当前配置**:

```
你是一个智能的命令行翻译助手。
请将自然语言转换为 shell 命令。
规则：
1. 支持中英文
2. 生成标准命令
3. 标记危险操作
```

## 🔍 智能补全提示词

**当前配置**:

```
你是一个高级命令行补全引擎。
请提供智能补全建议。
返回 JSON 格式。
```

## 📖 命令解释提示词

**当前配置**:

```
你是一个专业的命令行教学助手。请为用户详细解释命令的功能和用法。

请按以下格式回复：
1. 命令简介：简要说明命令的主要功能
2. 参数解释：解释各个参数的作用
3. 使用示例：提供常见的使用场景
4. 注意事项：提醒使用时需要注意的地方

请使用中文回复，内容要简洁明了，重点突出实用性。
```
"""
    
    # 创建临时文件
    with tempfile.NamedTemporaryFile(mode='w', suffix='.md', delete=False) as f:
        f.write(test_content)
        temp_path = f.name
    
    try:
        # 测试解析器
        parser = MarkdownPromptParser(temp_path)
        
        print("=== Markdown Prompt Parser 测试 ===")
        print(f"配置文件: {temp_path}")
        print()
        
        # 测试各种提示词
        prompts = parser.list_available_prompts()
        for prompt_type, available in prompts.items():
            print(f"{prompt_type}: {'✅' if available else '❌'}")
            if available:
                content = parser.get_prompt(prompt_type)
                print(f"  内容预览: {content[:50]}...")
            print()
        
        # 测试 fallback
        fallback_test = parser.get_prompt('nonexistent_prompt', 'fallback_value')
        print(f"Fallback 测试: {fallback_test}")
        
    finally:
        # 清理临时文件
        os.unlink(temp_path)


if __name__ == "__main__":
    test_parser()

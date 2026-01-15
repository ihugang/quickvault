#!/bin/bash

# Find Hardcoded Strings Script
# 查找项目中硬编码字符串的脚本
# 
# 使用方法 / Usage:
#   chmod +x find_hardcoded_strings.sh
#   ./find_hardcoded_strings.sh

set -e

# 颜色定义 / Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
SEARCH_DIRS=(
  "src/QuickVault-iOS-App/QuickVault-iOS"
  "src/QuickVaultKit/Sources/QuickVaultCore"
)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}查找硬编码字符串 / Finding Hardcoded Strings${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 1. 查找 UserDefaults 键
echo -e "${YELLOW}1. UserDefaults 键 / UserDefaults Keys:${NC}"
echo -e "${GREEN}-------------------${NC}"
for dir in "${SEARCH_DIRS[@]}"; do
  if [ -d "$PROJECT_ROOT/$dir" ]; then
    grep -rn --include="*.swift" \
      -e 'UserDefaults\.standard\.\(set\|string\|bool\|integer\|object\|removeObject\).*forKey:.*"' \
      "$PROJECT_ROOT/$dir" 2>/dev/null | \
      grep -v "AppConstants.UserDefaultsKeys" | \
      grep -v "LocalizationKeys" | \
      sed 's/^/  /' || true
  fi
done
echo ""

# 2. 查找本地化键
echo -e "${YELLOW}2. 本地化键 / Localization Keys:${NC}"
echo -e "${GREEN}-------------------${NC}"
for dir in "${SEARCH_DIRS[@]}"; do
  if [ -d "$PROJECT_ROOT/$dir" ]; then
    grep -rn --include="*.swift" \
      -e 'localizedString.*"[a-z_]\+\.[a-z_]\+' \
      -e 'NSLocalizedString.*"[a-z_]\+\.[a-z_]\+' \
      "$PROJECT_ROOT/$dir" 2>/dev/null | \
      grep -v "LocalizationKeys\." | \
      grep -v "localizationKey" | \
      sed 's/^/  /' || true
  fi
done
echo ""

# 3. 查找系统图标名称
echo -e "${YELLOW}3. SF Symbols 图标 / SF Symbols Icons:${NC}"
echo -e "${GREEN}-------------------${NC}"
for dir in "${SEARCH_DIRS[@]}"; do
  if [ -d "$PROJECT_ROOT/$dir" ]; then
    grep -rn --include="*.swift" \
      -e 'systemName:.*"[a-z.]\+\.fill"' \
      -e 'systemName:.*"[a-z.]\+\.circle"' \
      -e 'systemName:.*"[a-z]\+\.badge\.[a-z]\+"' \
      "$PROJECT_ROOT/$dir" 2>/dev/null | \
      grep -v "AppConstants.SystemIcon" | \
      sed 's/^/  /' || true
  fi
done
echo ""

# 4. 查找通知名称
echo -e "${YELLOW}4. 通知名称 / Notification Names:${NC}"
echo -e "${GREEN}-------------------${NC}"
for dir in "${SEARCH_DIRS[@]}"; do
  if [ -d "$PROJECT_ROOT/$dir" ]; then
    grep -rn --include="*.swift" \
      -e 'Notification\.Name.*"com\.' \
      "$PROJECT_ROOT/$dir" 2>/dev/null | \
      grep -v "AppConstants.Notification" | \
      sed 's/^/  /' || true
  fi
done
echo ""

# 5. 查找 Logger 子系统
echo -e "${YELLOW}5. Logger 子系统 / Logger Subsystems:${NC}"
echo -e "${GREEN}-------------------${NC}"
for dir in "${SEARCH_DIRS[@]}"; do
  if [ -d "$PROJECT_ROOT/$dir" ]; then
    grep -rn --include="*.swift" \
      -e 'Logger.*subsystem:.*"com\.' \
      "$PROJECT_ROOT/$dir" 2>/dev/null | \
      grep -v "AppConstants.Logger" | \
      sed 's/^/  /' || true
  fi
done
echo ""

# 6. 查找钥匙串键
echo -e "${YELLOW}6. 钥匙串键 / Keychain Keys:${NC}"
echo -e "${GREEN}-------------------${NC}"
for dir in "${SEARCH_DIRS[@]}"; do
  if [ -d "$PROJECT_ROOT/$dir" ]; then
    grep -rn --include="*.swift" \
      -e 'key:.*"com\.[a-z]\+\.[a-z]\+' \
      "$PROJECT_ROOT/$dir" 2>/dev/null | \
      grep -v "AppConstants.Keychain" | \
      sed 's/^/  /' || true
  fi
done
echo ""

# 7. 查找魔法数字
echo -e "${YELLOW}7. 魔法数字 (常见配置值) / Magic Numbers:${NC}"
echo -e "${GREEN}-------------------${NC}"
for dir in "${SEARCH_DIRS[@]}"; do
  if [ -d "$PROJECT_ROOT/$dir" ]; then
    # 查找常见的魔法数字模式
    grep -rn --include="*.swift" \
      -e 'timeout.*=.*[0-9]\{2,\}' \
      -e 'minPasswordLength.*=.*[0-9]' \
      -e 'maxAttempts.*=.*[0-9]' \
      -e 'iterations.*=.*[0-9]\{4,\}' \
      "$PROJECT_ROOT/$dir" 2>/dev/null | \
      grep -v "AppConstants\." | \
      grep -v "//.*Magic" | \
      sed 's/^/  /' || true
  fi
done
echo ""

# 统计信息
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}建议 / Recommendations:${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "1. 将找到的字符串迁移到 ${GREEN}AppConstants.swift${NC} 或 ${GREEN}LocalizationKeys.swift${NC}"
echo -e "2. 使用常量替换硬编码字符串"
echo -e "3. 参考 ${GREEN}CONSTANTS_GUIDE.md${NC} 了解最佳实践"
echo -e "4. 运行测试确保迁移后功能正常\n"

echo -e "${GREEN}完成 / Done!${NC}"

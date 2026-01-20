#!/usr/bin/env python3
"""
将 iOS Localizable.strings 转换为 Android strings.xml
"""
import re
import sys
from pathlib import Path

def convert_key(ios_key):
    """将 iOS 的点分隔键转换为 Android 的下划线分隔键"""
    return ios_key.replace('.', '_')

def escape_xml(text):
    """转义 XML 特殊字符"""
    text = text.replace('&', '&amp;')
    text = text.replace('<', '&lt;')
    text = text.replace('>', '&gt;')
    text = text.replace('"', '\\"')
    text = text.replace("'", "\\'")
    # 处理 iOS 的 %@ 格式化符号，转换为 Android 的 %s
    text = text.replace('%@', '%s')
    # 处理 %d 格式化符号
    text = re.sub(r'%(\d+\$)?d', r'%\1d', text)
    return text

def parse_ios_strings(file_path):
    """解析 iOS Localizable.strings 文件"""
    entries = []
    current_comment = ""

    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()

            # 跳过空行和 MARK 注释
            if not line or line.startswith('//') or line.startswith('/*'):
                if line.startswith('//') and not line.startswith('// MARK'):
                    current_comment = line[2:].strip()
                continue

            # 匹配键值对: "key" = "value";
            match = re.match(r'"([^"]+)"\s*=\s*"(.*)";', line)
            if match:
                key = match.group(1)
                value = match.group(2)
                android_key = convert_key(key)
                android_value = escape_xml(value)

                entries.append({
                    'key': android_key,
                    'value': android_value,
                    'comment': current_comment
                })
                current_comment = ""

    return entries

def generate_android_xml(entries, output_path):
    """生成 Android strings.xml 文件"""
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n')
        f.write('<resources>\n')

        last_category = ""
        for entry in entries:
            # 根据键的前缀分类
            category = entry['key'].split('_')[0]
            if category != last_category:
                if last_category:
                    f.write('\n')
                f.write(f'    <!-- {category.upper()} -->\n')
                last_category = category

            # 写入注释（如果有）
            if entry['comment']:
                f.write(f'    <!-- {entry["comment"]} -->\n')

            # 写入字符串资源
            f.write(f'    <string name="{entry["key"]}">{entry["value"]}</string>\n')

        f.write('</resources>\n')

def main():
    # iOS 本地化文件路径
    ios_en_path = Path('../src/QuickHold-iOS-App/QuickHold-iOS/Resources/en.lproj/Localizable.strings')
    ios_zh_path = Path('../src/QuickHold-iOS-App/QuickHold-iOS/Resources/zh-Hans.lproj/Localizable.strings')

    # Android 输出路径
    android_en_path = Path('app/src/main/res/values/strings.xml')
    android_zh_path = Path('app/src/main/res/values-zh/strings.xml')

    # 创建输出目录
    android_en_path.parent.mkdir(parents=True, exist_ok=True)
    android_zh_path.parent.mkdir(parents=True, exist_ok=True)

    # 转换英文
    print("Converting English strings...")
    if ios_en_path.exists():
        en_entries = parse_ios_strings(ios_en_path)
        generate_android_xml(en_entries, android_en_path)
        print(f"✓ Generated {android_en_path} ({len(en_entries)} strings)")
    else:
        print(f"✗ iOS English file not found: {ios_en_path}")

    # 转换简体中文
    print("Converting Simplified Chinese strings...")
    if ios_zh_path.exists():
        zh_entries = parse_ios_strings(ios_zh_path)
        generate_android_xml(zh_entries, android_zh_path)
        print(f"✓ Generated {android_zh_path} ({len(zh_entries)} strings)")
    else:
        print(f"✗ iOS Chinese file not found: {ios_zh_path}")

    print("\n✅ Conversion complete!")

if __name__ == '__main__':
    main()

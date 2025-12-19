#!/usr/bin/env python3
"""
Add traditional Chinese characters to HSK vocabulary JSON files.
Uses the character mapping from ChineseConverterHelper.
"""

import json
import os

# Simplified to Traditional mapping (from chinese_converter_helper.dart)
SIMPLIFIED_TO_TRADITIONAL = {
    '国': '國', '学': '學', '们': '們', '说': '說', '时': '時',
    '电': '電', '话': '話', '视': '視', '书': '書', '长': '長',
    '为': '為', '对': '對', '来': '來', '开': '開', '关': '關',
    '动': '動', '会': '會', '门': '門', '让': '讓', '过': '過',
    '这': '這', '那': '那', '从': '從', '进': '進', '远': '遠',
    '运': '運', '还': '還', '边': '邊', '现': '現', '发': '發',
    '听': '聽', '见': '見', '认': '認', '识': '識', '觉': '覺',
    '观': '觀', '买': '買', '卖': '賣', '读': '讀', '写': '寫',
    '汉': '漢', '语': '語', '词': '詞', '讲': '講', '谈': '談',
    '请': '請', '谢': '謝', '问': '問', '题': '題', '间': '間',
    '钟': '鐘', '头': '頭', '脸': '臉', '眼': '眼', '睛': '睛',
    '体': '體', '医': '醫', '院': '院', '药': '藥', '务': '務',
    '办': '辦', '级': '級', '经': '經', '东': '東', '西': '西',
    '南': '南', '北': '北', '京': '京', '站': '站', '车': '車',
    '机': '機', '场': '場', '路': '路', '铁': '鐵', '桥': '橋',
    '饭': '飯', '馆': '館', '店': '店', '宾': '賓', '欢': '歡',
    '迎': '迎', '准': '準', '备': '備', '练': '練', '习': '習',
    '号': '號', '码': '碼', '区': '區', '邮': '郵', '件': '件',
    '热': '熱', '冷': '冷', '雨': '雨', '雪': '雪', '风': '風',
    '阴': '陰', '阳': '陽', '云': '雲', '气': '氣', '温': '溫',
    '春': '春', '夏': '夏', '秋': '秋', '冬': '冬', '节': '節',
    '历': '歷', '旧': '舊', '新': '新', '年': '年', '岁': '歲',
    '朋': '朋', '友': '友', '爱': '愛', '结': '結', '婚': '婚',
    '妇': '婦', '女': '女', '男': '男', '孩': '孩', '子': '子',
    '教': '教', '师': '師', '课': '課', '班': '班', '校': '校',
    '业': '業', '作': '作', '劳': '勞', '累': '累', '休': '休',
    '息': '息', '睡': '睡', '起': '起', '床': '床', '觉': '覺',
    '脑': '腦', '恼': '惱', '烦': '煩', '难': '難', '乐': '樂',
    '痛': '痛', '苦': '苦', '病': '病', '疼': '疼', '累': '累',
    '饿': '餓', '渴': '渴', '饱': '飽', '吃': '吃', '喝': '喝',
    '菜': '菜', '鸡': '雞', '鱼': '魚', '肉': '肉', '蛋': '蛋',
    '汤': '湯', '茶': '茶', '咖': '咖', '啡': '啡', '啤': '啤',
    '酒': '酒', '糖': '糖', '盐': '鹽', '醋': '醋', '油': '油',
    '米': '米', '面': '麵', '包': '包', '饼': '餅', '干': '乾',
    '果': '果', '苹': '蘋', '葡': '葡', '萄': '萄', '橙': '橙',
    '瓜': '瓜', '椒': '椒', '豆': '豆', '腐': '腐', '奶': '奶',
    '牛': '牛', '羊': '羊', '猪': '豬', '马': '馬', '鸟': '鳥',
    '虫': '蟲', '猫': '貓', '狗': '狗', '熊': '熊', '猴': '猴',
    '象': '象', '龙': '龍', '凤': '鳳', '虎': '虎', '兔': '兔',
    '蛇': '蛇', '鼠': '鼠', '牛': '牛', '猪': '豬', '狗': '狗',
    '红': '紅', '黄': '黃', '蓝': '藍', '绿': '綠', '黑': '黑',
    '白': '白', '灰': '灰', '紫': '紫', '粉': '粉', '色': '色',
    '金': '金', '银': '銀', '铜': '銅', '铁': '鐵', '钱': '錢',
    '元': '元', '块': '塊', '毛': '毛', '角': '角', '分': '分',
    '万': '萬', '千': '千', '百': '百', '十': '十', '零': '零',
    '第': '第', '次': '次', '双': '雙', '对': '對', '单': '單',
    '独': '獨', '共': '共', '总': '總', '些': '些', '几': '幾',
    '每': '每', '样': '樣', '种': '種', '类': '類', '别': '別',
    '特': '特', '别': '別', '非': '非', '常': '常', '很': '很',
    '太': '太', '最': '最', '更': '更', '挺': '挺', '真': '真',
    '比': '比', '较': '較', '多': '多', '少': '少', '大': '大',
    '小': '小', '高': '高', '低': '低', '长': '長', '短': '短',
    '快': '快', '慢': '慢', '早': '早', '晚': '晚', '迟': '遲',
    '远': '遠', '近': '近', '里': '裡', '外': '外', '上': '上',
    '下': '下', '前': '前', '后': '後', '左': '左', '右': '右',
    '中': '中', '内': '內', '旁': '旁', '边': '邊', '就': '就',
    '都': '都', '也': '也', '又': '又', '再': '再', '才': '才',
    '刚': '剛', '已': '已', '经': '經', '正': '正', '在': '在',
    '着': '著', '了': '了', '过': '過', '呢': '呢', '吗': '嗎',
    '吧': '吧', '啊': '啊', '哦': '哦', '唉': '唉', '哎': '哎',
}

def convert_to_traditional(simplified_text):
    """Convert simplified Chinese text to traditional character by character."""
    traditional = ''
    for char in simplified_text:
        traditional += SIMPLIFIED_TO_TRADITIONAL.get(char, char)
    return traditional

def add_traditional_to_file(input_file, output_file=None):
    """Add traditional field to each word in the JSON file."""
    if output_file is None:
        output_file = input_file
    
    print(f"Processing {input_file}...")
    
    with open(input_file, 'r', encoding='utf-8') as f:
        words = json.load(f)
    
    updated_count = 0
    for word in words:
        if 'traditional' not in word or word['traditional'] == word['hanzi']:
            traditional = convert_to_traditional(word['hanzi'])
            word['traditional'] = traditional
            if traditional != word['hanzi']:
                updated_count += 1
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    
    print(f"✓ Processed {len(words)} words, {updated_count} converted to traditional")
    return len(words), updated_count

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    data_dir = os.path.dirname(script_dir)
    
    files = ['hsk1_words.json', 'hsk2_words.json', 'hsk3_words.json']
    
    total_words = 0
    total_converted = 0
    
    for filename in files:
        filepath = os.path.join(data_dir, filename)
        if os.path.exists(filepath):
            words, converted = add_traditional_to_file(filepath)
            total_words += words
            total_converted += converted
        else:
            print(f"⚠ File not found: {filepath}")
    
    print(f"\n✅ Total: {total_words} words, {total_converted} with traditional characters")

if __name__ == '__main__':
    main()

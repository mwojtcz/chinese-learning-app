# -*- coding: utf-8 -*-
"""
Parse official HSK 3.0 word list from GitHub repo
Extract HSK-2 and HSK-3 words with pinyin
"""

import json
import re

# Paste the word list text here (we'll read from a file)
def parse_hsk_wordlist(text):
    """Parse the official HSK wordlist text"""
    
    # Find the start of each level
    hsk1_start = text.find("一级词汇表")
    hsk2_start = text.find("二级词汇表")
    hsk3_start = text.find("三级词汇表")
    hsk4_start = text.find("四级词汇表")
    
    # Extract each section
    hsk2_text = text[hsk2_start:hsk3_start]
    hsk3_text = text[hsk3_start:hsk4_start]
    
    # Pattern: number + hanzi (with optional | for variant) (with optional parts in parentheses)
    # Examples: "1 啊", "4 爸爸｜爸", "6 白（形）"
    word_pattern = r'(\d+)\s+([\u4e00-\u9fff｜]+)(?:（[^）]+）)?'
    
    hsk2_words = []
    hsk3_words = []
    
    # Parse HSK-2
    for match in re.finditer(word_pattern, hsk2_text):
        num, hanzi = match.groups()
        # Remove variant markers
        hanzi = hanzi.split('｜')[0]
        hsk2_words.append({
            'num': int(num),
            'hanzi': hanzi
        })
    
    # Parse HSK-3
    for match in re.finditer(word_pattern, hsk3_text):
        num, hanzi = match.groups()
        hanzi = hanzi.split('｜')[0]
        hsk3_words.append({
            'num': int(num),
            'hanzi': hanzi
        })
    
    return hsk2_words, hsk3_words

def create_word_entries(words, level):
    """Convert parsed words to full JSON entries"""
    entries = []
    
    for i, word in enumerate(words, 1):
        entry = {
            "hanzi": word['hanzi'],
            "pinyin": "",  # TODO: Add pinyin
            "english": "",  # TODO: Add English
            "polish": "",   # TODO: Add Polish
            "level": level,
            "notes": f"HSK {level} word #{i}",
            "tags": [],
            "partOfSpeech": "",
            "frequency": i
        }
        entries.append(entry)
    
    return entries

# Read the wordlist with explicit UTF-8 encoding
try:
    with open('hsk30_wordlist.txt', 'r', encoding='utf-8') as f:
        text = f.read()
except:
    # Try with utf-8-sig to handle BOM
    with open('hsk30_wordlist.txt', 'r', encoding='utf-8-sig') as f:
        text = f.read()

hsk2_words, hsk3_words = parse_hsk_wordlist(text)

print(f"Found {len(hsk2_words)} HSK-2 words")
print(f"Found {len(hsk3_words)} HSK-3 words")

# Sample first 10 of each
print("\nFirst 10 HSK-2 words:")
for w in hsk2_words[:10]:
    print(f"  {w['num']}. {w['hanzi']}")

print("\nFirst 10 HSK-3 words:")
for w in hsk3_words[:10]:
    print(f"  {w['num']}. {w['hanzi']}")

# Create full entries
hsk2_entries = create_word_entries(hsk2_words, "HSK-2")
hsk3_entries = create_word_entries(hsk3_words, "HSK-3")

# Save to JSON
with open('hsk2_words_new.json', 'w', encoding='utf-8') as f:
    json.dump(hsk2_entries, f, ensure_ascii=False, indent=2)

with open('hsk3_words_new.json', 'w', encoding='utf-8') as f:
    json.dump(hsk3_entries, f, ensure_ascii=False, indent=2)

print(f"\n✅ Created hsk2_words_new.json with {len(hsk2_entries)} words")
print(f"✅ Created hsk3_words_new.json with {len(hsk3_entries)} words")

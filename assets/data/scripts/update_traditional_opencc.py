#!/usr/bin/env python3
"""
Complete traditional Chinese conversion for HSK 1-4 using OpenCC.
This provides accurate simplified→traditional conversion for all characters.
"""

import json
from opencc import OpenCC

# Initialize converter (simplified to traditional)
cc = OpenCC('s2t')

def update_traditional_in_file(input_file, output_file=None):
    """Update traditional field using OpenCC for accurate conversion."""
    if output_file is None:
        output_file = input_file
    
    print(f"Processing {input_file}...")
    
    with open(input_file, 'r', encoding='utf-8') as f:
        words = json.load(f)
    
    updated_count = 0
    for word in words:
        # Convert using OpenCC
        traditional = cc.convert(word['hanzi'])
        
        # Update if different or if field doesn't exist
        if 'traditional' not in word or word['traditional'] != traditional:
            word['traditional'] = traditional
            if traditional != word['hanzi']:
                updated_count += 1
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    
    # Statistics
    different = sum(1 for w in words if w['traditional'] != w['hanzi'])
    print(f"✓ Processed {len(words)} words")
    print(f"  - {different} words have traditional forms ({different*100//len(words)}%)")
    print(f"  - {updated_count} words updated")
    
    return len(words), different, updated_count

def main():
    files = [
        '../hsk1_words.json',
        '../hsk2_words.json',
        '../hsk3_words.json',
        '../hsk4_words.json',
    ]
    
    total_words = 0
    total_traditional = 0
    total_updated = 0
    
    for filename in files:
        try:
            words, trad, updated = update_traditional_in_file(filename)
            total_words += words
            total_traditional += trad
            total_updated += updated
            print()
        except FileNotFoundError:
            print(f"⚠ File not found: {filename}\n")
    
    print("=== SUMMARY ===")
    print(f"Total words: {total_words}")
    print(f"Words with traditional: {total_traditional} ({total_traditional*100//total_words}%)")
    print(f"Words updated: {total_updated}")

if __name__ == '__main__':
    main()

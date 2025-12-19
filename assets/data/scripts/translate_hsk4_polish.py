#!/usr/bin/env python3
"""
Translate HSK 4 vocabulary to Polish using DeepL API.
"""

import json
import deepl
import time

# DeepL API key
API_KEY = "eda9239d-3ea1-495c-bafb-4f57953f3a3b:fx"

def translate_hsk4_to_polish(input_file, output_file=None):
    """Translate English to Polish for HSK 4 vocabulary."""
    if output_file is None:
        output_file = input_file
    
    print(f"Loading {input_file}...")
    
    with open(input_file, 'r', encoding='utf-8') as f:
        words = json.load(f)
    
    # Initialize DeepL translator
    translator = deepl.Translator(API_KEY)
    
    # Count words that need translation
    needs_translation = [w for w in words if not w.get('polish') or w['polish'].strip() == '']
    print(f"Found {len(needs_translation)} words to translate")
    
    if len(needs_translation) == 0:
        print("✓ All words already have Polish translations!")
        return 0
    
    translated_count = 0
    errors = 0
    
    # Translate in batches to be nice to API
    batch_size = 50
    total_batches = (len(needs_translation) + batch_size - 1) // batch_size
    
    for i in range(0, len(needs_translation), batch_size):
        batch = needs_translation[i:i+batch_size]
        batch_num = i // batch_size + 1
        
        print(f"\nBatch {batch_num}/{total_batches} ({len(batch)} words)...")
        
        for word in batch:
            try:
                # Translate English to Polish
                result = translator.translate_text(
                    word['english'], 
                    source_lang="EN",
                    target_lang="PL"
                )
                
                word['polish'] = result.text
                translated_count += 1
                
                # Progress indicator
                if translated_count % 10 == 0:
                    print(f"  Translated: {translated_count}/{len(needs_translation)}")
                
                # Small delay to avoid rate limiting
                time.sleep(0.1)
                
            except Exception as e:
                print(f"  ✗ Error translating '{word['hanzi']}': {e}")
                word['polish'] = word['english']  # Fallback to English
                errors += 1
        
        # Longer pause between batches
        if batch_num < total_batches:
            print(f"  Pausing 2 seconds before next batch...")
            time.sleep(2)
    
    # Save updated data
    print(f"\nSaving to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    
    # Summary
    print("\n=== TRANSLATION SUMMARY ===")
    print(f"✓ Successfully translated: {translated_count}")
    if errors > 0:
        print(f"✗ Errors: {errors}")
    print(f"Total words in file: {len(words)}")
    
    # Check API usage
    try:
        usage = translator.get_usage()
        if usage.character.limit_exceeded:
            print("⚠ WARNING: Character limit exceeded!")
        else:
            print(f"\nAPI Usage: {usage.character.count:,} / {usage.character.limit:,} characters")
            remaining = usage.character.limit - usage.character.count
            print(f"Remaining this month: {remaining:,} characters")
    except:
        pass
    
    return translated_count

def main():
    input_file = '../hsk4_words.json'
    translate_hsk4_to_polish(input_file)

if __name__ == '__main__':
    main()

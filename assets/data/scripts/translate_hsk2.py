#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Translate HSK-2 words from English to Polish using deep-translator library
"""

import json
import time
from deep_translator import GoogleTranslator

def translate_word(english_text):
    """Translate English to Polish using Google Translate"""
    try:
        # Split by comma and translate first meaning
        first_meaning = english_text.split(',')[0].strip()
        
        # Translate
        translator = GoogleTranslator(source='en', target='pl')
        polish = translator.translate(first_meaning)
        
        return polish
    except Exception as e:
        print(f"Error translating '{english_text}': {e}")
        return ""

def main():
    # Load HSK-2 data
    with open('../hsk2_words.json', 'r', encoding='utf-8') as f:
        words = json.load(f)
    
    print(f"Loaded {len(words)} words from HSK-2")
    
    # Translate words that don't have Polish translation
    translated_count = 0
    for i, word in enumerate(words):
        if not word.get('polish') or word['polish'] == '':
            english = word.get('english', '')
            if english:
                print(f"[{i+1}/{len(words)}] Translating: {word['hanzi']} ({english[:50]}...)")
                polish = translate_word(english)
                word['polish'] = polish
                translated_count += 1
                
                # Sleep to avoid rate limiting
                time.sleep(0.5)
        else:
            print(f"[{i+1}/{len(words)}] Already translated: {word['hanzi']}")
    
    # Save updated data
    with open('../hsk2_words.json', 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    
    print(f"\nDone! Translated {translated_count} words.")
    print(f"Updated file: hsk2_words.json")

if __name__ == '__main__':
    main()

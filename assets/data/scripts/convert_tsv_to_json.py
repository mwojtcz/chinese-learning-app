# -*- coding: utf-8 -*-
"""
Convert TSV files from krmanik/HSK-3.0 repo to our JSON format
"""

import json
import csv

def convert_tsv_to_json(tsv_file, level, output_file):
    """Convert TSV to our JSON format"""
    words = []
    
    with open(tsv_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f, delimiter='\t')
        
        for i, row in enumerate(reader, 1):
            if len(row) < 4:
                continue
                
            traditional, simplified, pinyin, english = row[0], row[1], row[2], row[3]
            
            # Use simplified Chinese
            hanzi = simplified
            
            # Create word entry
            word = {
                "hanzi": hanzi,
                "pinyin": pinyin,
                "english": english,
                "polish": "",  # TODO: Add Polish translations
                "level": level,
                "notes": "",
                "tags": [],
                "partOfSpeech": "",
                "frequency": i
            }
            
            words.append(word)
    
    # Save to JSON
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    
    return len(words)

# Convert HSK-2
count2 = convert_tsv_to_json('hsk2_official.tsv', 'HSK-2', 'hsk2_words.json')
print(f"✅ Created hsk2_words.json with {count2} words")

# Convert HSK-3
count3 = convert_tsv_to_json('hsk3_official.tsv', 'HSK-3', 'hsk3_words.json')
print(f"✅ Created hsk3_words.json with {count3} words")

print(f"\n📊 Total: {count2 + count3} words")
print("\n⚠️  Polish translations still need to be added")

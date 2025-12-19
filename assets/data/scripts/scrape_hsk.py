#!/usr/bin/env python3
"""
Scrape HSK 3.0 vocabulary from mandarinbean.com
Downloads HSK 4-9 word lists with Chinese, pinyin, and English.
"""

import requests
from bs4 import BeautifulSoup
import json
import re
import time

# URLs for all HSK levels
HSK_URLS = {
    'HSK-4': 'https://mandarinbean.com/new-hsk-4-word-list/',
    'HSK-5': 'https://mandarinbean.com/new-hsk-5-word-list/',
    'HSK-6': 'https://mandarinbean.com/new-hsk-6-word-list/',
    'HSK-7-8-9': 'https://mandarinbean.com/new-hsk-7-8-9-word-list/',
}

def scrape_hsk_level(url, level_name):
    """Scrape vocabulary from a single HSK level page."""
    print(f"Scraping {level_name}...")
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    
    soup = BeautifulSoup(response.content, 'html.parser')
    
    # Find the table with vocabulary
    words = []
    tables = soup.find_all('table')
    
    for table in tables:
        rows = table.find_all('tr')
        
        for row in rows[1:]:  # Skip header row
            cols = row.find_all('td')
            
            if len(cols) >= 4:
                try:
                    # Extract data from columns
                    number = cols[0].get_text(strip=True)
                    hanzi = cols[1].get_text(strip=True)
                    pinyin = cols[2].get_text(strip=True)
                    english = cols[3].get_text(strip=True)
                    
                    if hanzi and pinyin and english:
                        word = {
                            'hanzi': hanzi,
                            'pinyin': pinyin,
                            'english': english,
                            'polish': '',  # To be filled later
                            'level': level_name,
                            'notes': '',
                            'tags': [],
                            'partOfSpeech': None,
                            'frequency': int(number) if number.isdigit() else None
                        }
                        words.append(word)
                except Exception as e:
                    print(f"Error parsing row: {e}")
                    continue
    
    print(f"✓ Found {len(words)} words for {level_name}")
    return words

def save_to_json(words, filename):
    """Save words to JSON file."""
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    print(f"✓ Saved to {filename}")

def main():
    all_words = {}
    
    for level, url in HSK_URLS.items():
        try:
            words = scrape_hsk_level(url, level)
            all_words[level] = words
            
            # Save individual level file
            filename = f"../hsk{level.replace('HSK-', '').replace('-8-9', '_789')}_words_scraped.json"
            save_to_json(words, filename)
            
            # Be nice to the server
            time.sleep(2)
            
        except Exception as e:
            print(f"✗ Error scraping {level}: {e}")
    
    # Print summary
    print("\n=== Summary ===")
    total = 0
    for level, words in all_words.items():
        count = len(words)
        total += count
        print(f"{level}: {count} words")
    print(f"Total: {total} words")
    
    return all_words

if __name__ == '__main__':
    main()

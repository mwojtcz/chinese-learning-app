import json
import re

# Mapowanie kategorii na podstawie angielskich słów kluczowych
CATEGORY_KEYWORDS = {
    "Numbers": ["number", "numerical", "digit", "count", "quantity"],
    "Time": ["time", "hour", "minute", "second", "day", "week", "month", "year", "morning", "afternoon", "evening", "night", "today", "yesterday", "tomorrow", "now", "later", "early", "late"],
    "Family": ["family", "parent", "father", "mother", "son", "daughter", "brother", "sister", "grandfather", "grandmother", "uncle", "aunt", "husband", "wife", "relative"],
    "Food": ["food", "eat", "drink", "meal", "breakfast", "lunch", "dinner", "rice", "noodle", "meat", "vegetable", "fruit", "tea", "coffee", "water", "cook"],
    "Colors": ["color", "red", "blue", "green", "yellow", "white", "black", "orange", "purple", "pink", "brown", "gray"],
    "Body": ["body", "head", "face", "eye", "ear", "nose", "mouth", "hand", "foot", "leg", "arm", "finger", "hair", "heart"],
    "Clothing": ["clothes", "clothing", "wear", "dress", "shirt", "pants", "shoe", "hat", "coat", "jacket"],
    "Transportation": ["transport", "car", "bus", "train", "plane", "bicycle", "boat", "ship", "station", "airport", "drive", "ride"],
    "Places": ["place", "home", "house", "school", "hospital", "restaurant", "hotel", "store", "shop", "bank", "post office", "park", "city", "country", "building"],
    "Weather": ["weather", "rain", "snow", "wind", "cloud", "sun", "hot", "cold", "warm", "cool"],
    "Animals": ["animal", "dog", "cat", "bird", "fish", "horse", "cow", "pig", "chicken"],
    "Nature": ["nature", "tree", "flower", "grass", "mountain", "river", "sea", "ocean", "sky", "earth", "water", "fire"],
    "Emotions": ["emotion", "feeling", "happy", "sad", "angry", "love", "hate", "like", "fear", "worry", "excited", "tired", "bored"],
    "Actions": ["action", "do", "make", "go", "come", "walk", "run", "sit", "stand", "sleep", "wake", "open", "close", "give", "take", "buy", "sell"],
    "Communication": ["say", "speak", "talk", "tell", "ask", "answer", "call", "write", "read", "listen", "hear", "see", "watch", "look"],
    "Learning": ["study", "learn", "teach", "student", "teacher", "class", "lesson", "book", "test", "exam", "homework"],
    "Work": ["work", "job", "office", "company", "business", "employee", "manager", "boss", "salary", "money"],
    "Health": ["health", "sick", "ill", "disease", "medicine", "doctor", "hospital", "pain", "hurt", "healthy"],
    "Sports": ["sport", "play", "game", "ball", "team", "win", "lose", "run", "jump", "swim"],
    "Technology": ["computer", "phone", "internet", "email", "website", "screen", "keyboard", "mouse"],
}

PART_OF_SPEECH_KEYWORDS = {
    "noun": ["CL:", "person", "thing", "place", "name", "object"],
    "verb": ["to ", "v."],
    "adjective": ["adj.", "-ful", "-ous", "-ive"],
    "adverb": ["adv.", "-ly"],
    "particle": ["particle"],
    "measure word": ["CL:", "classifier", "measure word"],
    "pronoun": ["I", "you", "he", "she", "it", "we", "they", "this", "that"],
}

def categorize_word(english, pinyin, hanzi):
    """Automatycznie kategoryzuj słowo na podstawie tłumaczenia"""
    tags = []
    part_of_speech = ""
    
    english_lower = english.lower()
    
    # Wykryj kategorie
    for category, keywords in CATEGORY_KEYWORDS.items():
        for keyword in keywords:
            if keyword in english_lower:
                if category not in tags:
                    tags.append(category)
    
    # Wykryj część mowy
    for pos, keywords in PART_OF_SPEECH_KEYWORDS.items():
        for keyword in keywords:
            if keyword.lower() in english_lower:
                part_of_speech = pos
                break
        if part_of_speech:
            break
    
    # Jeśli nie znaleziono tagów, spróbuj ogólnych kategorii
    if not tags:
        # Sprawdź czy to pytanie
        if any(word in english_lower for word in ["what", "where", "when", "who", "why", "how", "which"]):
            tags.append("Questions")
        # Sprawdź czy to liczebnik
        elif any(char.isdigit() for char in english) or any(word in english_lower for word in ["one", "two", "three", "first", "second"]):
            tags.append("Numbers")
        # Domyślna kategoria
        else:
            tags.append("General")
    
    return tags, part_of_speech

def process_file(input_file, output_file):
    """Przetwarza plik JSON i dodaje tagi oraz części mowy"""
    with open(input_file, 'r', encoding='utf-8') as f:
        words = json.load(f)
    
    updated_count = 0
    for word in words:
        # Pomiń jeśli już ma tagi
        if word.get('tags') and len(word['tags']) > 0:
            continue
        
        english = word.get('english', '')
        pinyin = word.get('pinyin', '')
        hanzi = word.get('hanzi', '')
        
        tags, pos = categorize_word(english, pinyin, hanzi)
        
        word['tags'] = tags
        if not word.get('partOfSpeech'):
            word['partOfSpeech'] = pos
        
        updated_count += 1
    
    # Zapisz z ładnym formatowaniem
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    
    print(f"Zaktualizowano {updated_count} słów w {output_file}")
    
    # Statystyki
    all_tags = set()
    all_pos = set()
    for word in words:
        all_tags.update(word.get('tags', []))
        if word.get('partOfSpeech'):
            all_pos.add(word['partOfSpeech'])
    
    print(f"Znalezione kategorie: {sorted(all_tags)}")
    print(f"Znalezione części mowy: {sorted(all_pos)}")

if __name__ == "__main__":
    print("Przetwarzanie HSK-2...")
    process_file('hsk2_words.json', 'hsk2_words.json')
    
    print("\nPrzetwarzanie HSK-3...")
    process_file('hsk3_words.json', 'hsk3_words.json')
    
    print("\nGotowe!")

import json

# Sprawdź liczby słów
with open('hsk1_words.json', 'r', encoding='utf-8') as f:
    hsk1 = json.load(f)
    
with open('hsk2_words.json', 'r', encoding='utf-8') as f:
    hsk2 = json.load(f)
    
with open('hsk3_words.json', 'r', encoding='utf-8') as f:
    hsk3 = json.load(f)

print("=== OBECNY STAN ===")
print(f"HSK-1: {len(hsk1)} słów")
print(f"HSK-2: {len(hsk2)} słów")
print(f"HSK-3: {len(hsk3)} słów")
print(f"RAZEM: {len(hsk1) + len(hsk2) + len(hsk3)} słów")
print()

print("=== WYMAGANIA HSK 3.0 ===")
print("HSK-1 (Band 1): 500 słów")
print("HSK-2 (Band 2): 772 słów")
print("HSK-3 (Band 3): 973 słów")
print("RAZEM: 2245 słów")
print()

print("=== BRAKI ===")
print(f"HSK-1: {500 - len(hsk1)} słów (do dodania)")
print(f"HSK-2: {772 - len(hsk2)} słów (do dodania)")
print(f"HSK-3: {973 - len(hsk3)} słów (do dodania)")
print(f"RAZEM: {2245 - (len(hsk1) + len(hsk2) + len(hsk3))} słów (do dodania)")

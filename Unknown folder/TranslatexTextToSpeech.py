from deep_translator import GoogleTranslator
from gtts import gTTS
import os

text = input("Enter text: ")
lang = input("Enter language code (e.g. tl, en, ja): ").strip()

# Translate
translated = GoogleTranslator(source='auto', target=lang).translate(text)
print(f"\nTranslated: {translated}")

# Convert to speech
tts = gTTS(text=translated, lang=lang) 
tts.save("output.mp3")
print("Audio saved as output.mp3")
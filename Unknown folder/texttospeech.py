from gtts import gTTS

#def text_to_speech(text, lang='en', filename='output.mp3'):
#    """
#    Convert text to speech and save it as an audio file.
#
#    :param text: The text to convert to speech.
#    :param lang: The language for the speech (default is English).
#    :param filename: The name of the output audio file (default is 'output.mp3').
#    """
text = "what sup duck!"

tts = gTTS(text=text, lang='en')
tts.save('output.mp3')
print(f"Audio saved successfully.")
from gtts import gTTS

#def text_to_speech(text, lang='en', filename='output.mp3'):
#    """
#    Convert text to speech and save it as an audio file.
#
#    :param text: The text to convert to speech.
#    :param lang: The language for the speech (default is English).
#    :param filename: The name of the output audio file (default is 'output.mp3').
#    """
text = "fuck you tonee!"

tts = gTTS(text=text, lang='tl')#tl(tagalog), en(english), es(spanish), fr(french), de(german), it(italian), ja(japanese), ko(korean), zh-cn(chinese), id(indonesian), hi(hindi), ar(arabic), ru(russian), pt(portuguese), vi(vietnamese), th(thai), tr(turkish), pl(polish), nl(dutch), sv(swedish), fi(finnish), no(norwegian), da(danish), cs(czech), el(greek), hu(hungarian), ro(romanian), sk(slovak), bg(bulgarian)
tts.save('output.mp3')#filename
print(f"Audio saved successfully.")
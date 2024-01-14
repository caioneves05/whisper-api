import logging
from faster_whisper import WhisperModel

import json

from flask import request
from app.auth import bp

logging.basicConfig()
logging.getLogger("faster_whisper").setLevel(logging.DEBUG)

model_size = "small"

decodeHour = {
  "13": "1",
  "14": "2",
  "15": "3",
  "16": "4",
  "17": "5",
  "18": "6",
  "19": "7",
  "20": "8",
  "21": "9",
  "22": "10",
  "23": "11",

  "1": "13",
  "2": "14",
  "3": "15",
  "4": "16",
  "5": "17",
  "6": "18",
  "7": "19",
  "8": "20",
  "9": "21",
  "10": "22",
  "11": "23",
}

decodeHourInFullAM = {
    "00": "Meia Noite",
    "12": "Meio Dia",
    "1": "Uma Hora",
    "2": "Duas Horas",
    "3": "Três Horas",
    "4": "Quatro Horas",
    "5": "Cinco Horas",
    "6": "Seis Horas",
    "7": "Sete Horas",
    "8": "Oito Horas",
    "9": "Nove Horas",
    "10": "Dez Horas",
    "11": "Onze Horas",
    "12": "Doze Horas",
    "13": "Treze Horas",
    "14": "Quatorze Horas",
    "15": "Quinze Horas",
    "16": "Dezesseis Horas",
    "17": "Dezessete Horas",
    "18": "Dezoito Horas",
    "19": "Dezenove Horas",
    "20": "Vinte Horas",
    "21": "Vinte e Uma Horas",
    "22": "Vinte e Duas Horas",
    "23": "Vinte e Três Horas",
}

decodeHourInFullPM = {
  "13": "Uma Hora",
  "14": "Duas Horas",
  "15": "Três Horas",
  "16": "Quatro Horas",
  "17": "Cinco Horas",
  "18": "Seis Horas",
  "19": "Sete Horas",
  "20": "Oito Horas",
  "21": "Nove Horas",
  "22": "Dez Horas",
  "23": "Onze Horas",
}

decodeMinuteInFull = {
  "1": "Um",
  "2": "Dois",
  "3": "Três",
  "4": "Quatro",
  "5": "Cinco",
  "6": "Seis",
  "7": "Sete",
  "8": "Oito",
  "9": "Nove",
  "10": "Dez",
  "11": "Onze",
  "12": "Doze",
  "13": "Treze",
  "14": "Quatorze",
  "15": "Quinze",
  "16": "Dezesseis",
  "17": "Dezessete",
  "18": "Dezoito",
  "19": "Dezenove",
  "20": "Vinte",
  "21": "Vinte e um",
  "22": "Vinte e dois",
  "23": "Vinte e três",
  "24": "Vinte e quatro",
  "25": "Vinte e cinco",
  "26": "Vinte e seis",
  "27": "Vinte e sete",
  "28": "Vinte e oito",
  "29": "Vinte e nove",
  "30": "Trinta",
  "31": "Trinta e um",
  "32": "Trinta e dois",
  "33": "Trinta e três",
  "34": "Trinta e quatro",
  "35": "Trinta e cinco",
  "36": "Trinta e seis",
  "37": "Trinta e sete",
  "38": "Trinta e oito",
  "39": "Trinta e nove",
  "40": "Quarenta",
  "41": "Quarenta e um",
  "42": "Quarenta e dois",
  "43": "Quarenta e três",
  "44": "Quarenta e quatro",
  "45": "Quarenta e cinco",
  "46": "Quarenta e seis",
  "47": "Quarenta e sete",
  "48": "Quarenta e oito",
  "49": "Quarenta e nove",
  "50": "Cinquenta",
  "51": "Cinquenta e um",
  "52": "Cinquenta e dois",
  "53": "Cinquenta e três",
  "54": "Cinquenta e quatro",
  "55": "Cinquenta e cinco",
  "56": "Cinquenta e seis",
  "57": "Cinquenta e sete",
  "58": "Cinquenta e oito",
  "59": "Cinquenta e nove",
  "60": "Sessenta",

}

def search_index_expected_peech(phrase, typeExpected, hourExpected, minuteExpected):
    words = phrase.split(' ')
    filtered_none_empty = list(filter(lambda x: x != '', words))
    typeIndex = None
    hourIndex = None
    minuteIndex = None

    

    for index, p in enumerate(filtered_none_empty):
        if p == typeExpected:
            typeIndex = index
        if hourExpected in p:
            hourIndex = index
        if minuteExpected in p:
            minuteIndex = index
    print("minute expected", minuteExpected)
    print(filtered_none_empty)
    print(typeIndex)
    print(hourIndex)
    print(minuteIndex)

    if (
        typeIndex is not None
        and hourIndex is not None
        and minuteIndex is not None
        and typeIndex < hourIndex
        and hourIndex < minuteIndex
    ):
        return True
    return False

@bp.route("/", methods=["POST"])
def face_match():
  if request.method == "POST":
    # Input parameters of route
    audio = request.files.get("audio")
    expectedSpeech = request.form.get("expected_speech")

    if ("audio" in request.files and "expected_speech" in request.form):
      
      # Library with responsible to transcription audio
      model = WhisperModel(model_size, device="cpu", compute_type="int8")
      segments, info = model.transcribe(audio, beam_size=1, patience=2, language='pt', vad_filter=True, vad_parameters=dict(min_silence_duration_ms=500),)
      print("Detected language '%s' with probability %f" % (info.language, info.language_probability))

      # Formated inputs
      typeRegisterClockExpectedSpeech = expectedSpeech.split(' ')[0]
      hourExpectedSpeechInt = int(expectedSpeech.split(' ')[1])
      minuteExpectedSpeechInt = int(expectedSpeech.split(' ')[2])
      
      # Transform to string
      hourExpectedSpeechString = decodeHour.get(str(hourExpectedSpeechInt))
      hourExpectedSpeechStringInFullAM = decodeHourInFullAM.get(str(hourExpectedSpeechInt))
      hourExpectedSpeechStringInFullPM = decodeHourInFullPM.get(str(hourExpectedSpeechInt))
      minuteExpectedSpeechString = decodeMinuteInFull.get(str(minuteExpectedSpeechInt))

      for segment in segments:
        
        print(segment.text.lower())
        print("[%.2fs -> %.2fs] %s" % (segment.start, segment.end, segment.text))

        phrase_expected = 'entrada uma hora e quarenta'
        
        #Verify TYPE input
        if typeRegisterClockExpectedSpeech.lower() in phrase_expected:
            
            #Verify HOUR and hour written in full
            if (
            (hourExpectedSpeechString is not None and hourExpectedSpeechString in phrase_expected) or
            (str(hourExpectedSpeechInt) is not None and str(hourExpectedSpeechInt) in phrase_expected) or
            (hourExpectedSpeechStringInFullAM is not None and hourExpectedSpeechStringInFullAM.lower() in phrase_expected) or
            (hourExpectedSpeechStringInFullPM is not None and hourExpectedSpeechStringInFullPM.lower() in phrase_expected)
            ):
            
          # Verificar MINUTE e hour written in full
              if str(minuteExpectedSpeechInt).lower() in phrase_expected or minuteExpectedSpeechString.lower() in phrase_expected:
              
                hour_found = None
                minute_found = None

                # Verificar e armazenar HOUR
                if hourExpectedSpeechString is not None and hourExpectedSpeechString in phrase_expected:
                    hour_found = hourExpectedSpeechString
                elif hourExpectedSpeechInt is not None and str(hourExpectedSpeechInt) in phrase_expected:
                    hour_found = str(hourExpectedSpeechInt)
                elif hourExpectedSpeechStringInFullAM is not None and hourExpectedSpeechStringInFullAM.lower() in phrase_expected:
                    hour_found = hourExpectedSpeechStringInFullAM
                elif hourExpectedSpeechStringInFullPM is not None and hourExpectedSpeechStringInFullPM.lower() in phrase_expected:
                    hour_found = hourExpectedSpeechStringInFullPM
                
                # Verificar e armazenar MINUTE
                if minuteExpectedSpeechInt is not None and str(minuteExpectedSpeechInt).lower() in phrase_expected:
                    minute_found = str(minuteExpectedSpeechInt)
                elif minuteExpectedSpeechString is not None and minuteExpectedSpeechString.lower() in phrase_expected:
                    minute_found = minuteExpectedSpeechString

                parametersIsValid = search_index_expected_peech(phrase_expected, typeRegisterClockExpectedSpeech.lower(), hour_found, minute_found)

                if parametersIsValid == True:
                  return json.dumps({"validated": True, "spoken_text_in_audio": segment.text})
                else:
                  return json.dumps({"validated": False, "spoken_text_in_audio": segment.text})
                          
              else:
                return json.dumps({"validated": False, "spoken_text_in_audio": segment.text})
            
            else:
              return json.dumps({"validated": False, "spoken_text_in_audio": segment.text})
        
        else:
          return json.dumps({"validated": False, "spoken_text_in_audio": segment.text})
      


      # return json.dumps({"language": segments.text})
    else:
      
      return json.dumps({'message': 'audio or expected_speech not found'}), 400, {'ContentType':'application/json'}
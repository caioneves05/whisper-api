import os
import json

from faster_whisper import WhisperModel
from flask import request
from app.auth import bp

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
  "00": "0",
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

decodeHourInFullSurname = {
   "12": "meio",
   "00": "meia"
}

decodeHourInFullAM = {
    "00": "Zero",
    "1": "Uma",
    "2": "Duas",
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
    "21": "Vinte e Uma",
    "22": "Vinte e Duas",
    "23": "Vinte e Três",
}

decodeHourInFullPM = {
  "13": "Uma",
  "14": "Duas",
  "15": "Três",
  "16": "Quatro",
  "17": "Cinco",
  "18": "Seis",
  "19": "Sete",
  "20": "Oito",
  "21": "Nove",
  "22": "Dez",
  "23": "Onze",
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

# def flatten(iter):
#   new_list = []
#   for sub_list in iter:
#     for item in sub_list:
#         new_list.append(item)
#   return new_list


def search_index_expected_speech(phrase, typeExpected, hourExpected, minuteExpected):
    words = phrase.split(' ')
    filtered_not_empty = list(filter(lambda x: x != '', words))


    typeIndex = None
    hourIndex = None
    minuteIndex = None

    for index, p in enumerate(filtered_not_empty):
        if typeExpected in p:
            typeIndex = index
        if hourExpected in p :
            if hourIndex == None:
               hourIndex = index
        if hourExpected and minuteExpected in p:
            minuteIndex = index
    
    if hourIndex < minuteIndex or hourIndex == minuteIndex:
      # if phrase same "ENTRADA 1340"
      value_with_expected = [item for item in filtered_not_empty if hourExpected in item][0]
      
      index_hour = value_with_expected.find(hourExpected)
      index_minute = value_with_expected.find(minuteExpected)
      
      print("caio")
      if index_hour < index_minute:
        return True
                   
    if (
        typeIndex is not None
        and hourIndex is not None
        and minuteIndex is not None
        and typeIndex < hourIndex
        and hourIndex < minuteIndex
    ):
              return True
    return False

model_folder = os.path.join(os.path.dirname(__file__), '..', '..', 'models', 'small')
model = WhisperModel(model_folder, device="cpu", compute_type="int8", cpu_threads=4, local_files_only=True)

@bp.route("/health", methods=["GET"])
def default_helth():
   return json.dumps({"message": "Hello World"})

@bp.route("/", methods=["POST"])
def face_match():


  try:
      if request.method == "POST":

        # Input parameters of route
        audio = request.files.get("audio")
        expectedSpeech = request.form.get("expected_speech")
        if ("audio" in request.files and "expected_speech" in request.form):

          # Library with responsible to transcription audio
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
          hourExpectedSpeechStringInFullSurname = decodeHourInFullSurname.get(expectedSpeech.split(' ')[1])
          minuteExpectedSpeechString = decodeMinuteInFull.get(str(minuteExpectedSpeechInt))
          for segment in segments:
            
            # print("[%.2fs -> %.2fs] %s" % (segment.start, segment.end, segment.text))
            phrase_expected = segment.text.lower()
            #Verify TYPE input
            if typeRegisterClockExpectedSpeech.lower() in phrase_expected.lower():
                
                #Verify HOUR and hour written in full
                if (
                (hourExpectedSpeechString is not None and hourExpectedSpeechString in phrase_expected) or
                (str(hourExpectedSpeechInt) is not None and str(hourExpectedSpeechInt) in phrase_expected) or
                (hourExpectedSpeechStringInFullAM is not None and hourExpectedSpeechStringInFullAM.lower() in phrase_expected) or
                (hourExpectedSpeechStringInFullPM is not None and hourExpectedSpeechStringInFullPM.lower() in phrase_expected) or
                (hourExpectedSpeechStringInFullSurname is not None and hourExpectedSpeechStringInFullSurname.lower() in phrase_expected)
                ):

              # Verify MINUTE e hour written in full
                  if str(minuteExpectedSpeechInt).lower() in phrase_expected or minuteExpectedSpeechString.lower() in phrase_expected:
                  
                    hour_found = None
                    minute_found = None

                    # Check and save the HOUR
                    if hourExpectedSpeechString is not None and hourExpectedSpeechString in phrase_expected:
                        hour_found = hourExpectedSpeechString.lower()
                    elif hourExpectedSpeechInt is not None and str(hourExpectedSpeechInt) in phrase_expected:
                        hour_found = str(hourExpectedSpeechInt).lower()
                    elif hourExpectedSpeechStringInFullAM is not None and hourExpectedSpeechStringInFullAM.lower() in phrase_expected:
                        hour_found = hourExpectedSpeechStringInFullAM.lower()
                    elif hourExpectedSpeechStringInFullPM is not None and hourExpectedSpeechStringInFullPM.lower() in phrase_expected:
                        hour_found = hourExpectedSpeechStringInFullPM.lower()
                    elif hourExpectedSpeechStringInFullSurname is not None and hourExpectedSpeechStringInFullSurname.lower() in phrase_expected:
                      hour_found = hourExpectedSpeechStringInFullSurname.lower()
                    
                    # Check and save the MINUTE
                    if minuteExpectedSpeechInt is not None and str(minuteExpectedSpeechInt).lower() in phrase_expected:
                        minute_found = str(minuteExpectedSpeechInt).lower()
                    elif minuteExpectedSpeechString is not None and minuteExpectedSpeechString.lower() in phrase_expected:
                        minute_found = minuteExpectedSpeechString.lower()

                    parametersIsValid = search_index_expected_speech(phrase_expected, typeRegisterClockExpectedSpeech.lower(), hour_found, minute_found)
                    if parametersIsValid == True:
                      return json.dumps({"validated": True, "spoken_text_in_audio": phrase_expected})
                    else:
                      return json.dumps({"validated": False, "spoken_text_in_audio": phrase_expected})
                              
                  else:
                    return json.dumps({"validated": False, "spoken_text_in_audio": phrase_expected})
                
                else:
                  return json.dumps({"validated": False, "spoken_text_in_audio": phrase_expected})
            
            else:
              return json.dumps({"validated": False, "spoken_text_in_audio": phrase_expected})
  except Exception as e:
      print(e)
      return json.dumps({'message': 'audio or expected_speech not found'}), 400, {'ContentType':'application/json'}
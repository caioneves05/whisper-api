from typing import BinaryIO, Union
from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel

from fastapi import FastAPI
from pydantic import BaseModel

import whisper
import subprocess
import base64
import numpy
import torch

import os
import numpy as np
import ffmpeg

import os

SAMPLE_RATE = 16000

app = FastAPI()

class Data(BaseModel):
  audio: str

@app.post("/")
def read_root(data: Data):

  print(whisper._file_)

  process = subprocess.Popen(
    ['ls'], 
    stdout=subprocess.PIPE,
    universal_newlines=True
  )

  model = whisper.load_model('/code/app/small.pt')

  # decoded = base64.b64decode(data.audio)

class Data(BaseModel):
  audio: str

@app.post("/")
def read_root(data: Data):

  print(whisper._file_)

  process = subprocess.Popen(
    ['ls'], 
    stdout=subprocess.PIPE,
    universal_newlines=True
  )

  model = whisper.load_model('/code/app/small.pt')

  decoded = base64.b64decode(data.audio)


  # tensor = torch.Tensor(numpy.frombuffer(decoded), dtype=numpy.int32)

  mel =  whisper.log_mel_spectrogram( decoded ).to(model.device)

  result = whisper.decode(model, mel, whisper.DecodingOptions())

  while True:
    output = process.stdout.readline()
    print(output.strip())
    # Do something else
    return_code = process.poll()
    if return_code is not None:
      print('RETURN CODE', return_code)
      # Process has finished, read rest of the output 
      for output in process.stdout.readlines():
        print(output.strip())
      break
    
    return {"Hello": result}
  decoded = data.audio

  # print('--------ANTES------')
  # print(type(decoded.decode('utf-8')))
  # print('--------DEPOIS-----')

  # tensor = torch.Tensor(numpy.frombuffer(decoded), dtype=numpy.int32)

  file: UploadFile = File(decoded)

  mel =  whisper.log_mel_spectrogram( 
     load_audio(file = file.file)
   ).to(model.device)

  # result = whisper.decode(model, mel, whisper.DecodingOptions(fp16 = False))

  while True:
    output = process.stdout.readline()
    print(output.strip())
    # Do something else
    return_code = process.poll()
    if return_code is not None:
      print('RETURN CODE', return_code)
      # Process has finished, read rest of the output 
      for output in process.stdout.readlines():
        print(output.strip())
      break
    
    return {"Hello": result}

@app.get("/items/{item_id}")
def read_item(item_id: int, q: Union[str, None] = None):
    return {"item_id": item_id, "q": q}

def load_audio(file: BinaryIO, encode=True, sr: int = SAMPLE_RATE):
    """
    Open an audio file object and read as mono waveform, resampling as necessary.
    Modified from https://github.com/openai/whisper/blob/main/whisper/audio.py to accept a file object
    Parameters
    ----------
    file: BinaryIO
        The audio file like object
    encode: Boolean
        If true, encode audio stream to WAV before sending to whisper
    sr: int
        The sample rate to resample the audio if necessary
    Returns
    -------
    A NumPy array containing the audio waveform, in float32 dtype.
    """

    if encode:
        try:
            # This launches a subprocess to decode audio while down-mixing and resampling as necessary.
            # Requires the ffmpeg CLI and ffmpeg-python package to be installed.
            out, _ = (
                ffmpeg.input("pipe:", threads=0)
                .output("-", format="s16le", acodec="pcm_s16le", ac=1, ar=sr)
                .run(cmd="ffmpeg", capture_stdout=True, capture_stderr=True, input=file.read())#trocar 'ffmpeg'
            )
        except ffmpeg.Error as e:
            raise RuntimeError(f"Failed to load audio: {e.stderr.decode()}") from e
    else:
        out = file.read()

    return np.frombuffer(out, np.int16).flatten().astype(np.float32) / 32768.0
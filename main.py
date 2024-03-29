import logging
from faster_whisper import WhisperModel

logging.basicConfig()
logging.getLogger("faster_whisper").setLevel(logging.DEBUG)

model_size = "large-v3"

# Run on GPU with FP16
model = WhisperModel(model_size, device="cpu", compute_type="int8")

# or run on GPU with INT8
# model = WhisperModel(model_size, device="cuda", compute_type="int8_float16")
# or run on CPU with INT8
# model = WhisperModel(model_size, device="cpu", compute_type="int8")

segments, info = model.transcribe("audio.mp3", beam_size=5, patience=2, language='pt', vad_filter=True)


print("Detected language '%s' with probability %f" % (info.language, info.language_probability))
print(segments)

for segment in segments:
    print(segment)
    print("[%.2fs -> %.2fs] %s" % (segment.start, segment.end, segment.text))
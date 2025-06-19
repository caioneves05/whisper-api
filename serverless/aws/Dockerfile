FROM public.ecr.aws/lambda/python:3.9

COPY requirements.txt ${LAMBDA_TASK_ROOT}

COPY tmp ${LAMBDA_TASK_ROOT}

RUN yum install -y pkgconfig

# Install the specified packages
RUN pip install -r requirements.txt

RUN python3 -c 'import faster_whisper; faster_whisper.download_model("small", "tmp/small")'

COPY app.py ${LAMBDA_TASK_ROOT}

COPY audio.mp4 ${LAMBDA_TASK_ROOT}

CMD ["app.handler"]

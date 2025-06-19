# DEVELOPMENT

FROM python:3.9 As development

WORKDIR /app

RUN apt-get update && apt-get install -y python3

RUN apt-get install -y python3-pip

RUN apt-get install -y build-essential

COPY requirements.txt /

RUN pip3 install --trusted-host pypi.python.org -r /requirements.txt


COPY . .

# PRODUCTION

FROM python:3.9 As production

WORKDIR /app

RUN apt-get update && apt-get install -y python3

RUN apt-get install -y python3-pip

RUN apt-get install -y build-essential

COPY requirements.txt /

RUN pip3 install --trusted-host pypi.python.org -r /requirements.txt


EXPOSE 8000

COPY . .

CMD ["gunicorn", "-k", "gevent", "-b", "0.0.0.0:8000", "app.wsgi:app"]
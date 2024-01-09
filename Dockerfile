FROM nvidia/cuda:11.7.1-runtime-ubuntu20.04

# Install necessary dependencies
RUN apt-get update && apt-get upgrade && apt-get install -y python3-pip

# Set the working directory
WORKDIR /app

# Copy the app code and requirements filed
COPY . /app

# Install the app dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

RUN pip install nvidia-cublas-cu11 nvidia-cudnn-cu11

RUN export LD_LIBRARY_PATH=`python3 -c 'import os; import nvidia.cublas.lib; import nvidia.cudnn.lib; print(os.path.dirname(nvidia.cublas.lib.__file__) + ":" + os.path.dirname(nvidia.cudnn.lib.__file__))'`

ENTRYPOINT [ "python3", "main.py" ]
sudo docker stop $(sudo docker ps -a -q)
sudo docker rm $(sudo docker ps -a -q)
sudo sudo docker build -t asr .
sudo docker run -p 9000:8080 asr
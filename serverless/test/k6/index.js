import http from 'k6/http';
import { sleep } from 'k6';
import { audioBase64 } from './audioBase64.js';

export let options = {
  vus: 10, // VIRTUAL USERS
  duration: '1m',
};

export default function () {
  const url = 'https://b62rss5pn3ufd7w2uwnaroo5qu0ujcsb.lambda-url.sa-east-1.on.aws/';

  const randomNumber = Math.floor(Math.random() * 20)

  const payload = JSON.stringify({
    expected_speech:  `ENTRADA ${randomNumber} 40`,
    audio: audioBase64,
  });

  console.log(randomNumber);

  // const params = {
  //   headers: {
  //     'Content-Type': 'application/json',
  //   },
  // };

  const response = http.post(url, payload);

  if (response.status === 200) {
    console.log('Solicitação bem-sucedida!');
  } else {
    console.error(`Erro na solicitação: ${response.status}`);
  }
}
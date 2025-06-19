# Speech API/ App

Toda a validação ocorre dentro do diretório `/app`, e os modelos `pt-br` baixados se encontram em `/models`.

É importante observar que a performance de execução da biblioteca whisper, e o tempo de execução de transcrição estão diretamente ligados a quantidade de threads de CPU e WORKERS para trabalhar em cada tarefa.


## Instalando depêndencias

```sh
python3 pip install -r requirements.txt
```

## Rodando o projeto em desenvolvimento

O comando abaixo deverá ser rodado no diretório `server/app`.

`url base: http://127.0.0.1:5000`

```sh
python3 -m flask --debug run
```

## Rodando o projeto com  docker compose

O comando abaixo deverá ser rodado no diretório `server/app`.

`url base: http://0.0.0.0:9999`

```sh
sudo docker compose
```

## Rotas

### Transcrição de áudio

Este endpoint faz a transcrição e validação do áudio de acordo com os parâmetros passados.

Requisição
- Método: `POST`
- URL: `/auth`
- Header: `Content-Type: multipart/form`
O corpo da requisição deve ser um objeto com o seguinte modelo:

```json
{
	"expected_speech": "ENTRADA 13 40",
	"audio": "audio.mp4"
}
```
Resposta de Sucesso
- Código de status: `200 OK`
- Corpo da resposta:
```json
{
	"validated": true,
	"spoken_text_in_audio": " Entrada 13 horas e 40."
}
```

`Observação`: O parâmetro `audio` na requisição deve ser passado com espaços entre as strings, como no exemplo passado acima, e sem espaçoes no começo e final da string.


## Git LFS

O projeto está usando o [Git LFS](https://github.com/git-lfs/git-lfs) em arquivos `*.bin` para não comprometer seu histórico do Git. Veja o `.gitattributes` para mais detalhes.
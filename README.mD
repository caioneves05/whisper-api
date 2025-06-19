# Speech API

Este projeto roda a biblioteca [faster whisper](https://github.com/SYSTRAN/faster-whisper) para realizar a trasncrição de um áudio recebido pela nossa API, assim aplicando toda a validação de registro ponto de acordo com os formatos de horário AM, PM, e escritos por extenso.

# Implementações

Este projeto contém 2 tipos de implementações e suas respectivas documentações.

## Server

Este projeto opera em sua máquina com uma dependência considerável de processamento, já que as configurações de hardware influenciarão diretamente na capacidade e tempo de resposta da API.

[documentação](https://github.com/ruk-encoding-paths/speech-api/tree/main/server)

## Serverless


Este projeto aproveita uma função lambda no servidor da AWS para sua execução, eliminando a necessidade de capacidade de processamento ou escalonamento horizontal de máquinas, pois a Amazon gerencia e otimiza todo o processo.

[documentação](https://github.com/ruk-encoding-paths/speech-api/tree/main/serverless)
// ignore_for_file: avoid_print, unnecessary_null_comparison, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';

import 'package:Mobi/repositories/_get_host.dart';
import 'package:Mobi/repositories/registro_ponto_repository.dart';
import 'package:Mobi/repositories/ultimos_pontos_repository.dart';
import 'package:Mobi/screens/registro_ponto/components/ponto_ok.dart';
import 'package:Mobi/services/store.dart';
import 'package:Mobi/utils/constants.dart';
import 'package:Mobi/utils/printHighlighted.dart';
import 'package:Mobi/validators/registro_ponto/registro_ponto_validator.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/speech/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:Mobi/services/http_client.dart';
import 'package:screenshot/screenshot.dart';

// ignore: constant_identifier_names
enum GravarAudioState { IDLE, LOADING }

class RegistroPontoAudioBloc extends BlocBase with RegistroPontoValidator {
  final String _token = Constants.TOKEN_NOT_LOGIN;

  final RegistroPontoRepository _repository = RegistroPontoRepository();
  final UltimosPontosRepository _repositoryPonto = UltimosPontosRepository();
  final HostRepository _repositoryHost = HostRepository();

  final _stateAudioController = BehaviorSubject<GravarAudioState>();
  final _registroCabecalhoController = BehaviorSubject<dynamic>();
  final _statusAudioController = BehaviorSubject<String>();
  final _repetirAudioController = BehaviorSubject<dynamic>();
  final _erroAudioController = BehaviorSubject<dynamic>();

  Stream<dynamic> get outCabecalhoAudio => _registroCabecalhoController.stream;
  Stream<String> get outStatusAudio => _statusAudioController.stream;
  Stream<dynamic> get outRepetirAudio => _repetirAudioController.stream;
  Stream<dynamic> get outErrorAudio => _erroAudioController.stream;
  Stream<GravarAudioState> get outStateAudio => _stateAudioController.stream;

  Future<Map<String, dynamic>> getMapPonto() async {
    Map<String, dynamic> registroPonto = await Store.getMap('registroPonto');
    _registroCabecalhoController.sink.add(registroPonto);
    return Future.value(registroPonto);
  }

  Future<dynamic> addNewFieldRegistroPonto(String key, dynamic field) async {
    const keyStore = 'registroPonto';
    dynamic registroPonto = await Store.getMap(keyStore);

    if (registroPonto == null) {
      await Store.saveMap(keyStore, {});
      registroPonto = {};
    }

    registroPonto[key] = field;
    await Store.saveMap(keyStore, registroPonto);

    //print(registroPonto);
    Future.value(registroPonto);
  }

  gravarAudio() {
    _statusAudioController.sink.add('PREPARE-SE JÁ IREMOS GRAVAR O ÁUDIO');
    _erroAudioController.sink.add(null);
    _repetirAudioController.sink.add(null);
  }

  Future<String> printScreen(ScreenshotController screenshotController) async {
    String pathFinal = '';
    await screenshotController
        .capture(delay: const Duration(milliseconds: 10))
        .then((image) async {
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        pathFinal =
            '${directory.path}/${DateTime.now().microsecondsSinceEpoch}.png';
        final imagePath = await File(pathFinal).create();
        await imagePath.writeAsBytes(image);
        //print('pathFinal: $pathFinal');
      }
    });
    return pathFinal;
  }

  final _credentials = ServiceAccountCredentials.fromJson(r'''
        {
          "type": "service_account",
          "project_id": "msiga-f75d7",
          "private_key_id": "5e898b9cf8f96a41f5f9284e1803df65589935f4",
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC/MlJ/9uUcMq8+\nCAqhtFZFMOAQWi2dF2wdPXJRVOBnAE7DDgWENXiGAMXlWhkINdm71mNu6nLU68sE\nAXg6do13t457QVPkPApeKnQRP0TlUbdqg61IpGu4E5mznGEGisS/bkVxwatfhHAp\nWmBLk27np0HXlHdqQ+hw/vkR1N2bCNKBf39WWNzkwY05sNmAGZpChta0+1ZBzBsZ\n8V2l8FGiQDdIVs65TW5dQlmrmDAI726PSh4JM9v02DXcsaXHRtd303Ge0p1t6ZWK\nQugwf/5phmJvUIvVoEkxbGqIZopn79GtKKHuiH4QM9FWJ6mHJd1Towqk6w051FCL\nTp1nTyrXAgMBAAECggEADyv+mPHuF1E8T7dSpKdLSz1IInQNd5BCv4U/O435KqM/\nHMJRlL6rfDK2gW8nWlvvlbS6+jO3fgbh+sTlFfqPWkciEszJy+wpxHQo9q9nF61m\n2Rhu2TtW4uoHQdXwaxT67Nfiwdak8zTus5Fc39JotBA1LNa2rSOLX+ATwqL6HNGw\nqSnW654lxT7Sa8JrohXsDKHGSaT0pUBpbtED5fTRgZu8lvmQiL/hptBi1BrRqo8+\n/EQPOdL1qfFQEo9JOp4fYYgL/o2+jiSFLbtOLVCpbCknBixjNNRZIGGxqA7apOOP\nybuy1I36aBoKfEGRUQm2dVFXmo6Bqp1OR2ods/Ns6QKBgQDw9fLTAVmma/yeIQcV\n+tGPwy/PNwdHPw8UVmUeX6ochCs1t/W1L2npKKZcSoy45HOrPjRu4RhukIFEWLRz\n7UCnK0tH8JCZ7QxhQCFgEuLu4SZzAWIFdK/ALAfoY7pqIrSFAMWRiNjB46eeO2V9\nd/mBKI1yDuLx3dciTdDPGDcSWQKBgQDLIT7w7jv2lOW8JLTrMk7mwbSQDIyYibzr\nPDpfqqj7OzY/oKpfTRL6pjJRrdrRFZ8a46csEs7IcLibbO8A4GGzLvNZ6tGZxXtA\n1G6sY6uLybf3iSIrQCcBiioAWK3dFuym9srz1WoVBehlTOrN+62nA9YfeGqyFWAn\nohC9ZYKgrwKBgQCwK3GEeek8tpj0V7thg4axsAgFXPsySNVSjjPR+ClcPfmFheDb\nvjWV5UV0FoE6MLSsz4bwRhxhwb7w5FXSp/RsBEg+6ZAfKeOyOnvsTQKjmfNNhAZR\nbNWOD+McMcW6EXOgBkdsNvwbDcGf+1chW5UMrER1zpJ4OTQv/Wqb7t1cyQKBgDrO\nZCdiAPARCTVftxTEGr2JZJmzWFysu4mqhQe/I26gJMNk4w32BUGVLcoht9CCHu6s\n62/B/iVfJMKyVbr+OqqiNAdbCNUoq9cH6QZ1UGuGuYCrLb4xs1kpw6EYCzWPdnGb\nzwOqTCzL6gyxqOR7MTnBzZKMzO7Da3Pt4kTCh3+3AoGAZzrgeg3wWPliTDsfyhGM\nrjz8mogapzthmcHan0Ig46XDV4DH5xC02j5JTjyFLY9ywp9tDo9MCEoo3f0pfdlg\n8et10JBmqGinpNev9EmBGA/y/dSqOtE8Oeo3DimUUyWKF0LIdcVbIl0/0MU65znC\nJG16pI4o1aCji+xtMJ96Mxc=\n-----END PRIVATE KEY-----\n",
          "client_email": "cloud-speech-to-text-api@msiga-f75d7.iam.gserviceaccount.com",
          "client_id": "117924555040650505592",
          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
          "token_uri": "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/cloud-speech-to-text-api%40msiga-f75d7.iam.gserviceaccount.com"
        }
        ''');

  // ignore: non_constant_identifier_names
  final dynamic _SCOPES = const [SpeechApi.cloudPlatformScope];

  Future<bool?> audioRecog(dynamic file) async {
    bool? valida;
    _stateAudioController.add(GravarAudioState.LOADING);
    valida = null;
    try {
      await clientViaServiceAccount(_credentials, _SCOPES)
          .then((httpClient) async {
        printGreen(httpClient.toString());
        var speech = SpeechApi(httpClient);
        final bytes = io.File(file).readAsBytesSync();
        dynamic audioString = base64Encode(bytes);
        printYellow(audioString.toString());

        //print('Reconhecer o áudio');

        dynamic json = {
          "config": {
            "encoding": "LINEAR16",
            "sampleRateHertz": 44100,
            "languageCode": "pt-BR",
            "enableWordTimeOffsets": false,
            "enableAutomaticPunctuation": true,
            "model": "default"
          },
          "audio": {
            "content": audioString,
          }
        };

        RecognitionConfig(
            encoding: "LINEAR16",
            sampleRateHertz: 44100,
            languageCode: "pt-BR",
            model: "default");
        dynamic recognizeRequest = RecognizeRequest.fromJson(json);

        // ignore: missing_return

        await speech.speech.recognize(recognizeRequest).then((response) async {
          //print(response.results);
          try {
            if (response.results != null) {
              for (var result in response.results!) {
                //print(result.alternatives![0]);
                //print(result.alternatives![0].transcript);
                String results = result.alternatives![0].transcript!;
                //print('---------------- Resulta reconhecido');
                //print(results);
                //print('---------------- Resulta reconhecido');
                valida = await validacao(results);
                //print('---------------- VALIDACAO ENVIADA');
                //print(valida);
                //print('---------------- VALIDACAO ENVIADA');
                _stateAudioController.add(GravarAudioState.IDLE);
                return valida;
              }
            } else {
              valida = await validacao(null);
              //print('ENTREI AQUI');
              _stateAudioController.add(GravarAudioState.IDLE);
              return valida;
            }
          } catch (e) {
            printRed(e.toString());
            //print("caiu no catch recognize");
          }
        });
      });
    } catch (e) {
      //print(e);
      //print('ENTREI AQUI ERRO');
      valida = null;
      _stateAudioController.add(GravarAudioState.IDLE);
      return null;
    }

    _stateAudioController.add(GravarAudioState.IDLE);
    return valida;
  }

  Future<bool> validacao(dynamic resultado) async {
    Map<String, dynamic> registroPonto = await Store.getMap('registroPonto');
    String tipo = registroPonto['ponto']['tipo'];
    String horaServer = registroPonto['data_ponto'];
    String horarioServidor =
        DateFormat("HH:mm").format(DateTime.parse(horaServer).toLocal());

    var verificarHoraZero = horarioServidor[0];

    if (tipo == "Retorno Pausa") {
      tipo = "Retorno";
    }

    //print('----------------recebido');
    //print(resultado);
    //print('----------------recebido');

    if (resultado == null) {
      mudaStatusAudio('GRAVAR ÁUDIO NOVAMENTE');
      mudaRepitaAudio(null);
      mudaErroAudio('NÃO VÁLIDO');
      return false;
    }

    if (verificarHoraZero == '0') {
      var novoHorario = horarioServidor.substring(1);
      //print("$tipo $novoHorario");

      //print(resultado);

      List<dynamic> coded = [
        " horas",
        " e ",
        "meio-dia",
        "meia-noite e ",
        " e meia",
        "sair daqui",
        ".",
        "às",
        "as",
        " i ",
        "meio dia",
        "em",
        "pausar",
        " da noite",
        " da tarde",
        " da manhã",
        " inove",
        "0:00:",
        "uma hora",
      ];

      List<dynamic> decoded = [
        ":00",
        ":0",
        "12:00",
        "00:",
        ":30",
        "saída",
        "",
        "",
        "",
        ":",
        "12:00",
        "",
        "pausa",
        "",
        "",
        "",
        ":09",
        "0:",
        "1:00",
      ];

      Map<dynamic, dynamic> map = Map.fromIterables(coded, decoded);

      resultado = map.entries
          .fold(resultado, (prev, e) => prev.replaceAll(e.key, e.value));

      resultado =
          corrigirHorariosMalIdentificados(tipo, novoHorario, resultado);

      //print(resultado);

      if (resultado.contains(":0")) {
        var results = resultado.split(":");
        if (results[1].length == 3) {
          resultado = results[0] + ":" + results[1].substring(1, 3);
          //print(resultado);
        }
      }

      if (!resultado.contains(":")) {
        var results = resultado.split(" ");
        //print(results);

        RegExp numberIf = RegExp(r'^\b[0-9]+\b');

        if (results.length > 2) {
          if (numberIf.hasMatch(results[1]) == true &&
              numberIf.hasMatch(results[2]) == true) {
            if (results[1].length == 1 && results[2].length == 1) {
              resultado = results[0] + " " + results[1] + ":0" + results[2];
            } else if (results[1].length == 1) {
              resultado = results[0] + " " + results[1] + ":" + results[2];
            } else if (results[2].length == 1) {
              resultado = results[0] + " " + results[1] + ":0" + results[2];
            } else {
              resultado = results[0] + " " + results[1] + ":" + results[2];
            }
          }
        } else if (results.length == 2) {
          if (numberIf.hasMatch(results[1]) == true) {
            if (results[1].length == 4) {
              resultado = results[0] +
                  " " +
                  results[1].substring(0, 2) +
                  ":" +
                  results[1].substring(2, 4);
            } else if (results[1].length == 3) {
              resultado = results[0] +
                  " " +
                  results[1].substring(0, 1) +
                  ":" +
                  results[1].substring(1, 3);
            } else if (results.length == 2) {
              resultado = results[0] +
                  " " +
                  results[1].substring(0, 1) +
                  ":0" +
                  results[1].substring(1, 2);
            }
          }
        }
        //print(resultado);
      }

      if ("${tipo.toLowerCase()} ${novoHorario.toLowerCase()}" ==
          resultado.toLowerCase()) {
        mudaErroAudio(null);

        return true;
      } else {
        mudaStatusAudio('GRAVAR ÁUDIO NOVAMENTE');
        mudaRepitaAudio(null);
        mudaErroAudio('NÃO VÁLIDO');

        return false;
      }
    } else {
      //print("$tipo $horarioServidor");
      //print(resultado);

      List<dynamic> coded = [
        " horas",
        " e ",
        "meio-dia",
        "meia-noite e ",
        " e meia",
        "sair daqui",
        ".",
        "às",
        "as",
        " i ",
        "meio dia",
        "em",
        "pausar",
        " da noite",
        " da tarde",
        " da manhã",
        " inove",
        "0:00:",
        "uma hora",
      ];

      List<dynamic> decoded = [
        ":00",
        ":0",
        "12:00",
        "00:",
        ":30",
        "saída",
        "",
        "",
        "",
        ":",
        "12:00",
        "",
        "pausa",
        "",
        "",
        "",
        ":09",
        "0:",
        "1:00",
      ];
      Map<dynamic, dynamic> map = Map.fromIterables(coded, decoded);

      resultado = map.entries
          .fold(resultado, (prev, e) => prev.replaceAll(e.key, e.value));

      //print(resultado);

      if (resultado.contains(":0")) {
        var results = resultado.split(":");
        if (results[1].length == 3) {
          resultado = results[0] + ":" + results[1].substring(1, 3);
          //print(resultado);
        }
      }

      if (resultado.contains("12:00:0")) {
        var results = resultado.split(":");
        resultado =
            results[0] + ":" + results[2].substring(results[2].length - 2, 3);
        //print(resultado);
      }

      if (resultado.contains("12:00")) {
        var results = resultado.split(":");
        if (results[1].length > 2) {
          List<dynamic> coded = ["00", "00 "];
          List<dynamic> decoded = ["", ""];
          Map<dynamic, dynamic> map = Map.fromIterables(coded, decoded);
          var horarioMeioDia = results[1];
          horarioMeioDia = map.entries
              .fold(resultado, (prev, e) => prev.replaceAll(e.key, e.value));

          resultado = results[0] + ":" + horarioMeioDia;
          //print(resultado);
        }
      }

      if (!resultado.contains(":")) {
        var results = resultado.split(" ");
        //print(results);

        RegExp numberIf = RegExp(r'^\b[0-9]+\b');

        if (results.length > 2) {
          if (numberIf.hasMatch(results[1]) == true &&
              numberIf.hasMatch(results[2]) == true) {
            if (results[1].length == 1 && results[2].length == 1) {
              resultado = results[0] + " 0" + results[1] + ":0" + results[2];
            } else if (results[1].length == 1) {
              resultado = results[0] + " 0" + results[1] + ":" + results[2];
            } else if (results[2].length == 1) {
              resultado = results[0] + " " + results[1] + ":0" + results[2];
            } else {
              resultado = results[0] + " " + results[1] + ":" + results[2];
            }
          }
        } else if (results.length == 2) {
          if (numberIf.hasMatch(results[1]) == true) {
            if (results[1].length == 4) {
              resultado = results[0] +
                  " " +
                  results[1].substring(0, 2) +
                  ":" +
                  results[1].substring(2, 4);
            } else if (results[1].length == 3) {
              resultado = results[0] +
                  " " +
                  results[1].substring(0, 2) +
                  ":0" +
                  results[1].substring(2, 3);
            }
          }
        }
        //print(resultado);
      }

      if ("${tipo.toLowerCase()} ${horarioServidor.toLowerCase()}" ==
          resultado.toLowerCase()) {
        mudaErroAudio(null);

        return true;
      } else {
        mudaStatusAudio('GRAVAR ÁUDIO NOVAMENTE');
        mudaRepitaAudio(null);
        mudaErroAudio('NÃO VÁLIDO');

        return false;
      }
    }
  }

  Future<String> textoRepetir(String horario, String tipo) async {
    dynamic horarioServidor =
        DateFormat("HH:mm").format(DateTime.parse(horario).toLocal());

    if (tipo == "Retorno Pausa") {
      tipo = "Retorno";
    }

    var result = horarioServidor.split(":");

    List<dynamic> codedHour = [
      "00",
      "01",
      "02",
      "03",
      "04",
      "05",
      "06",
      "07",
      "08",
      "09",
      "10",
      "11",
      "12",
      "13",
      "14",
      "15",
      "16",
      "17",
      "18",
      "19",
      "20",
      "21",
      "22",
      "23",
    ];

    List<dynamic> decodedHour = [
      "Zero Horas",
      "Uma Hora",
      "Duas Horas",
      "Três Horas",
      "Quatro Horas",
      "Cinco Horas",
      "Seis Horas",
      "Sete Horas",
      "Oito Horas",
      "Nove Horas",
      "Dez Horas",
      "Onze Horas",
      "Doze Horas",
      "Treze Horas",
      "Quatorze Horas",
      "Quinze Horas",
      "Dezesseis Horas",
      "Dezessete Horas",
      "Dezoito Horas",
      "Dezenove Horas",
      "Vinte Horas",
      "Vinte e Uma Horas",
      "Vinte e Duas Horas",
      "Vinte e Três Horas",
    ];

    Map<dynamic, dynamic> mapHour = Map.fromIterables(codedHour, decodedHour);
    var horaEdit = mapHour.entries
        .fold(result[0], (prev, e) => prev.replaceAll(e.key, e.value));

    List<dynamic> codedMinute = [
      '00',
      '01',
      '02',
      '03',
      '04',
      '05',
      '06',
      '07',
      '08',
      '09',
      '10',
      '11',
      '12',
      '13',
      '14',
      '15',
      '16',
      '17',
      '18',
      '19',
      '20',
      '21',
      '22',
      '23',
      '24',
      '25',
      '26',
      '27',
      '28',
      '29',
      '30',
      '31',
      '32',
      '33',
      '34',
      '35',
      '36',
      '37',
      '38',
      '39',
      '40',
      '41',
      '42',
      '43',
      '44',
      '45',
      '46',
      '47',
      '48',
      '49',
      '50',
      '51',
      '52',
      '53',
      '54',
      '55',
      '56',
      '57',
      '58',
      '59',
    ];

    List<dynamic> decodedMinute = [
      '',
      ' e Um',
      ' e Dois',
      ' e Três',
      ' e Quatro',
      ' e Cinco',
      ' e Seis',
      ' e Sete',
      ' e Oito',
      ' e Nove',
      ' e Dez',
      ' e Onze',
      ' e Doze',
      ' e Treze',
      ' e Quatorze',
      ' e Quinze',
      ' e Dezesseis',
      ' e Dezessete',
      ' e Dezoito',
      ' e Dezenove',
      ' e Vinte',
      ' e Vinte e Um',
      ' e Vinte e Dois',
f
    ];

    Map<dynamic, dynamic> mapMinute =
        Map.fromIterables(codedMinute, decodedMinute);
    var minuteEdit = mapMinute.entries
        .fold(result[1], (prev, e) => prev.replaceAll(e.key, e.value));

    return '$tipo $horaEdit$minuteEdit';
  }

  // Relizando o processo de efetivação do Ponto
  efetivarPonto(BuildContext context) async {
    //print('Efetivar Ponto');
    mudaStatusAudio('EFETIVANDO MARCACAO');
    mudaRepitaAudio('ÁUDIO VALIDADO');
    mudaErroAudio(null);

    _stateAudioController.add(GravarAudioState.LOADING);
    Map<String, dynamic> registroPonto = await Store.getMap('registroPonto');

    bool ocorrencia = registroPonto['ponto']['ocorrencia'];
    String horaServer = registroPonto['data_ponto'].toString();
    String tipo = registroPonto['ponto']['tipo'].toString();
    String dia = registroPonto['ponto']['dia'].toString();
    int idColab = registroPonto['colaborador']['codigo'];

    try {
      await addPontoColab(idColab, tipo, horaServer, dia);
    } catch (e) {
      //print(e);
    }

    try {
      dynamic atestadoPath = registroPonto['atestado'];
      dynamic task;
      String screenshotPath = '';
      final host = await _repositoryHost.getHost(api: true);

      if (registroPonto['screenshot'] != null) {
        mudaStatusAudio('UPLOAD PRINT');
        final dynamic screenshot = await HttpClient.uploadFileAsFormData(
            registroPonto['screenshot'], '$host/public/upload/pontoCerto',
            token: _token);
        screenshotPath = screenshot['dir'] + '/' + screenshot['file'];
        //print(screenshotPath);
      }

      mudaStatusAudio('UPLOAD AUDIO');
      final dynamic audioFile = await HttpClient.uploadFileAsFormData(
        registroPonto['audio'],
        '$host/public/upload/pontoCerto',
        token: _token,
      );
      String audioPath = audioFile['dir'] + '/' + audioFile['file'];
      //print(audioPath);

      mudaStatusAudio('UPLOAD SELFIE');
      final dynamic selfieFile = await HttpClient.uploadFileAsFormData(
          registroPonto['selfie'], '$host/public/upload/pontoCerto',
          token: _token);
      String selfiePath = selfieFile['dir'] + '/' + selfieFile['file'];
      //print(selfiePath);

      if (ocorrencia == true) {
        if (atestadoPath != null) {
          mudaStatusAudio('UPLOAD ATESTADO');
          final dynamic atestado = await HttpClient.uploadFileAsFormData(
              registroPonto['atestado'], '$host/public/upload/task',
              token: _token);
          atestadoPath = atestado['file'];
          //print(atestadoPath);
        }
        mudaStatusAudio('CRIANDO TASK');
        task = await _repository.criarTask(atestadoPath);
      }

      mudaStatusAudio('EFETIVANDO MARCACAO');
      await _repository.efetivarMarcacao(
          audioPath, screenshotPath, selfiePath, atestadoPath, task, false);

      registroPonto['online'] = true;
      await _repositoryPonto.addUltimosPontos(registroPonto, idColab);

      _stateAudioController.add(GravarAudioState.IDLE);
      return dialogPontoEfetivado(context, ocorrencia, tipo, horaServer, false);
    } catch (e) {
      //print(e);
      //print('Salvar Registro Offline');

      if (e.toString().toLowerCase().contains('internel') == true ||
          e.toString().toLowerCase().contains('ocorreu um erro') == true) {
        mudaStatusAudio('SALVANDO REGISTRO OFFLINE');
        await saveOfflinePoint();

        registroPonto['online'] = false;
        await _repositoryPonto.addUltimosPontos(registroPonto, idColab);

        _stateAudioController.add(GravarAudioState.IDLE);
        return dialogPontoEfetivado(
            context, ocorrencia, tipo, horaServer, true);
      } else {
        _stateAudioController.add(GravarAudioState.IDLE);
        mudaStatusAudio('ERRO AO SALVAR REGISTRO');
        late Timer timer;

        return showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            timer = Timer(const Duration(seconds: 20), () {
              //print("20 Segundos inativo");
              Navigator.pop(context);
              Navigator.pop(context);
            });

            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                backgroundColor: Colors.red,
                title: const Text(
                  "Efetivação do Ponto",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
                content: Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 18.0),
                ),
                actions: [
                  TextButton(
                    child: const Text("OK",
                        style: TextStyle(color: Colors.white, fontSize: 20.0)),
                    onPressed: () {
                      timer.cancel();
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        ).then((value) => timer.cancel());
      }
    }
  }

  // Função para salvar o registro de ponto offline caso haja algum erro para realizar o upload do mesmo.
  saveOfflinePoint() async {
    List toDoList = [];

    try {
      await _readDataOfflinePoint().then((data) {
        toDoList = json.decode(data);
      });
    } catch (e) {
      toDoList = [];
    }

    Map<String, dynamic> registroPonto = await Store.getMap('registroPonto');
    toDoList.add(registroPonto);

    await _saveDataOfflinePoint(toDoList);
  }

  Future<File> _getFileOfflinePoint() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveDataOfflinePoint(List toDoList) async {
    String data = json.encode(toDoList);
    final file = await _getFileOfflinePoint();
    return file.writeAsString(data);
  }

  Future<String> _readDataOfflinePoint() async {
    try {
      final file = await _getFileOfflinePoint();
      return file.readAsString();
    } catch (e) {
      //print(e);
      return "";
    }
  }

  // Função para adicionar o arquivo de ponto para ser lido offline.
  addPontoColab(
      dynamic idColab, String tipo, dynamic horaServer, dynamic dia) async {
    List toDoListColab = [];

    await _readDataPonto(idColab).then((data) {
      toDoListColab = json.decode(data);
    });

    // ignore: prefer_collection_literals
    Map<String, dynamic> newToDo = Map();
    newToDo["codigo"] = idColab;
    newToDo["tipo"] = tipo;
    newToDo["horario"] = horaServer.toString();
    newToDo["dia"] = dia.toString();

    toDoListColab.add(newToDo);

    await saveDataListPonto(toDoListColab, idColab);
  }

  Future<File> _getFile(dynamic idColab) async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/${idColab}_pontos.json");
  }

  Future<String> _readDataPonto(dynamic idColab) async {
    try {
      final file = await _getFile(idColab);
      return file.readAsString();
    } catch (e) {
      return "";
    }
  }

  Future<File> saveDataListPonto(dynamic toDoList, dynamic colabId) async {
    String data = json.encode(toDoList);
    final file = await _getFile(colabId);
    //print("Arquivo de Ponto Atualizado");
    return file.writeAsString(data);
  }

  dialogPontoEfetivado(
      BuildContext context, ocorrencia, tipo, horarioServidor, bool offline) {
    dynamic dataServer =
        DateFormat('HH:mm').format(DateTime.parse(horarioServidor).toLocal());

    String textoPonto = "Você registrou o ponto de $tipo as $dataServer";
    String tituloPonto = "Ponto Batido";

    if (offline == false && ocorrencia == true) {
      textoPonto =
          "Você registrou uma Ocorrência de Ponto para o ponto de $tipo as $dataServer";
      tituloPonto = "Ocorrência de Ponto";
    }

    if (offline == true) {
      textoPonto =
          "Você registrou o ponto de $tipo as $dataServer, ocorreu um erro para realizar a efetivação do ponto, verifique a internet e sincronize o ponto. O mesmo foi salvo, basta sincronizar";
    }

    if (offline == true && ocorrencia == true) {
      tituloPonto = "Ocorrência de Ponto";
      textoPonto =
          "Você registrou uma Ocorrência de Ponto para o ponto de $tipo as $dataServer, ocorreu um erro para realizar a efetivação do ponto, verifique a internet e sincronize o ponto. O mesmo foi salvo, basta sincronizar";
    }

    late Timer timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        timer = Timer(const Duration(seconds: 20), () {
          //print("20 Segundos inativo");
          Navigator.pop(context);
          Navigator.pop(context);
        });
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: offline == true ? Colors.red : Colors.green,
            title: Text(tituloPonto,
                style: const TextStyle(color: Colors.white, fontSize: 20.0)),
            content: PontoOK(textoPonto: textoPonto),
            actions: [
              TextButton(
                child: const Text("OK",
                    style: TextStyle(color: Colors.white, fontSize: 20.0)),
                onPressed: () {
                  timer.cancel();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    ).then((value) => timer.cancel());
  }

  mudaStatusAudio(String text) {
    _statusAudioController.sink.add(text);
  }

  mudaRepitaAudio(dynamic text) {
    _repetirAudioController.sink.add(text);
  }

  mudaErroAudio(dynamic text) {
    _erroAudioController.sink.add(text);
  }

  @override
  void dispose() {
    _registroCabecalhoController.close();
    _statusAudioController.close();
    _repetirAudioController.close();
    _erroAudioController.close();
    _stateAudioController.close();
    super.dispose();
  }
}

dynamic corrigirHorariosMalIdentificados(
    String tipo, String horarioServer, String horarioIdentificado) {
  if (((horarioServer == '8:09' || horarioServer == '8:13') &&
          tipo == 'entrada') &&
      (horarioIdentificado == 'entrada 8:30')) {
    return '$tipo $horarioServer';
  } else {
    return horarioIdentificado;
  }

  // List<dynamic> horariosMalIdentificados = [
  //   {
  //     'speechResult': 'entrada 8:30',
  //     'matches': ['8:09', '8:15'],
  //     'tipo': 'entrada'
  //   },
  //   {
  //     'speechResult': 'saída 10:12',
  //     'matches': ['8:09', '8:15'],
  //     'tipo': 'saída'
  //   }
  // ];

  // horariosMalIdentificados.forEach((horario) => {
  //       if (horario['speechResult'] == horarioIdentificado &&
  //           horario['tipo'] == tipo)
  //         {
  //           horario['matches'].forEach((possivelHorarioSolicitado) {
  //             if (possivelHorarioSolicitado == horarioServer) {
  //               horarioIdentificado =
  //                   horario['tipo'] + ' ' + possivelHorarioSolicitado;
  //             }
  //           })
  //         }
  //     });

  // return horarioIdentificado;
}
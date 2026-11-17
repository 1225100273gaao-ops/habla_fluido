import 'package:flutter_test/flutter_test.dart';
import 'package:habla_fluido/datos/tutor_simulado.dart';
import 'package:habla_fluido/datos/voz_simulada.dart';
import 'package:habla_fluido/dominio/nivel.dart';
import 'package:habla_fluido/presentacion/vm/dictado_vm.dart';
import 'package:habla_fluido/presentacion/vm/escritura_vm.dart';
import 'package:habla_fluido/presentacion/vm/lectura_vm.dart';
import 'package:habla_fluido/presentacion/vm/pronunciacion_vm.dart';

import 'ayudas_vm.dart';

void main() {
  setUp(() => diaPrueba = DateTime(2026, 11, 5));

  group('PronunciacionViewModel', () {
    test('compara, registra el intento y crea tarjeta de repaso', () async {
      final cerebro = nuevoCerebro();
      final vm = PronunciacionViewModel(VozSimulada(['nice to meet you']), cerebro);
      await vm.grabar();
      expect(vm.resultado!.puntaje, 1.0);
      expect(cerebro.progreso.de(Habilidad.pronunciacion)!.intentos, 1);
      expect(cerebro.mazo.todas.single.id, 'a1-01');
    });
    test('silencio → mensaje amable y no registra nada', () async {
      final cerebro = nuevoCerebro();
      final vm = PronunciacionViewModel(VozSimulada([null]), cerebro);
      await vm.grabar();
      expect(vm.error, contains('No te escuché'));
      expect(vm.resultado, isNull);
      expect(cerebro.progreso.de(Habilidad.pronunciacion), isNull);
    });
    test('el modelo lento usa velocidad 0.6', () async {
      final voz = VozSimulada();
      final vm = PronunciacionViewModel(voz, nuevoCerebro());
      await vm.escucharModelo(lento: true);
      expect(voz.velocidades.single, 0.6);
      expect(voz.dichos.single, 'Nice to meet you.');
    });
    test('un error del micrófono no revela detalles', () async {
      final vm = PronunciacionViewModel(VozRota(), nuevoCerebro());
      await vm.grabar();
      expect(vm.error, 'Ocurrió un error inesperado. Intenta de nuevo.');
    });
    test('siguiente avanza y limpia el resultado', () async {
      final vm = PronunciacionViewModel(VozSimulada(['hola']), nuevoCerebro());
      await vm.grabar();
      vm.siguiente();
      expect(vm.resultado, isNull);
      expect(vm.actual.id, 'a1-02');
    });
    test('doble toque en "Escuchar" se ignora mientras habla', () async {
      final voz = VozLenta();
      final vm = PronunciacionViewModel(voz, nuevoCerebro());
      final a = vm.escucharModelo();
      final b = vm.escucharModelo();
      await Future.wait([a, b]);
      expect(voz.llamadas, 1);
    });
  });

  group('DictadoViewModel', () {
    test('exige escuchar primero', () async {
      final vm = DictadoViewModel(VozSimulada(), nuevoCerebro());
      await vm.enviar('algo');
      expect(vm.error, 'Primero escucha la frase.');
    });
    test('puntúa el oído y registra', () async {
      final cerebro = nuevoCerebro();
      final vm = DictadoViewModel(VozSimulada(), cerebro);
      await vm.reproducir();
      await vm.enviar('nice to meet you');
      expect(vm.resultado!.puntaje, 1.0);
      expect(cerebro.progreso.de(Habilidad.escucha)!.intentos, 1);
    });
    test('texto vacío', () async {
      final vm = DictadoViewModel(VozSimulada(), nuevoCerebro());
      await vm.reproducir();
      await vm.enviar('   ');
      expect(vm.error, 'Escribe lo que entendiste.');
    });
    test('siguiente reinicia las reproducciones', () async {
      final vm = DictadoViewModel(VozSimulada(), nuevoCerebro());
      await vm.reproducir();
      vm.siguiente();
      expect(vm.reproducciones, 0);
    });
  });

  group('LecturaViewModel', () {
    test('puntúa cuando se responden todas, una sola vez', () async {
      final cerebro = nuevoCerebro();
      final vm = LecturaViewModel(cerebro);
      await vm.responder(0, 1);
      await vm.responder(1, 2);
      expect(vm.terminado, isFalse);
      await vm.responder(2, 2);
      expect(vm.terminado, isTrue);
      expect(vm.correctas, 2);
      expect(vm.puntaje, closeTo(2 / 3, 1e-9));
      await vm.responder(0, 0);
      expect(vm.correctas, 2);
      expect(cerebro.progreso.de(Habilidad.lectura)!.intentos, 1);
    });
    test('opciones o preguntas inexistentes se ignoran', () async {
      final vm = LecturaViewModel(nuevoCerebro());
      await vm.responder(9, 0);
      await vm.responder(0, 9);
      expect(vm.respuestas, isEmpty);
    });
    test('siguienteTexto reinicia', () async {
      final vm = LecturaViewModel(nuevoCerebro());
      await vm.responder(0, 1);
      vm.siguienteTexto();
      expect(vm.respuestas, isEmpty);
    });
  });

  group('EscrituraViewModel', () {
    test('menos de 5 palabras no se envía', () async {
      final vm = EscrituraViewModel(TutorSimulado(), nuevoCerebro());
      await vm.enviar('hello there');
      expect(vm.error, contains('5 palabras'));
      expect(vm.resultado, isNull);
    });
    test('texto con un error → puntaje 0.8 y se registra', () async {
      final cerebro = nuevoCerebro();
      final vm = EscrituraViewModel(TutorSimulado(), cerebro);
      await vm.enviar('He go to school every day');
      expect(vm.resultado!.correcciones.length, 1);
      expect(cerebro.progreso.dominioDe(Habilidad.escritura), closeTo(0.8, 1e-9));
    });
    test('puntajeDe', () {
      expect(EscrituraViewModel.puntajeDe(0), 1.0);
      expect(EscrituraViewModel.puntajeDe(2), closeTo(0.6, 1e-9));
      expect(EscrituraViewModel.puntajeDe(9), 0.0);
    });
  });
}
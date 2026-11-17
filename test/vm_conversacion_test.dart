import 'package:flutter_test/flutter_test.dart';
import 'package:habla_fluido/datos/tutor_simulado.dart';
import 'package:habla_fluido/datos/voz_simulada.dart';
import 'package:habla_fluido/dominio/nivel.dart';
import 'package:habla_fluido/presentacion/vm/conversacion_vm.dart';

import 'ayudas_vm.dart';

void main() {
  setUp(() => diaPrueba = DateTime(2026, 11, 5));

  group('ConversacionViewModel', () {
    test('inicia con un saludo del tutor, una sola vez', () {
      final vm = ConversacionViewModel(TutorSimulado(), VozSimulada(), nuevoCerebro());
      vm.iniciar();
      vm.iniciar();
      expect(vm.historial.length, 1);
      expect(vm.historial.single.delEstudiante, isFalse);
    });
    test('turno completo: mensajes, correcciones, voz y progreso', () async {
      final voz = VozSimulada();
      final cerebro = nuevoCerebro();
      final vm = ConversacionViewModel(TutorSimulado(), voz, cerebro)..iniciar();
      await vm.enviar('I am agree with you');
      expect(vm.historial.length, 3);
      expect(vm.ultimasCorrecciones.single.corregido, 'I agree');
      expect(voz.dichos.length, 1);
      expect(cerebro.progreso.dominioDe(Habilidad.conversacion), closeTo(0.75, 1e-9));
    });
    test('sin autoVoz el tutor no habla', () async {
      final voz = VozSimulada();
      final vm = ConversacionViewModel(TutorSimulado(), voz, nuevoCerebro())
        ..iniciar()
        ..alternarAutoVoz();
      await vm.enviar('Hello');
      expect(voz.dichos, isEmpty);
    });
    test('si el tutor falla: mensaje genérico, historial sin duplicar roles y texto recuperable', () async {
      final tutor = TutorQueFalla(1);
      final vm = ConversacionViewModel(tutor, VozSimulada(), nuevoCerebro())..iniciar();
      await vm.enviar('My text');
      expect(vm.error, 'Ocurrió un error inesperado. Intenta de nuevo.');
      expect(vm.error, isNot(contains('secreto')));
      expect(vm.historial.length, 1);
      expect(vm.textoNoEnviado, 'My text');
      await vm.enviar('My text');
      expect(vm.historial.length, 3);
      expect(vm.error, isNull);
    });
    test('mensajes vacíos o enormes se rechazan sin llamar al tutor', () async {
      final tutor = TutorQueFalla(0);
      final vm = ConversacionViewModel(tutor, VozSimulada(), nuevoCerebro())..iniciar();
      await vm.enviar('   ');
      await vm.enviar('x' * 501);
      expect(tutor.vistos, isEmpty);
      expect(vm.error, contains('más corto'));
    });
    test('dictar: reconoce la voz y la envía', () async {
      final vm = ConversacionViewModel(TutorSimulado(), VozSimulada(['I like music']), nuevoCerebro())..iniciar();
      await vm.dictar();
      expect(vm.historial[1].texto, 'I like music');
    });
    test('puntajeTurno', () {
      expect(ConversacionViewModel.puntajeTurno(0), 1.0);
      expect(ConversacionViewModel.puntajeTurno(2), 0.5);
      expect(ConversacionViewModel.puntajeTurno(9), 0.0);
    });
  });
}
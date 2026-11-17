import 'package:flutter_test/flutter_test.dart';
import 'package:habla_fluido/datos/almacen_avance.dart';
import 'package:habla_fluido/datos/voz_simulada.dart';
import 'package:habla_fluido/dominio/frase.dart';
import 'package:habla_fluido/dominio/nivel.dart';
import 'package:habla_fluido/presentacion/vm/aprendizaje_vm.dart';
import 'package:habla_fluido/presentacion/vm/repaso_vm.dart';

import 'ayudas_vm.dart';

void main() {
  setUp(() => diaPrueba = DateTime(2026, 11, 5));

  group('AprendizajeViewModel y persistencia', () {
    test('guarda y recupera progreso y tarjetas', () async {
      final almacen = AlmacenAvanceMemoria();
      final a = nuevoCerebro(almacen);
      await a.registrarIntento(Habilidad.pronunciacion, 1.0, frase: catalogoFrases.first);

      final b = nuevoCerebro(almacen);
      await b.cargar();
      expect(b.progreso.dominioDe(Habilidad.pronunciacion), 1.0);
      expect(b.mazo.todas.length, 1);
    });
    test('un fallo al guardar no interrumpe la práctica', () async {
      final a = AprendizajeViewModel(AlmacenRoto(), reloj: () => diaPrueba);
      await a.registrarIntento(Habilidad.lectura, 1.0);
      expect(a.progreso.de(Habilidad.lectura)!.intentos, 1);
    });
    test('plan de 20 minutos', () {
      expect(nuevoCerebro().plan.fold<int>(0, (s, b) => s + b.minutos), 20);
    });
  });

  group('RepasoViewModel', () {
    Future<AprendizajeViewModel> conTarjeta() async {
      final a = nuevoCerebro();
      await a.registrarIntento(Habilidad.pronunciacion, 0.2, frase: catalogoFrases.first);
      diaPrueba = DateTime(2026, 11, 6);
      return a;
    }

    test('hay que ver la respuesta antes de calificar', () async {
      final a = await conTarjeta();
      final vm = RepasoViewModel(a, VozSimulada());
      expect(vm.restantes, 1);
      await vm.calificar(5);
      expect(vm.restantes, 1);
    });
    test('calificar bien la saca de la cola y la aleja', () async {
      final a = await conTarjeta();
      final vm = RepasoViewModel(a, VozSimulada());
      await vm.mostrarRespuesta();
      await vm.calificar(5);
      expect(vm.terminado, isTrue);
      expect(a.pendientes, isEmpty);
    });
    test('"otra vez" la vuelve a poner al final de la cola', () async {
      final a = await conTarjeta();
      final vm = RepasoViewModel(a, VozSimulada());
      await vm.mostrarRespuesta();
      await vm.calificar(1);
      expect(vm.restantes, 1);
      expect(vm.respuestaVisible, isFalse);
    });
  });
}
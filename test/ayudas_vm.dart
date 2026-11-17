import 'package:habla_fluido/datos/almacen_avance.dart';
import 'package:habla_fluido/dominio/nivel.dart';
import 'package:habla_fluido/dominio/tutor.dart';
import 'package:habla_fluido/dominio/voz.dart';
import 'package:habla_fluido/presentacion/vm/aprendizaje_vm.dart';

DateTime diaPrueba = DateTime(2026, 11, 5);

AprendizajeViewModel nuevoCerebro([AlmacenAvanceMemoria? a]) =>
    AprendizajeViewModel(a ?? AlmacenAvanceMemoria(), reloj: () => diaPrueba);

class TutorQueFalla implements TutorIA {
  int fallos;
  final List<List<Mensaje>> vistos = [];
  TutorQueFalla(this.fallos);

  @override
  Future<RespuestaTutor> conversar({required NivelCefr nivel, required List<Mensaje> historial}) async {
    vistos.add([...historial]);
    if (fallos-- > 0) throw Exception('sin red: detalle interno secreto');
    return const RespuestaTutor('Nice!', siguientePregunta: 'And you?');
  }

  @override
  Future<RespuestaTutor> corregir({required NivelCefr nivel, required String texto}) =>
      throw UnimplementedError();
}

class VozLenta implements Voz {
  int llamadas = 0;

  @override
  Future<void> hablar(String texto, {double velocidad = 1.0}) async {
    llamadas++;
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }

  @override
  Future<String?> escuchar({Duration limite = const Duration(seconds: 8)}) async => 'x';

  @override
  Future<void> detener() async {}
}

class VozRota implements Voz {
  @override
  Future<void> hablar(String texto, {double velocidad = 1.0}) async => throw Exception('boom');

  @override
  Future<String?> escuchar({Duration limite = const Duration(seconds: 8)}) async => throw Exception('boom');

  @override
  Future<void> detener() async {}
}

class AlmacenRoto extends AlmacenAvanceMemoria {
  @override
  Future<void> guardar(Map<String, Object?> datos) async => throw Exception('disco lleno');
}
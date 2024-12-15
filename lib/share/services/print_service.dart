import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class PrinterService {
  final String printerIp;
  final int printerPort;

  PrinterService({required this.printerIp, this.printerPort = 9100});

  Future<void> printText(String text) async {
    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);

      final PosPrintResult res =
          await printer.connect(printerIp, port: printerPort);

      if (res == PosPrintResult.success) {
        printer.text(
          text,
          styles: PosStyles(align: PosAlign.center),
        );
        printer.feed(2); // Alimentar 2 líneas
        printer.cut();
        printer.disconnect();
        print('Impresión completada con éxito.');
      } else {
        print('Error al conectar con la impresora: ${res.msg}');
      }
    } catch (e) {
      print('Error al imprimir: $e');
    }
  }
}

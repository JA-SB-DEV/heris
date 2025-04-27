import 'dart:typed_data'; // Para Uint8List
import 'package:pdf/pdf.dart'; // Formato de página PDF
import 'package:pdf/widgets.dart' as pw; // Widgets para construir el PDF
import 'package:intl/intl.dart'; // Para formatear números y fechas
// Importar modelos necesarios
// Asegúrate que las rutas sean correctas desde lib/core/services/
import '../../data/models/item.dart';
// import '../../data/models/stock_level.dart'; // No se usa directamente aquí

// Clase para manejar la generación de PDFs
class PdfService {

  // Método principal para generar el PDF del inventario
  Future<Uint8List> generateInventoryPdf(
      List<Item> items, // Lista de todos los items
      Map<String, int> stockQuantities, // Mapa de itemId a cantidad de stock para la sede específica
      String locationName // Nombre de la bodega/sede del reporte
    ) async {

    final pdf = pw.Document(); // Crear documento PDF

    // --- Formateador de Moneda ---
    final currencyFormat = NumberFormat.currency(
        locale: 'es_CO', symbol: '', decimalDigits: 0, customPattern: '\$ #,##0');
    // -----------------------------

    // --- Construcción de los datos para la tabla ---
    final List<List<String>> dataTable = [
      // Encabezados
      ['Nombre ', 'Unidad', 'Precio Unit.', 'Stock Actual', 'Valor Total'],
    ];

    double grandTotalValue = 0; // Variable para el total general

    // Iterar sobre los items para crear las filas y calcular totales
    for (var item in items) {
      final quantity = stockQuantities[item.id] ?? 0;
      final totalPrice = quantity * item.price;
      grandTotalValue += totalPrice; // Sumar al total general

      dataTable.add([
        item.name,
        item.unit,
        currencyFormat.format(item.price),
        quantity.toString(),
        currencyFormat.format(totalPrice),
      ]);
    }
    // --- Fin Construcción de Datos ---

    // Añadir una página al documento PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) { /* ... Header ... */
           return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
              padding: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
              decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey))),
              child: pw.Text('Reporte de Inventario - $locationName',
                  style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey))
            );
        },
        footer: (pw.Context context) { /* ... Footer ... */
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey)
            )
          );
        },
        build: (pw.Context context) {
          return <pw.Widget>[
            // Título Principal
            pw.Header(
              level: 0,
              child: pw.Row( /* ... Título y Fecha ... */
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Reporte de Inventario - $locationName', textScaleFactor: 1.5, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                ]
              ),
            ),
            pw.SizedBox(height: 20),

            // Tabla de Inventario
            pw.Table.fromTextArray(
              headers: dataTable.first,
              data: dataTable.sublist(1),
              border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: { 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight },
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              columnWidths: { 0: const pw.FlexColumnWidth(3.0), 1: const pw.FlexColumnWidth(1.0), 2: const pw.FlexColumnWidth(1.5), 3: const pw.FlexColumnWidth(1.0), 4: const pw.FlexColumnWidth(1.8) }
            ),

            pw.SizedBox(height: 30), // Espacio antes del total

            // --- Total General del Inventario (DESCOMENTADO Y FORMATEADO) ---
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container( // Contenedor para darle estilo
                 padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: pw.BoxDecoration(
                   border: pw.Border.all(color: PdfColors.black, width: 0.5),
                   color: PdfColors.grey200, // Fondo sutil para el total
                 ),
                 child: pw.Text(
                  // Usar el formateador para mostrar el total general
                  'Valor Total General: ${currencyFormat.format(grandTotalValue)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
              )
            ),
            // --------------------------------------------------------------
          ];
        },
      ),
    ); // Fin de addPage

    // Guardar y devolver los bytes del PDF
    print("PdfService: PDF generado, guardando bytes...");
    return pdf.save();
  }

} // Fin de la clase PdfService

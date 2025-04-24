import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear moneda
import '../../../data/models/item.dart';

class ItemListTile extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  // final int? currentStock; // Stock se muestra en el diálogo por ahora

  const ItemListTile({
    super.key,
    required this.item,
    this.onTap,
    // this.currentStock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Formateador de moneda
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final formattedPrice = currencyFormat.format(item.price);

    return Card( // Usar el CardTheme definido en app_theme.dart
      // Quitar margen si se usa el del CardTheme
      // margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      clipBehavior: Clip.antiAlias, // Para que el InkWell funcione bien con el shape
      child: InkWell( // Añadir InkWell para efecto ripple al tocar
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // --- Icono Temático ---
              CircleAvatar(
                 backgroundColor: colorScheme.secondaryContainer, // Usar color de acento claro
                 foregroundColor: colorScheme.onSecondaryContainer,
                 child: const Icon(Icons.local_dining_outlined, size: 20), // Icono genérico de comida/restaurante
                 // O usar la inicial si prefieres:
                 // child: Text(item.name.isNotEmpty ? item.name[0].toUpperCase() : '?'),
               ),
              // --------------------
              const SizedBox(width: 16.0),
              // --- Columna de Texto ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del Item (más prominente)
                    Text(
                      item.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    // Unidad y Precio (secundario)
                    Text(
                      '${item.unit}  |  $formattedPrice',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                     // Mostrar descripción si existe (más sutil)
                     if (item.description != null && item.description!.isNotEmpty)
                       Padding(
                         padding: const EdgeInsets.only(top: 4.0),
                         child: Text(
                           item.description!,
                           style: theme.textTheme.bodySmall?.copyWith(
                             color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                           ),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                  ],
                ),
              ),
              // ----------------------
              // --- Opcional: Stock (si decidieras mostrarlo aquí) ---
              // const SizedBox(width: 16.0),
              // Text(
              //   'Stock: ${currentStock ?? '-'}',
              //   style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              // ),
              // -----------------------------------------------------
               // --- Icono de Chevron para indicar accionable ---
               Icon(
                 Icons.chevron_right,
                 color: colorScheme.onSurfaceVariant.withOpacity(0.5),
               ),
               // --------------------------------------------
            ],
          ),
        ),
      ),
    );
  }
}


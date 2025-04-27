import 'dart:async';
import 'dart:typed_data'; // Required for Uint8List (PDF bytes)
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart'; // Import printing package
import 'package:pdf/pdf.dart'; // Import PDF page format
// Import your data models
import '../../data/models/item.dart';
import '../../data/models/stock_level.dart';
// Import your repository
import '../../data/repositories/inventory_repository.dart';
// Import the PDF service
import '../../core/services/pdf_service.dart'; // <-- IMPORTAR PdfService (Asegúrate que exista)

// Manages the state related to inventory items and their stock levels
class InventoryProvider extends ChangeNotifier {
  // Dependency on the repository to fetch/modify data
  final InventoryRepository _repository;
  // --- Instance of PdfService ---
  // You could also inject this via the constructor if preferred
  final PdfService _pdfService = PdfService();
  // -----------------------------
  // Subscription to listen for real-time updates to the items list
  StreamSubscription? _itemsSubscription;

  // --- State Variables ---
  List<Item> _items = [];
  bool _isLoadingItems = false; // Loading state for the item list
  String? _errorMessage; // General error message

  // State for fetching single item stock (for details pop-up)
  StockLevel? _selectedItemStock;
  bool _isLoadingStock = false;
  String? _errorFetchingStock;

  // --- NEW: State for PDF generation ---
  bool _isGeneratingPdf = false; // Indicates if PDF generation is in progress
  String? _pdfError; // Holds errors specific to PDF generation
  // ------------------------------------

  // --- Public Getters ---
  List<Item> get items => _items;
  bool get isLoadingItems => _isLoadingItems;
  String? get errorMessage => _errorMessage;
  StockLevel? get selectedItemStock => _selectedItemStock;
  bool get isLoadingStock => _isLoadingStock;
  String? get errorFetchingStock => _errorFetchingStock;
  // --- NEW: Getters for PDF state ---
  bool get isGeneratingPdf => _isGeneratingPdf; // Getter for PDF generation state
  String? get pdfError => _pdfError; // Getter for PDF generation errors
  // ---------------------------------

  // Constructor
  InventoryProvider(this._repository) {
    print("InventoryProvider initialized. Fetching items...");
    fetchItems();
  }

  // Fetches the list of items
  void fetchItems() {
    _isLoadingItems = true;
    _errorMessage = null;
    notifyListeners();

    _itemsSubscription?.cancel();
    // Ensure InventoryRepository has getItemsStream()
    _itemsSubscription = _repository.getItemsStream().listen(
      (itemsData) {
        _items = itemsData;
        _isLoadingItems = false;
        print("InventoryProvider: Received ${itemsData.length} items.");
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = "Error loading items: ${error.toString()}";
        print("InventoryProvider ERROR fetching items: $_errorMessage");
        _isLoadingItems = false;
        _items = [];
        notifyListeners();
      },
    );
  }

  // Adds a new item
  Future<void> addItem({
    required String name, required String unit, String? description,
    required double price, required int initialStock,
  }) async {
    _errorMessage = null;
    try {
      // Ensure InventoryRepository has checkItemExistsByName() and addItem()
      bool exists = await _repository.checkItemExistsByName(name);
      if (exists) {
        _errorMessage = "An item with the name '$name' already exists.";
        notifyListeners();
        throw Exception(_errorMessage);
      }
      await _repository.addItem(
        name: name, unit: unit, description: description,
        price: price, initialStock: initialStock,
      );
       print("InventoryProvider: Item '$name' added successfully.");
    } catch (e) {
      if (_errorMessage == null) _errorMessage = "Error adding item: ${e.toString()}";
      print("InventoryProvider: Final error in addItem: $_errorMessage");
      notifyListeners();
      throw e;
    }
  }

  // Adds stock to an existing item
  Future<void> addStock({
    required String itemId, required String locationId, required int quantityReceived,
  }) async {
    _errorMessage = null;
    try {
      // Ensure InventoryRepository has addStock()
      await _repository.addStock(
        itemId: itemId, locationId: locationId, quantityReceived: quantityReceived,
      );
      print("InventoryProvider: addStock call completed for item $itemId at $locationId.");
      // Optionally refresh details if pop-up is open
      if (_selectedItemStock?.itemId == itemId && _selectedItemStock?.locationId == locationId) {
         await fetchStockForItem(itemId, locationId);
      }
    } catch (e) {
       _errorMessage = "Error adding stock: ${e.toString()}";
       print("InventoryProvider ERROR adding stock: $_errorMessage");
       notifyListeners();
       throw e;
    }
  }

  // Fetches stock details for one item (for pop-up)
  Future<void> fetchStockForItem(String itemId, String locationId) async {
    print("--- fetchStockForItem START ---");
    print("Fetching stock for Item ID: $itemId at Location ID: $locationId");
    _isLoadingStock = true;
    _errorFetchingStock = null;
    _selectedItemStock = null;
    notifyListeners();
    try {
      // Ensure InventoryRepository has getStockLevel()
      _selectedItemStock = await _repository.getStockLevel(itemId, locationId);
      if (_selectedItemStock != null) print("InventoryProvider: Stock found: Qty=${_selectedItemStock!.quantity}");
      else print("InventoryProvider: Stock NOT found for $itemId at $locationId.");
    } catch (e) {
      print("InventoryProvider ERROR fetching stock for $itemId: $e");
      _errorFetchingStock = "Error getting stock: ${e.toString()}";
    } finally {
      _isLoadingStock = false;
      print("--- fetchStockForItem END (isLoadingStock: $_isLoadingStock) ---");
      notifyListeners();
    }
  }

  // Deletes an item (if stock is zero)
  Future<void> deleteItem(String itemId, String mainLocationId) async {
    _errorMessage = null;
    try {
      // Ensure InventoryRepository has deleteItem()
      await _repository.deleteItem(itemId, mainLocationId);
      print("InventoryProvider: deleteItem call completed for $itemId.");
    } catch (e) {
      print("InventoryProvider ERROR in deleteItem: $e");
      if (e.toString().contains("No se puede eliminar un item con stock")) {
         print("InventoryProvider: Specific stock error detected.");
      } else {
        _errorMessage = "Error deleting item: ${e.toString()}";
        notifyListeners();
      }
      throw e;
    }
  }

  // --- NEW: Method to generate and show Inventory PDF ---
  Future<void> generateAndShowInventoryPdf(String locationId, String locationName) async {
    _isGeneratingPdf = true; // Set PDF loading state
    _pdfError = null; // Clear previous PDF errors
    notifyListeners(); // Notify UI about PDF generation start

    try {
      print("InventoryProvider: Starting PDF generation for $locationName (ID: $locationId)");
      // 1. Get the current list of items (already available in _items)
      final currentItems = List<Item>.from(_items); // Use a copy

      // 2. Fetch all current stock levels for the specified location
      print("InventoryProvider: Fetching all stock levels for $locationId...");
      // Ensure InventoryRepository has getStockLevelsForLocation()
      final stockQuantities = await _repository.getStockLevelsForLocation(locationId);
      print("InventoryProvider: Fetched ${stockQuantities.length} stock records.");

      // 3. Call the PdfService to generate the PDF bytes
      print("InventoryProvider: Generating PDF bytes...");
      // Ensure PdfService and generateInventoryPdf exist and work
      final Uint8List pdfBytes = await _pdfService.generateInventoryPdf(
        currentItems,
        stockQuantities, // Pass the map of stocks
        locationName, // Pass the location name for the title
      );
      print("InventoryProvider: PDF bytes generated (${pdfBytes.lengthInBytes} bytes).");

      // 4. Use the 'printing' package to display the PDF preview
      print("InventoryProvider: Displaying PDF preview...");
      // Generate a filename suggestion
      final fileName = 'inventario_${locationName.replaceAll(' ', '_')}_${DateTime.now().toIso8601String()}.pdf';
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes, // Provide the generated bytes
          name: fileName // Suggest a filename
      );
      print("InventoryProvider: PDF preview closed.");
      _pdfError = null; // Clear error on success

    } catch (e) {
      // Handle errors during PDF generation or data fetching
      print("InventoryProvider ERROR generating PDF: $e");
      _pdfError = "Error generating PDF report: ${e.toString()}";
      // Notify listeners about the error so the UI can potentially show it
      notifyListeners();
      // Optional: Re-throw if you want the UI button's catch block to handle it too
      // throw e;
    } finally {
      // Ensure PDF loading state is turned off
      _isGeneratingPdf = false;
      notifyListeners(); // Notify UI that PDF generation finished
    }
  }
  // --- FIN NUEVO MÉTODO ---


  // Clean up subscription when the provider is disposed
  @override
  void dispose() {
    print("InventoryProvider disposed. Cancelling subscription.");
    _itemsSubscription?.cancel();
    super.dispose();
  }
}

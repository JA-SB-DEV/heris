import 'dart:async'; // Required for StreamSubscription
import 'package:flutter/foundation.dart'; // Required for ChangeNotifier
import '../../data/models/location.dart'; // Import the Location model
import '../../data/repositories/inventory_repository.dart'; // Import the repository interface

// Manages the state related to business locations (warehouses, stores)
class LocationProvider extends ChangeNotifier {
  // The repository dependency to interact with data sources
  final InventoryRepository _repository;
  // Subscription to listen for real-time updates from the locations stream
  StreamSubscription? _locationsSubscription;

  // --- State Variables ---
  // Holds the list of all locations fetched from the repository
  List<Location> _locations = [];
  // Holds the specific location marked as the main warehouse
  Location? _mainWarehouse;
  // Indicates if the initial list of locations is being loaded
  bool _isLoading = false;
  // Holds any error message that occurred during fetching or saving
  String? _errorMessage;
  // Indicates if a save operation (like adding a location) is in progress
  bool _isSaving = false;
  // ---------------------

  // --- Public Getters ---
  // Provides read-only access to the list of all locations
  List<Location> get allLocations => _locations;
  // Provides a filtered list containing only destination locations (not the main warehouse)
  List<Location> get destinationLocations => _locations.where((loc) => !loc.isMainWarehouse).toList();
  // Provides read-only access to the main warehouse location (can be null)
  Location? get mainWarehouse => _mainWarehouse;
  // Provides read-only access to the loading state for the initial fetch
  bool get isLoading => _isLoading;
  // Provides read-only access to the current error message
  String? get errorMessage => _errorMessage;
  // Provides read-only access to the saving state
  bool get isSaving => _isSaving;
  // --------------------

  // Constructor: Takes the repository and immediately starts fetching locations
  LocationProvider(this._repository) {
    print("LocationProvider initialized. Fetching locations...");
    fetchLocations(); // Load locations when the provider is created
  }

  // Fetches the list of locations from the repository and listens for updates
  void fetchLocations() {
    _isLoading = true; // Set loading state to true
    _errorMessage = null; // Clear previous errors
    notifyListeners(); // Notify UI about the loading state

    // Cancel any previous subscription to avoid memory leaks
    _locationsSubscription?.cancel();
    // Listen to the stream provided by the repository
    // Ensure InventoryRepository has getLocationsStream() defined
    _locationsSubscription = _repository.getLocationsStream().listen(
      (locationsData) {
        // Successfully received data
        _locations = locationsData; // Update the local list
        print("LocationProvider: Received ${locationsData.length} locations.");

        // Attempt to find the main warehouse within the fetched data
        Location? foundWarehouse;
        try {
          // Use firstWhere to find the location marked as main warehouse
          foundWarehouse = _locations.firstWhere((loc) => loc.isMainWarehouse);
          print("LocationProvider: Main warehouse found: ${foundWarehouse.name}");
        } on StateError {
          // Handle the case where no main warehouse is found
          foundWarehouse = null;
          print("LocationProvider WARNING: No location marked as Main Warehouse found.");
        } catch (e) {
          // Catch any other potential errors during the search
          print("LocationProvider ERROR processing locations: $e");
          foundWarehouse = null;
        }
        _mainWarehouse = foundWarehouse; // Assign the result (could be null)

        _isLoading = false; // Set loading state to false
        _errorMessage = null; // Clear error message on success
        notifyListeners(); // Notify UI with the updated data
      },
      onError: (error) {
        // Handle errors from the stream
        _errorMessage = "Error loading locations: ${error.toString()}";
        print("LocationProvider ERROR fetching locations: $_errorMessage");
        _isLoading = false; // Set loading state to false
        _locations = []; // Clear locations list on error
        _mainWarehouse = null; // Clear main warehouse on error
        notifyListeners(); // Notify UI about the error
      },
    );
  }

  // Adds a new location via the repository
  Future<void> addLocation({
    required String name,
    String? address,
    required bool isMainWarehouse,
  }) async {
    _isSaving = true; // Set saving state to true
    _errorMessage = null; // Clear previous errors
    notifyListeners(); // Notify UI that saving has started

    try {
      // --- Important Validation ---
      // Check if trying to add a new main warehouse when one already exists
      if (isMainWarehouse && _mainWarehouse != null) {
         // Throw a specific error if a main warehouse already exists
         throw Exception("A Main Warehouse (${_mainWarehouse!.name}) already exists. Only one is allowed.");
      }
      // ---------------------------

      // Call the repository method to add the location
      // Ensure InventoryRepository has addLocation() defined
      await _repository.addLocation(
        name: name,
        address: address,
        isMainWarehouse: isMainWarehouse,
      );
      // If successful, the stream listener in fetchLocations should automatically
      // update the list. No need to manually call fetchLocations or update state here.
      print("LocationProvider: addLocation call completed successfully for '$name'.");

    } catch (e) {
      // Catch any error (including the validation error above)
      _errorMessage = "Error saving location: ${e.toString()}";
      print("LocationProvider ERROR saving location: $_errorMessage");
      notifyListeners(); // Notify UI about the error
      throw e; // Re-throw the error so the UI (e.g., SnackBar) can handle it
    } finally {
      // Ensure saving state is turned off regardless of success or failure
      _isSaving = false;
      notifyListeners(); // Notify UI that saving has finished
    }
  }

  // Override dispose to cancel the stream subscription when the provider is removed
  @override
  void dispose() {
    print("LocationProvider disposed. Cancelling subscription.");
    _locationsSubscription?.cancel(); // Cancel the stream subscription
    super.dispose(); // Call the parent dispose method
  }
}

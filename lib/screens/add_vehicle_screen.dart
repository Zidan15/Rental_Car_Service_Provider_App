import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/models/location.dart';
import 'package:fleetwise/services/vehicle_service.dart';
import 'package:fleetwise/services/location_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddVehicleScreen extends StatefulWidget {
  final Vehicle? vehicleToEdit; // Optional: pass existing vehicle for edit mode

  const AddVehicleScreen({super.key, this.vehicleToEdit});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _fuelTypeController = TextEditingController();
  final _transmissionController = TextEditingController();
  final _colorController = TextEditingController();
  final _categoryController = TextEditingController();
  final _plateController = TextEditingController();
  final _priceController = TextEditingController();
  
  final _vehicleService = VehicleService();
  final _locationService = LocationService();
  bool _isLoading = false;
  bool _isListed = true;
  
  List<ProviderLocation> _locations = [];
  String? _selectedLocationId;
  bool _locationsLoading = true;

  // Track if we're in edit mode
  bool get _isEditMode => widget.vehicleToEdit != null;

  // Store initial dropdown values for pre-selection
  String? _selectedBrand;
  String? _selectedFuelType;
  String? _selectedTransmission;
  String? _selectedColor;
  String? _selectedCategory;

  // --- Photo picker state ---
  // Picked image bytes (for display & upload)
  final List<Uint8List> _pickedImageBytes = [];
  // Names for each picked file
  final List<String> _pickedImageNames = [];
  // Existing image URL from DB (edit mode)
  String? _existingImageUrl;
  bool _isUploadingPhotos = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing
    if (_isEditMode) {
      final v = widget.vehicleToEdit!;
      _brandController.text = v.brand;
      _modelController.text = v.model;
      _yearController.text = v.year.toString();
      _fuelTypeController.text = v.fuelType;
      _transmissionController.text = v.transmission;
      _colorController.text = v.color;
      _categoryController.text = v.category ?? '';
      _plateController.text = v.plateNumber;
      _priceController.text = v.pricePerDay > 0 ? v.pricePerDay.toString() : '';
      _isListed = v.isListed;

      // Set dropdown selections
      _selectedBrand = v.brand;
      _selectedFuelType = v.fuelType;
      _selectedTransmission = v.transmission;
      _selectedColor = v.color;
      _selectedCategory = v.category;
      _selectedLocationId = v.locationId;
      _existingImageUrl = v.imageUrl;
    }
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locations = await _locationService.getLocations();
    if (mounted) {
      setState(() {
        _locations = locations;
        _locationsLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _fuelTypeController.dispose();
    _transmissionController.dispose();
    _colorController.dispose();
    _categoryController.dispose();
    _plateController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // 1. Upload any newly picked photos to Supabase Storage
        String? uploadedImageUrl = _existingImageUrl;
        if (_pickedImageBytes.isNotEmpty) {
          setState(() => _isUploadingPhotos = true);
          final supabase = Supabase.instance.client;
          final userId = supabase.auth.currentUser!.id;
          // Upload the first image (primary photo)
          final bytes = _pickedImageBytes[0];
          final fileName = _pickedImageNames[0];
          final ext = fileName.split('.').last.toLowerCase();
          final storagePath = '$userId/${const Uuid().v4()}.$ext';

          await supabase.storage
              .from('vehicle-images')
              .uploadBinary(
                storagePath,
                bytes,
                fileOptions: FileOptions(
                  contentType: 'image/$ext',
                  upsert: true,
                ),
              );

          uploadedImageUrl = supabase.storage
              .from('vehicle-images')
              .getPublicUrl(storagePath);
          setState(() => _isUploadingPhotos = false);
        }

        final priceText = _priceController.text.trim();
        final price = priceText.isEmpty ? 0.0 : double.parse(priceText);

        final vehicle = Vehicle(
          id: _isEditMode ? widget.vehicleToEdit!.id : const Uuid().v4(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          year: int.parse(_yearController.text.trim()),
          fuelType: _fuelTypeController.text.trim(),
          transmission: _transmissionController.text.trim(),
          color: _colorController.text.trim(),
          plateNumber: _plateController.text.trim(),
          category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
          pricePerDay: price,
          isListed: _isListed,
          locationId: _selectedLocationId,
          status: VehicleStatus.healthy,
          lastReading: DateTime.now(),
          alcoholLevel: 'Sober',

          engineTemp: 0.0,
          speed: 0.0,
          latitude: 0.0,
          longitude: 0.0,
          imageUrl: uploadedImageUrl,
        );

        if (_isEditMode) {
          await _vehicleService.updateVehicle(vehicle);
        } else {
          await _vehicleService.addVehicle(vehicle);
        }

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Vehicle updated successfully!' : 'Vehicle added successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        if (_isEditMode) {
          // Return true to indicate successful update
          Navigator.of(context).pop(true);
        } else {
          // Reset form for add mode
          _formKey.currentState!.reset();
          _brandController.clear();
          _modelController.clear();
          _yearController.clear();
          _fuelTypeController.clear();
          _transmissionController.clear();
          _colorController.clear();
          _categoryController.clear();
          _plateController.clear();
          _priceController.clear();
          setState(() {
            _selectedBrand = null;
            _selectedFuelType = null;
            _selectedTransmission = null;
            _selectedColor = null;
            _selectedCategory = null;
            _selectedLocationId = null;
            _isListed = true;
            _pickedImageBytes.clear();
            _pickedImageNames.clear();
            _existingImageUrl = null;
          });
        }

      } on StorageException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo upload failed: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } on PostgrestException catch (e) {
        if (!mounted) return;
        String errorMessage = 'Error ${_isEditMode ? 'updating' : 'adding'} vehicle: ${e.message}';
        if (e.code == '23505') {
          errorMessage = 'A vehicle with this license plate already exists.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
             content: Text(errorMessage),
             backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${_isEditMode ? 'updating' : 'adding'} vehicle: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dropdown Lists
    final brands = ['Toyota', 'Honda', 'Suzuki', 'Hyundai', 'Tata', 'Mahindra', 'Kia', 'BMW', 'Mercedes', 'Audi', 'Other'];
    final fuelTypes = ['Petrol', 'Diesel', 'Electric', 'Hybrid', 'CNG'];
    final transmissions = ['Automatic', 'Manual'];
    final colors = ['White', 'Black', 'Silver', 'Grey', 'Red', 'Blue', 'Green', 'Yellow', 'Other'];
    final categories = ['Hatchback', 'Sedan', 'SUV'];

    // If in edit mode and value isn't in the list, add it
    if (_isEditMode) {
      if (_selectedBrand != null && !brands.contains(_selectedBrand)) {
        brands.add(_selectedBrand!);
      }
      if (_selectedColor != null && !colors.contains(_selectedColor)) {
        colors.add(_selectedColor!);
      }
      if (_selectedCategory != null && !categories.contains(_selectedCategory)) {
        categories.add(_selectedCategory!);
      }
    }

    return _isEditMode
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Edit Vehicle'),
            ),
            body: _buildForm(theme, brands, fuelTypes, transmissions, colors, categories),
          )
        : _buildForm(theme, brands, fuelTypes, transmissions, colors, categories);
  }

  Widget _buildForm(ThemeData theme, List<String> brands, List<String> fuelTypes, 
                    List<String> transmissions, List<String> colors, List<String> categories) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _isEditMode ? 'Edit Vehicle Information' : 'Vehicle Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // BRAND DROPDOWN
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Brand',
              prefixIcon: Icon(Icons.business),
            ),
            value: _selectedBrand,
            items: brands.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedBrand = val;
              });
              _brandController.text = val ?? '';
            },
            validator: (value) => _brandController.text.isEmpty ? 'Please select brand' : null,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Model',
              hintText: 'e.g., Corolla',
              prefixIcon: Icon(Icons.directions_car),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Please enter model' : null,
          ),
          const SizedBox(height: 16),
          
          // CATEGORY DROPDOWN
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category),
            ),
            value: _selectedCategory,
            items: categories.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedCategory = val;
              });
              _categoryController.text = val ?? '';
            },
            validator: (value) => _categoryController.text.isEmpty ? 'Please select category' : null,
          ),
          const SizedBox(height: 16),

          // LOCATION DROPDOWN
          _locationsLoading
              ? const LinearProgressIndicator()
              : _locations.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 8),
                          Expanded(child: Text('No locations. Add in Profile > Manage Locations.')),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Location',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      isExpanded: true, // Prevents overflow by expanding to fill available width
                      value: _selectedLocationId,
                      items: _locations.map((loc) => DropdownMenuItem(
                        value: loc.id, 
                        child: Text(
                          loc.name,
                          overflow: TextOverflow.ellipsis, // Truncate long names
                        ),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedLocationId = val),
                    ),
          const SizedBox(height: 16),

          // PRICE PER DAY
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Price per Day (₹)',
              hintText: 'e.g., 1500',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final price = double.tryParse(value);
                if (price == null || price < 0) {
                  return 'Please enter a valid price';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _yearController,
            decoration: const InputDecoration(
              labelText: 'Year',
              hintText: 'e.g., 2023',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter year';
              final year = int.tryParse(value);
              if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                return 'Please enter a valid year';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // FUEL TYPE DROPDOWN
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Fuel Type',
              prefixIcon: Icon(Icons.local_gas_station),
            ),
            value: _selectedFuelType,
            items: fuelTypes.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedFuelType = val;
              });
              _fuelTypeController.text = val ?? '';
            },
            validator: (value) => _fuelTypeController.text.isEmpty ? 'Please select fuel type' : null,
          ),
          
          const SizedBox(height: 16),
          
          // TRANSMISSION DROPDOWN
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Transmission',
              prefixIcon: Icon(Icons.settings_outlined),
            ),
            value: _selectedTransmission,
            items: transmissions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedTransmission = val;
              });
              _transmissionController.text = val ?? '';
            },
            validator: (value) => _transmissionController.text.isEmpty ? 'Please select transmission' : null,
          ),
          
          const SizedBox(height: 16),
          
          // COLOR DROPDOWN
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Color',
              prefixIcon: Icon(Icons.palette),
            ),
            value: _selectedColor,
            items: colors.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedColor = val;
              });
              _colorController.text = val ?? '';
            },
            validator: (value) => _colorController.text.isEmpty ? 'Please select color' : null,
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _plateController,
            decoration: const InputDecoration(
              labelText: 'Plate Number',
              hintText: 'e.g., GA-01-AB-1234',
              prefixIcon: Icon(Icons.badge),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Please enter plate number' : null,
          ),
          
          const SizedBox(height: 24),

          // LIST FOR RENT TOGGLE
          SwitchListTile(
            title: const Text('List this vehicle for rent'),
            subtitle: Text(_isListed ? 'Visible to renters' : 'Hidden from renters'),
            value: _isListed,
            onChanged: (val) {
              setState(() {
                _isListed = val;
              });
            },
            secondary: Icon(
              _isListed ? Icons.visibility : Icons.visibility_off,
              color: _isListed ? Colors.green : Colors.grey,
            ),
          ),

          // --- PHOTO PICKER ---
          _buildPhotoPicker(theme),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditMode ? 'Update Vehicle' : 'Submit'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }


  // ----------------------------------------------------------------
  // PHOTO PICKER WIDGET
  // ----------------------------------------------------------------
  Widget _buildPhotoPicker(ThemeData theme) {
    final hasImages = _existingImageUrl != null || _pickedImageBytes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Thumbnail grid
        if (hasImages)
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Show existing DB image (edit mode)
                if (_existingImageUrl != null && _pickedImageBytes.isEmpty)
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(_existingImageUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _existingImageUrl = null),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(153),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                // Show newly picked images
                ..._pickedImageBytes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final bytes = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: MemoryImage(bytes),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _pickedImageBytes.removeAt(idx);
                            _pickedImageNames.removeAt(idx);
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(153),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                      if (idx == 0)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(204),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        if (hasImages) const SizedBox(height: 8),

        // Add Photos button
        OutlinedButton.icon(
          onPressed: _isUploadingPhotos ? null : _pickImages,
          icon: _isUploadingPhotos
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_photo_alternate_outlined),
          label: Text(_isUploadingPhotos
              ? 'Uploading...'
              : hasImages
                  ? 'Add More Photos'
                  : 'Add Photos'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        if (_pickedImageBytes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${_pickedImageBytes.length} photo${_pickedImageBytes.length > 1 ? 's' : ''} selected • First photo is the cover',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
            ),
          ),
      ],
    );
  }

  // Pick images using image_picker
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;

    for (final xFile in picked) {
      final bytes = await xFile.readAsBytes();
      if (mounted) {
        setState(() {
          _pickedImageBytes.add(bytes);
          _pickedImageNames.add(xFile.name);
        });
      }
    }
  }
}

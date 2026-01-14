import 'package:flutter/material.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/services/vehicle_service.dart';
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
  bool _isLoading = false;
  bool _isListed = true; // Default to listed

  // Track if we're in edit mode
  bool get _isEditMode => widget.vehicleToEdit != null;

  // Store initial dropdown values for pre-selection
  String? _selectedBrand;
  String? _selectedFuelType;
  String? _selectedTransmission;
  String? _selectedColor;
  String? _selectedCategory;

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
      setState(() {
        _isLoading = true;
      });

      try {
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
          status: VehicleStatus.healthy,
          lastReading: DateTime.now(),
          alcoholLevel: 0.0,
          engineTemp: 0.0,
          speed: 0.0,
          latitude: 0.0,
          longitude: 0.0,
          imageUrl: _isEditMode ? widget.vehicleToEdit!.imageUrl : null,
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
            _isListed = true;
          });
        }

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
    final categories = ['Hatchback', 'Sedan', 'Compact SUV', 'Full-Size SUV', 'MUV/7-Seater', 'Luxury/Premium', 'Convertible/Open-Top'];

    // If in edit mode and value isn't in the list, add it
    if (_isEditMode) {
      if (_selectedBrand != null && !brands.contains(_selectedBrand)) {
        brands.add(_selectedBrand!);
      }
      if (_selectedColor != null && !colors.contains(_selectedColor)) {
        colors.add(_selectedColor!);
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

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo picker (mock only)')),
              );
            },
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add Photos'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading 
              ? const SizedBox(
                  height: 20, 
                  width: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              : Text(_isEditMode ? 'Update Vehicle' : 'Submit'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
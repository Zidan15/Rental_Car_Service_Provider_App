import 'package:flutter/material.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/services/vehicle_service.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

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
  final _plateController = TextEditingController();
  
  final _vehicleService = VehicleService();
  bool _isLoading = false;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _fuelTypeController.dispose();
    _transmissionController.dispose();
    _colorController.dispose();
    _plateController.dispose();
  
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create a new Vehicle object
        // Note: We generate a temporary ID here, but Supabase might handle it if we omitted it.
        // However, the Vehicle model requires an ID. 
        // Ideally, we should let the DB generate it, but for now we'll generate a UUID.
        final newVehicle = Vehicle(
          id: const Uuid().v4(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          year: int.parse(_yearController.text.trim()),
          fuelType: _fuelTypeController.text.trim(),
          transmission: _transmissionController.text.trim(),
          color: _colorController.text.trim(),
          plateNumber: _plateController.text.trim(),
          status: VehicleStatus.healthy, // Default status
          lastReading: DateTime.now(),
          alcoholLevel: 0.0,
          engineTemp: 0.0,
          speed: 0.0,
          latitude: 0.0,
          longitude: 0.0,
          imageUrl: null, // Placeholder for now
        );

        await _vehicleService.addVehicle(newVehicle);

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Reset form
        _formKey.currentState!.reset();
        _brandController.clear();
        _modelController.clear();
        _yearController.clear();
        _fuelTypeController.clear();
        _transmissionController.clear();
        _colorController.clear();
        _plateController.clear();

      } on PostgrestException catch (e) {
        if (!mounted) return;
        String errorMessage = 'Error adding vehicle: ${e.message}';
        
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
            content: Text('Error adding vehicle: ${e.toString()}'),
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
  // 💥 NO Scaffold here. Returns only the content.
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Vehicle Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _brandController,
            decoration: const InputDecoration(
              labelText: 'Brand',
              hintText: 'e.g., Toyota',
              prefixIcon: Icon(Icons.business),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter brand';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Model',
              hintText: 'e.g., Corolla',
              prefixIcon: Icon(Icons.directions_car),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter model';
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
              if (value == null || value.isEmpty) {
                return 'Please enter year';
              }
              final year = int.tryParse(value);
              if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                return 'Please enter a valid year';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fuelTypeController,
            decoration: const InputDecoration(
              labelText: 'Fuel Type',
              hintText: 'e.g., Petrol, Diesel, Electric',
              prefixIcon: Icon(Icons.local_gas_station),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter fuel type';
              }
              return null;
            },
          ),
          
          // ✅ NEW TRANSMISSION FIELD
          const SizedBox(height: 16),
          TextFormField(
            controller: _transmissionController,
            decoration: const InputDecoration(
              labelText: 'Transmission',
              hintText: 'e.g., Automatic, Manual',
              prefixIcon: Icon(Icons.settings_outlined), // Common icon for transmission
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter transmission type';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          TextFormField(
            controller: _colorController,
            decoration: const InputDecoration(
              labelText: 'Color',
              hintText: 'e.g., White, Black, Silver',
              prefixIcon: Icon(Icons.palette),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter color';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _plateController,
            decoration: const InputDecoration(
              labelText: 'Plate Number',
              hintText: 'e.g., GA-01-AB-1234',
              prefixIcon: Icon(Icons.badge),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter plate number';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
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
              : const Text('Submit'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
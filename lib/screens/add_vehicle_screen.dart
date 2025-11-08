import 'package:flutter/material.dart';

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
  final _colorController = TextEditingController();
  final _plateController = TextEditingController();
 

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _fuelTypeController.dispose();
    _colorController.dispose();
    _plateController.dispose();
  
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle added successfully (mock only)'),
          duration: Duration(seconds: 2),
        ),
      );
      _formKey.currentState!.reset();
      _brandController.clear();
      _modelController.clear();
      _yearController.clear();
      _fuelTypeController.clear();
      _colorController.clear();
      _plateController.clear();
     
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADD VEHICLE'),
      ),
      body: Form(
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
              onPressed: _submitForm,
              child: const Text('Submit'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

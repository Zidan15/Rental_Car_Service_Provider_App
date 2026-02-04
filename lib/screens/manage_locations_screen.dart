// lib/screens/manage_locations_screen.dart
import 'package:flutter/material.dart';
import 'package:fleetwise/models/location.dart';
import 'package:fleetwise/services/location_service.dart';
import 'package:fleetwise/screens/add_location_screen.dart';

class ManageLocationsScreen extends StatefulWidget {
  const ManageLocationsScreen({super.key});

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  final LocationService _locationService = LocationService();
  List<ProviderLocation> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    final locations = await _locationService.getLocations();
    if (mounted) {
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLocation(ProviderLocation location) async {
    // 1. Check if location is in use
    final usageCount = await _locationService.getLocationUsageCount(location.id);
    
    // 2. Prepare dialog content based on usage
    final String title = 'Delete Location';
    final String content = usageCount > 0 
        ? '⚠️ Warning: This location is currently assigned to $usageCount vehicle(s).\n\nDeleting it will remove the location from these vehicles. Continue?'
        : 'Are you sure you want to delete "${location.name}"?';

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _locationService.deleteLocation(location.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'), backgroundColor: Colors.green));
        _loadLocations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _navigateToAddLocation() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddLocationScreen()),
    );
    if (result == true) _loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MANAGE LOCATIONS', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddLocation,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off, size: 64, color: theme.colorScheme.secondary.withAlpha(128)),
                      const SizedBox(height: 16),
                      Text('No locations yet', style: theme.textTheme.titleMedium),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLocations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _locations.length,
                    itemBuilder: (context, index) {
                      final loc = _locations[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: theme.colorScheme.primary),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(loc.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  if (loc.address != null)
                                    Text(loc.address!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _deleteLocation(loc),
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red.withAlpha(180),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

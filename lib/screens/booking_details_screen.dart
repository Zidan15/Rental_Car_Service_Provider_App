// lib/screens/booking_details_screen.dart
import 'package:flutter/material.dart';
import 'package:fleetwise/models/booking.dart';
import 'package:fleetwise/services/booking_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onStatusChanged;

  const BookingDetailsScreen({
    super.key,
    required this.booking,
    this.onStatusChanged,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final BookingService _bookingService = BookingService();
  late Booking _booking;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Future<void> _updateStatus(String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getDialogTitle(status)),
        content: Text(_getDialogContent(status)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: status == 'confirmed' ? Colors.green : Colors.red,
            ),
            child: Text(_getDialogAction(status)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUpdating = true);

    try {
      await _bookingService.updateBookingStatus(_booking.id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking ${_getStatusLabel(status)}'),
            backgroundColor: status == 'confirmed' ? Colors.green : Colors.orange,
          ),
        );
        widget.onStatusChanged?.call();
        Navigator.pop(context, true); // Return true to indicate change
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDialogTitle(String status) {
    switch (status) {
      case 'confirmed': return 'Accept Booking';
      case 'rejected': return 'Reject Booking';
      case 'cancelled': return 'Cancel Booking';
      case 'completed': return 'Complete Trip';
      default: return 'Update Booking';
    }
  }

  String _getDialogContent(String status) {
    switch (status) {
      case 'confirmed': 
        return 'Accept this booking request from ${_booking.renterName ?? "the renter"}?';
      case 'rejected': 
        return 'Reject this booking request? The renter will be notified.';
      case 'cancelled': 
        return 'Cancel this confirmed booking? The renter will be notified and may expect a refund.';
      case 'completed': 
        return 'Mark this trip as completed? This confirms the vehicle has been returned and will add the earnings to your account.';
      default: 
        return 'Are you sure?';
    }
  }

  String _getDialogAction(String status) {
    switch (status) {
      case 'confirmed': return 'Accept';
      case 'rejected': return 'Reject';
      case 'cancelled': return 'Cancel Booking';
      case 'completed': return 'Complete';
      default: return 'Confirm';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'confirmed': return 'accepted';
      case 'rejected': return 'rejected';
      case 'cancelled': return 'cancelled';
      case 'completed': return 'completed';
      default: return 'updated';
    }
  }

  Future<void> _callRenter() async {
    if (_booking.renterPhone != null) {
      final uri = Uri.parse('tel:${_booking.renterPhone}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('BOOKING DETAILS', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Section
            _SectionCard(
              title: 'Vehicle',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _booking.vehicleName ?? 'Unknown Vehicle',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_booking.vehiclePlate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _booking.vehiclePlate!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Renter Section
            _SectionCard(
              title: 'Renter',
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withAlpha(26),
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _booking.renterName ?? 'Unknown Renter',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_booking.renterPhone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _booking.renterPhone!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_booking.renterPhone != null)
                    IconButton(
                      onPressed: _callRenter,
                      icon: const Icon(Icons.phone),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.withAlpha(26),
                        foregroundColor: Colors.green,
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dates Section
            _SectionCard(
              title: 'Rental Period',
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(_booking.startDate),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(_booking.endDate),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Pickup Location Section with Map
            if (_booking.pickupLocation != null || _booking.pickupLat != null)
              _SectionCard(
                title: 'Pickup Location',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_booking.pickupLocation != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _booking.pickupLocation!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    if (_booking.pickupLat != null && _booking.pickupLng != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 180,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(_booking.pickupLat!, _booking.pickupLng!),
                              initialZoom: 14.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none, // Static map for preview
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.fleetwise',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(_booking.pickupLat!, _booking.pickupLng!),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_on,
                                      size: 40,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 32,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No coordinates available',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            
            if (_booking.pickupLocation != null || _booking.pickupLat != null)
              const SizedBox(height: 16),
            
            // Price & Status Section
            _SectionCard(
              title: 'Payment',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_booking.totalPrice.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  _StatusBadge(status: _booking.status),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            if (_isUpdating)
              const Center(child: CircularProgressIndicator())
            else if (_booking.status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus('rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus('confirmed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ] else if (_booking.status == 'confirmed') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus('cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus('completed'),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Complete Trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange.withAlpha(26);
        textColor = Colors.orange;
        label = 'PENDING';
        break;
      case 'confirmed':
        backgroundColor = Colors.blue.withAlpha(26);
        textColor = Colors.blue;
        label = 'CONFIRMED';
        break;
      case 'completed':
        backgroundColor = Colors.green.withAlpha(26);
        textColor = Colors.green;
        label = 'COMPLETED';
        break;
      case 'cancelled':
        backgroundColor = Colors.grey.withAlpha(26);
        textColor = Colors.grey;
        label = 'CANCELLED';
        break;
      case 'rejected':
        backgroundColor = Colors.red.withAlpha(26);
        textColor = Colors.red;
        label = 'REJECTED';
        break;
      default:
        backgroundColor = Colors.grey.withAlpha(26);
        textColor = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

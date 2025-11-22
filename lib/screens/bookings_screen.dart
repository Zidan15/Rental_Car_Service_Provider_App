import 'package:flutter/material.dart';
import 'package:fleetwise/models/booking.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/models/listing.dart';
import 'package:fleetwise/services/booking_service.dart';
import 'package:fleetwise/services/vehicle_service.dart';
import 'package:fleetwise/services/listing_service.dart';
import 'package:fleetwise/widgets/empty_state.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // TabBar placed directly in the body
        Container(
          color: theme.scaffoldBackgroundColor, // Match background or use primaryColor if preferred
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'REQUESTS'),
              Tab(text: 'MY LISTINGS'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _BookingRequestsTab(),
              _MyListingsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: BOOKING REQUESTS (DEMAND)
// -----------------------------------------------------------------------------
class _BookingRequestsTab extends StatefulWidget {
  const _BookingRequestsTab();

  @override
  State<_BookingRequestsTab> createState() => _BookingRequestsTabState();
}

class _BookingRequestsTabState extends State<_BookingRequestsTab> {
  final _bookingService = BookingService();
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final bookings = await _bookingService.getBookings();
    if (mounted) {
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String bookingId, String status) async {
    try {
      await _bookingService.updateBookingStatus(bookingId, status);
      _loadBookings(); // Reload list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_bookings.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_today_outlined,
        message: 'No bookings yet',
        subtitle: 'Requests from clients will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return _BookingCard(
          booking: booking,
          onAccept: () => _updateStatus(booking.id, 'confirmed'),
          onReject: () => _updateStatus(booking.id, 'rejected'),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BookingCard({
    required this.booking,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = booking.status == 'pending';
    final dateFormat = DateFormat('MMM dd');

    Color statusColor;
    switch (booking.status) {
      case 'confirmed': statusColor = Colors.green; break;
      case 'rejected': statusColor = Colors.red; break;
      case 'completed': statusColor = Colors.blue; break;
      default: statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.vehicleName ?? 'Unknown Vehicle',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Renter: ${booking.renterName ?? 'Unknown'}'),
            const SizedBox(height: 4),
            Text(
              '${dateFormat.format(booking.startDate)} - ${dateFormat.format(booking.endDate)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ₹${booking.totalPrice.toStringAsFixed(0)}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Accept'),
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

// -----------------------------------------------------------------------------
// TAB 2: MY LISTINGS (SUPPLY)
// -----------------------------------------------------------------------------
class _MyListingsTab extends StatefulWidget {
  const _MyListingsTab();

  @override
  State<_MyListingsTab> createState() => _MyListingsTabState();
}

class _MyListingsTabState extends State<_MyListingsTab> {
  final _vehicleService = VehicleService();
  final _listingService = ListingService();
  
  List<Vehicle> _vehicles = [];
  Map<String, Listing?> _listings = {}; // Map vehicleId -> Listing
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // 1. Fetch vehicles
    final vehicles = await _vehicleService.getVehicles();
    
    // 2. Fetch listings for each vehicle
    // Ideally this should be a joined query, but for now we'll fetch individually or loop
    // A better way: fetch all listings for this user. But ListingService is per-vehicle.
    // Let's loop for now (not efficient for 100s of cars, but fine for 10-20).
    Map<String, Listing?> listingsMap = {};
    for (var v in vehicles) {
      final listing = await _listingService.getListingForVehicle(v.id);
      listingsMap[v.id] = listing;
    }

    if (mounted) {
      setState(() {
        _vehicles = vehicles;
        _listings = listingsMap;
        _isLoading = false;
      });
    }
  }

  void _showPublishDialog(Vehicle vehicle, Listing? currentListing) {
    final priceController = TextEditingController(
      text: currentListing?.pricePerDay.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Publish ${vehicle.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price Per Day (₹)',
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceController.text);
              if (price == null) return;

              await _listingService.publishListing(vehicle.id, price);
              if (mounted) Navigator.pop(context);
              _loadData(); // Refresh
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  void _unpublish(String vehicleId) async {
    await _listingService.unpublishListing(vehicleId);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_vehicles.isEmpty) {
      return const EmptyState(
        icon: Icons.directions_car_outlined,
        message: 'No vehicles found',
        subtitle: 'Add vehicles to your fleet first',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        final listing = _listings[vehicle.id];
        final isPublished = listing?.isActive ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(vehicle.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isPublished 
              ? 'Listed at ₹${listing!.pricePerDay.toStringAsFixed(0)}/day' 
              : 'Not Listed'),
            trailing: isPublished
                ? OutlinedButton(
                    onPressed: () => _unpublish(vehicle.id),
                    child: const Text('Unpublish'),
                  )
                : ElevatedButton(
                    onPressed: () => _showPublishDialog(vehicle, listing),
                    child: const Text('Publish'),
                  ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fleetwise/models/booking.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/services/booking_service.dart';
import 'package:fleetwise/services/vehicle_service.dart';
import 'package:fleetwise/widgets/empty_state.dart';
import 'package:fleetwise/screens/booking_details_screen.dart';
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
          color: theme.scaffoldBackgroundColor,
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
            children: [
              _BookingRequestsTab(tabController: _tabController),
              _MyListingsTab(tabController: _tabController),
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
  final TabController tabController;
  
  const _BookingRequestsTab({required this.tabController});

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
    // Listen for tab changes and refresh when this tab (index 0) becomes active
    widget.tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    // Only refresh when switching TO this tab (index 0) and animation is complete
    if (widget.tabController.index == 0 && !widget.tabController.indexIsChanging) {
      _loadBookings();
    }
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
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

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: _bookings.isEmpty
          ? Stack(
              children: [
                ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 100),
                    EmptyState(
                      icon: Icons.calendar_today_outlined,
                      message: 'No bookings yet',
                      subtitle: 'Requests from clients will appear here',
                    ),
                  ],
                ),
                // Refresh button for desktop users
                Positioned(
                  top: 8,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: _loadBookings,
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    return _BookingCard(
                      booking: booking,
                      onAccept: () => _updateStatus(booking.id, 'approved'),
                      onReject: () => _updateStatus(booking.id, 'rejected'),
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingDetailsScreen(
                              booking: booking,
                              onStatusChanged: _loadBookings,
                            ),
                          ),
                        );
                        if (result == true) _loadBookings();
                      },
                    );
                  },
                ),
                // Refresh button for desktop users
                Positioned(
                  top: 8,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: _loadBookings,
                  ),
                ),
              ],
            ),
    );
  }
}


class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback? onTap;

  const _BookingCard({
    required this.booking,
    required this.onAccept,
    required this.onReject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = booking.status == 'pending';
    final dateFormat = DateFormat('MMM dd');

    Color statusColor;
    switch (booking.status) {
      case 'confirmed': statusColor = Colors.green; break;
      case 'approved': statusColor = Colors.blue; break;
      case 'rejected': statusColor = Colors.red; break;
      case 'completed': statusColor = Colors.grey; break;
      case 'cancelled': statusColor = Colors.red; break;
      default: statusColor = Colors.orange;
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
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
            if (booking.pickupLocation != null && booking.pickupLocation!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Pickup: ${booking.pickupLocation}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                    ),
                  ),
                ],
              ),
            ],
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
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: MY LISTINGS (SUPPLY) - NOW USING VEHICLES TABLE DIRECTLY
// -----------------------------------------------------------------------------
class _MyListingsTab extends StatefulWidget {
  final TabController tabController;

  const _MyListingsTab({required this.tabController});

  @override
  State<_MyListingsTab> createState() => _MyListingsTabState();
}

class _MyListingsTabState extends State<_MyListingsTab> {
  final _vehicleService = VehicleService();
  
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Listen for tab changes and refresh when this tab (index 1) becomes active
    widget.tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    // Only refresh when switching TO this tab (index 1) and animation is complete
    if (widget.tabController.index == 1 && !widget.tabController.indexIsChanging) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final vehicles = await _vehicleService.getVehicles();

    if (mounted) {
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    }
  }

  void _showPublishDialog(Vehicle vehicle) {
    final priceController = TextEditingController(
      text: vehicle.pricePerDay > 0 ? vehicle.pricePerDay.toString() : '',
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
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid price')),
                );
                return;
              }

              try {
                await _vehicleService.toggleListing(vehicle.id, true, pricePerDay: price);
                if (mounted) Navigator.pop(context);
                _loadData(); // Refresh
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  void _unpublish(String vehicleId) async {
    try {
      await _vehicleService.toggleListing(vehicleId, false);
      _loadData();
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
        final isPublished = vehicle.isListed;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(vehicle.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isPublished 
              ? 'Listed at ₹${vehicle.pricePerDay.toStringAsFixed(0)}/day' 
              : 'Not Listed'),
            trailing: isPublished
                ? OutlinedButton(
                    onPressed: () => _unpublish(vehicle.id),
                    child: const Text('Unpublish'),
                  )
                : ElevatedButton(
                    onPressed: () => _showPublishDialog(vehicle),
                    child: const Text('Publish'),
                  ),
          ),
        );
      },
    );
  }
}

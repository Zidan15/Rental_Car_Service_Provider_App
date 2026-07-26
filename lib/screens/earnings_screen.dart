// lib/screens/earnings_screen.dart
import 'package:flutter/material.dart';
import 'package:fleetwise/services/booking_service.dart';
import 'package:fleetwise/models/booking.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final BookingService _bookingService = BookingService();
  
  List<Booking> _allCompletedBookings = [];
  List<Booking> _filteredBookings = [];
  bool _isLoading = true;
  
  // Filter state
  String _selectedFilter = 'month'; // 'week', 'month', 'all', 'custom'
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);
    
    try {
      final bookings = await _bookingService.getCompletedBookings();
      if (mounted) {
        setState(() {
          _allCompletedBookings = bookings;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        _filteredBookings = _allCompletedBookings.where((b) => 
          b.endDate.isAfter(weekStart) && b.endDate.isBefore(now.add(const Duration(days: 1)))
        ).toList();
        break;
      case 'month':
        _filteredBookings = _allCompletedBookings.where((b) =>
          b.endDate.month == now.month && b.endDate.year == now.year
        ).toList();
        break;
      case 'all':
        _filteredBookings = _allCompletedBookings;
        break;
      case 'custom':
        _filteredBookings = _allCompletedBookings.where((b) =>
          b.endDate.month == _selectedMonth.month && b.endDate.year == _selectedMonth.year
        ).toList();
        break;
    }
  }

  double get _totalEarnings => _filteredBookings.fold(0.0, (sum, b) => sum + b.totalPrice);
  double get _allTimeEarnings => _allCompletedBookings.fold(0.0, (sum, b) => sum + b.totalPrice);

  void _selectFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  void _navigateMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _selectedFilter = 'custom';
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('EARNINGS', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Earnings Card
                    _EarningsCard(
                      title: _selectedFilter == 'all' ? 'All Time Earnings' : 'Earnings',
                      amount: _totalEarnings,
                      subtitle: _selectedFilter == 'custom'
                          ? DateFormat('MMMM yyyy').format(_selectedMonth)
                          : _selectedFilter == 'week'
                              ? 'This Week'
                              : _selectedFilter == 'month'
                                  ? 'This Month'
                                  : null,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Quick Filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'This Week',
                            isSelected: _selectedFilter == 'week',
                            onTap: () => _selectFilter('week'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'This Month',
                            isSelected: _selectedFilter == 'month',
                            onTap: () => _selectFilter('month'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'All Time',
                            isSelected: _selectedFilter == 'all',
                            onTap: () => _selectFilter('all'),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Month Navigator
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => _navigateMonth(-1),
                          ),
                          GestureDetector(
                            onTap: () => _selectFilter('custom'),
                            child: Text(
                              DateFormat('MMMM yyyy').format(_selectedMonth),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _selectedFilter == 'custom' 
                                    ? theme.colorScheme.primary 
                                    : null,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _selectedMonth.month == DateTime.now().month && 
                                       _selectedMonth.year == DateTime.now().year
                                ? null
                                : () => _navigateMonth(1),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment History
                    Text(
                      'Payment History',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_filteredBookings.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: theme.colorScheme.secondary.withAlpha(128),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No completed bookings',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(_filteredBookings.length, (index) {
                        final booking = _filteredBookings[index];
                        return _PaymentHistoryItem(booking: booking);
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final String title;
  final double amount;
  final String? subtitle;

  const _EarningsCard({
    required this.title,
    required this.amount,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(200),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withAlpha(180),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(
            color: theme.colorScheme.secondary.withAlpha(51),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : theme.colorScheme.secondary,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }
}

class _PaymentHistoryItem extends StatelessWidget {
  final Booking booking;

  const _PaymentHistoryItem({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.vehicleName ?? 'Vehicle',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFormat.format(booking.startDate)} - ${dateFormat.format(booking.endDate)} • ${booking.renterName ?? "Renter"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${booking.totalPrice.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Colors.green.withAlpha(180),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Paid',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

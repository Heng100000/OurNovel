import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../menu/presentation/pages/menu_page.dart';
import '../../data/invoice_model.dart';
import '../../data/invoice_service.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final InvoiceService _invoiceService = InvoiceService();
  bool _isLoading = true;
  String? _error;
  Map<String, List<InvoiceModel>> _groupedInvoices = {};

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    try {
      final invoices = await _invoiceService.getInvoices();
      if (mounted) {
        setState(() {
          _groupedInvoices = _groupInvoicesByMonth(invoices);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, List<InvoiceModel>> _groupInvoicesByMonth(
      List<InvoiceModel> invoices) {
    // Sort invoices by date descending first to ensure month order is recent first, or as returned by API
    final sortedInvoices = List<InvoiceModel>.from(invoices)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final Map<String, List<InvoiceModel>> grouped = {};
    for (var invoice in sortedInvoices) {
      final month = DateFormat('MMMM').format(invoice.createdAt);
      if (!grouped.containsKey(month)) {
        grouped[month] = [];
      }
      grouped[month]!.add(invoice);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const SideMenuDrawer(),
      appBar: AppBar(
        title: const Text('វិក្កយបត្រ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchInvoices();
              },
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    if (_groupedInvoices.isEmpty) {
      return const Center(child: Text('មិនមានវិក្កយបត្រទេ (No Invoices)'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 20, bottom: 40),
      itemCount: _groupedInvoices.length,
      itemBuilder: (context, index) {
        final month = _groupedInvoices.keys.elementAt(index);
        final invoices = _groupedInvoices[month]!;
        return _buildMonthGroup(month, invoices);
      },
    );
  }

  Widget _buildMonthGroup(String month, List<InvoiceModel> invoices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Header (Green Tab)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(
                0xFF6A8E3A), // Match the mock's slightly lighter olive green tab
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Text(
            month,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Gray container for cards
        Container(
          margin:
              const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0), // Light gray background
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: invoices
                .map((inv) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildInvoiceCard(inv),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    // Derive visual status from order if possible, fallback to fixed string
    String status = "Arrive";
    Color statusColor = const Color(0xFF7DB17D); // Default soft green

    if (invoice.order != null && invoice.order['status'] != null) {
      final oStatus = invoice.order['status'].toString().toLowerCase();
      if (oStatus == 'pending') {
        status = "Pending";
        statusColor = Colors.orange;
      } else if (oStatus == 'cancelled') {
        status = "Cancelled";
        statusColor = Colors.red;
      } else {
        status = invoice.order['status'].toString();
      }
    }

    // Try to get delivery company logo
    String? logoUrl;
    if (invoice.order != null &&
        invoice.order['shipping'] != null &&
        invoice.order['shipping']['logo_url'] != null) {
      logoUrl = invoice.order['shipping']['logo_url'];
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo box
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.contain,
                      errorWidget: (c, e, s) =>
                          const Icon(Icons.receipt_long, color: Colors.grey))
                  : const Icon(Icons.receipt_long, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),

          // Invoice details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceNo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM, yyyy').format(invoice.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Badges and actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // View Icon
              Icon(
                Icons.visibility_outlined,
                color: const Color(0xFF5A7336), // App primary matching
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

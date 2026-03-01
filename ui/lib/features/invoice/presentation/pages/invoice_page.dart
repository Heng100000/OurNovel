import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../menu/presentation/pages/menu_page.dart';
import '../../data/invoice_model.dart';
import '../../data/invoice_service.dart';
import '../../../../core/widgets/global_loader.dart';
import '../../../../theme/theme_service.dart';
import '../../../../l10n/language_service.dart';
import 'invoice_detail_page.dart';

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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, langService, child) {
        final isDark = themeService.isDarkMode;
        final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);

        final Map<String, List<InvoiceModel>> filteredGroupedInvoices = {};
        if (_searchQuery.isEmpty) {
          filteredGroupedInvoices.addAll(_groupedInvoices);
        } else {
          final query = _searchQuery.toLowerCase();
          _groupedInvoices.forEach((month, invoices) {
            final matches = invoices.where((inv) =>
                inv.invoiceNo.toLowerCase().contains(query)).toList();
            if (matches.isNotEmpty) {
              filteredGroupedInvoices[month] = matches;
            }
          });
        }

        return Scaffold(
          backgroundColor: bgColor,
          drawer: const SideMenuDrawer(),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(context, filteredGroupedInvoices, isDark, langService),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                sliver: _buildSliverBody(filteredGroupedInvoices, isDark, langService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverHeader(BuildContext context, Map<String, List<InvoiceModel>> filteredData, bool isDark, LanguageService langService) {
    int totalInvoices = 0;
    filteredData.values.forEach((list) => totalInvoices += list.length);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 160,
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF1A2410), const Color(0xFF2D3A1D)] 
                : [const Color(0xFF42542B), const Color(0xFF5A7336)],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (!_isSearching) ...[
                          Builder(
                            builder: (context) => IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                              ),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            langService.translate('invoice'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => _isSearching = true),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: langService.translate('search_invoices'),
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                                  border: InputBorder.none,
                                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70, size: 22),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _isSearching = false;
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onChanged: (value) => setState(() => _searchQuery = value),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 24, left: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _searchQuery.isEmpty ? langService.translate('invoice_activity') : langService.translate('found_results').replaceFirst('%s', totalInvoices.toString()),
                            style: TextStyle(
                              color: AppColors.accentYellow.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            langService.translate('total_invoices_label').replaceFirst('%s', totalInvoices.toString()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverBody(Map<String, List<InvoiceModel>> groupedInvoices, bool isDark, LanguageService langService) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: GlobalLoader(size: 40)),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text('Error: $_error', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetchInvoices();
                },
                child: Text(langService.translate('try_again')),
              )
            ],
          ),
        ),
      );
    }

    if (groupedInvoices.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_rounded, size: 80, color: isDark ? Colors.white10 : Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                langService.translate('no_invoices'),
                style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final month = groupedInvoices.keys.elementAt(index);
          final invoices = groupedInvoices[month]!;
          return _buildMonthGroup(month, invoices, isDark, langService);
        },
        childCount: groupedInvoices.length,
      ),
    );
  }

  Widget _buildMonthGroup(String month, List<InvoiceModel> invoices, bool isDark, LanguageService langService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16, top: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                month,
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF2D3436),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        ...invoices.map((inv) => _buildInvoiceCard(inv, isDark, langService)).toList(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice, bool isDark, LanguageService langService) {
    String statusLabel = langService.translate('paid');
    Color statusColor = const Color(0xFF00B894); 

    if (invoice.orderStatus.isNotEmpty) {
      final oStatus = invoice.orderStatus.toLowerCase();
      if (oStatus == 'pending') {
        statusLabel = langService.translate('pending_status');
        statusColor = const Color(0xFFFD9644);
      } else if (oStatus == 'cancelled') {
        statusLabel = langService.translate('cancelled_status');
        statusColor = const Color(0xFFEB3B5A);
      } else if (oStatus == 'paid' || oStatus == 'completed') {
        statusLabel = langService.translate('paid');
        statusColor = const Color(0xFF00B894);
      }
    }

    final String? logoUrl = invoice.deliveryLogoUrl;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF2D3436);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceDetailPage(invoice: invoice),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: logoUrl,
                        fit: BoxFit.contain,
                        errorWidget: (c, e, s) =>
                            Icon(Icons.inventory_2_rounded, color: AppColors.primary.withOpacity(0.5), size: 28))
                    : Icon(Icons.receipt_rounded, color: AppColors.primary.withOpacity(0.5), size: 28),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM, yyyy • hh:mm a').format(invoice.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white30 : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${double.parse(invoice.grandTotal).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


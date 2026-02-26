import 'package:flutter/material.dart';
import '../features/menu/presentation/pages/menu_page.dart';

class PromotionItem {
  final String title;
  final String author;
  final String imagePath;
  final double price;
  final double originalPrice;
  final int discountPercentage;
  final int sold;
  final int available;

  const PromotionItem({
    required this.title,
    required this.author,
    required this.imagePath,
    required this.price,
    required this.originalPrice,
    required this.discountPercentage,
    required this.sold,
    required this.available,
  });
}

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  late List<int> _soldCounts;

  @override
  void initState() {
    super.initState();
    _soldCounts = _flashSales.map((item) => item.sold).toList();
  }

  static const List<PromotionItem> _flashSales = [
    PromotionItem(
      title: 'The mythical capital',
      author: 'Mr.Moon',
      imagePath: 'assets/images/Novel.png',
      price: 26.6,
      originalPrice: 26.6,
      discountPercentage: 20,
      sold: 50,
      available: 20,
    ),
    PromotionItem(
      title: 'The mythical capital',
      author: 'Mr.Moon',
      imagePath: 'assets/images/Novel.png',
      price: 26.6,
      originalPrice: 26.6,
      discountPercentage: 20,
      sold: 50,
      available: 20,
    ),
    PromotionItem(
      title: 'The mythical capital',
      author: 'Mr.Moon',
      imagePath: 'assets/images/Novel.png',
      price: 26.6,
      originalPrice: 26.6,
      discountPercentage: 20,
      sold: 50,
      available: 20,
    ),
    PromotionItem(
      title: 'The mythical capital',
      author: 'Mr.Moon',
      imagePath: 'assets/images/Novel.png',
      price: 26.6,
      originalPrice: 26.6,
      discountPercentage: 20,
      sold: 50,
      available: 20,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const SideMenuDrawer(),
      body: Column(
        children: [
          // Header
          _buildHeader(context),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Flash Sales Title and Timer
                  _buildFlashSalesHeader(),
                  
                  // Flash Sales Grid
                  _buildFlashSalesGrid(),
                  
                  // Promotion Section
                  _buildPromotionSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF2E7D32),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12, // Reduced from 20
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 20),
                onPressed: () => Scaffold.of(context).openDrawer(),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 10), // Reduced from 20
          // Title, and Icons
          Row(
            children: [
              const Text(
                'Promotions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildHeaderIcon(Icons.notifications_none, '2'),
              const SizedBox(width: 12),
              _buildHeaderIcon(Icons.shopping_cart_outlined, '2'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, String badge) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFE57373),
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlashSalesHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2), // Tightened padding
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Flash Sales',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B6A35),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B6A35),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: const Text(
                  '02 : 25 : 30',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF4B6A35), thickness: 2),
        ],
      ),
    );
  }

  Widget _buildFlashSalesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7, // Fine-tuned to 0.7 to avoid minor overflow while staying tight
        crossAxisSpacing: 16,
        mainAxisSpacing: 8,
      ),
      itemCount: _flashSales.length,
      itemBuilder: (context, index) {
        return _buildFlashSaleItem(index);
      },
    );
  }

  Widget _buildFlashSaleItem(int index) {
    final item = _flashSales[index];
    final currentSold = _soldCounts[index];
    final total = item.sold + item.available;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 160, // Slightly shorter
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24), // Slightly more compact rounding
                image: DecorationImage(
                  image: AssetImage(item.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-${item.discountPercentage}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2), // Further reduced from 4
        Text(
          item.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF4B6A35),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          item.author,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '\$${item.price}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF4B6A35),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${item.originalPrice}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFE57373),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4B6A35),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.shopping_cart, color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 2), // Reduced from 8
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8, // Thinner track
                  activeTrackColor: const Color(0xFFE57373),
                  inactiveTrackColor: const Color(0xFFFFCDD2).withOpacity(0.3),
                  thumbColor: Colors.white,
                  overlayColor: const Color(0xFFE57373).withOpacity(0.1),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                    elevation: 3,
                  ),
                  trackShape: const RoundedRectSliderTrackShape(),
                  activeTickMarkColor: Colors.transparent,
                  inactiveTickMarkColor: Colors.transparent,
                ),
                child: SizedBox(
                  height: 20, // Much more condensed slider height
                  child: Slider(
                    value: currentSold.toDouble(),
                    min: 0,
                    max: total.toDouble(),
                    onChanged: (value) {
                      setState(() {
                        _soldCounts[index] = value.round();
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 0), // Removed gap
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sold: $currentSold', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Available: ${total - currentSold}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildPromotionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promotion',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B6A35),
            ),
          ),
          const SizedBox(height: 2), // Reduced to 2
          GridView.builder(
            padding: EdgeInsets.zero, // Explicitly set to zero to remove default gaps
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.1,
              mainAxisSpacing: 10, // Slightly reduced
              crossAxisSpacing: 16,
            ),
            itemCount: 4, // Displaying 4 items as per screenshot
            itemBuilder: (context, index) {
              return _buildCompactPromotionItem(_flashSales[index % _flashSales.length]);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCompactPromotionItem(PromotionItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15), // Softer corners from 535
              child: Image.asset(
                item.imagePath,
                width: 75,
                height: 75,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-${item.discountPercentage}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF4B6A35),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'by ${item.author}', // Re-added "by " but now controlled here
                style: TextStyle(
                  fontSize: 10, // Slightly smaller
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2), // Further reduced to 2
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${item.price}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF4B6A35),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '\$${item.originalPrice}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFD32F2F),
                              decoration: TextDecoration.lineThrough,
                              decorationThickness: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B6A35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

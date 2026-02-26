import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:ui/features/menu/presentation/pages/menu_page.dart';
import 'package:ui/widget/home_screen.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedCategory = 'View All';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'View All', 'icon': Icons.all_inclusive, 'color': Color(0xFF5A7335)},
    {'name': 'Sales', 'icon': Icons.percent, 'color': Color(0xFFF2994A)},
    {'name': 'Promotion', 'icon': Icons.campaign, 'color': Color(0xFF9B51E0)},
    {'name': 'General', 'icon': Icons.notifications, 'color': Color(0xFFBB6BD9)},
  ];

  // Static data matching the reference image
  final List<Map<String, dynamic>> _staticNotifications = [
    {
      'title': 'អបអរសាទរ ទិវាជ័យជម្នះ',
      'date': '2024-01-08 7:03 AM',
      'message': 'ខួបលើកទី៤៥ នៃទិវាជ័យជម្នះលើរបបប្រល័យពូជសាសន៍ ៧ មករា',
      'image': 'assets/images/sdach.jpg',
    },
    {
      'title': 'ថ្ងៃនេះ ជាថ្ងៃសីល ១៥ កើតពេញបូណ៌មី ខែបុស្ស',
      'date': '2024-01-08 7:03 AM',
      'message': 'សូមឱ្យរឿងល្អៗ កើតមានលើមនុស្សគ្រប់ៗគ្នា',
      'image': 'assets/images/somdach.jpg',
    },
    {
      'title': 'ប្រភេទសៀវភៅល្អៗ - From Dream to Reality',
      'date': '2024-01-08 7:03 AM',
      'message': 'ជាសៀវភៅមួយក្បាល ដែលបានបង្ហាញពីគំនិតអប់រំល្អៗ និងផ្តល់ជូននូវផ្លូវកាត់និងចំណេះដឹងការរស់នៅ',
      'image': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF42542B);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      drawer: const SideMenuDrawer(),
      body: Column(
        children: [
          // ─── Custom Header ─────────────────────────────────────
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20),
            decoration: const BoxDecoration(
              color: primaryGreen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Back + Notification Row ──────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Notification',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Hanuman',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                
                // ─── Categories (Chips like in screenshot) ──────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['name'];
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: isSelected ? Colors.white : Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: cat['color'],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(cat['icon'], color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat['name'],
                              style: const TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ─── Notification List ────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _staticNotifications.length,
              itemBuilder: (context, index) {
                final item = _staticNotifications[index];
                return _StaticNotificationCard(data: item);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticNotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _StaticNotificationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF42542B);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with Green Border
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade700, width: 1.5),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.menu_book, color: Colors.green.shade800, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'Hanuman',
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['date'],
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        data['message'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontFamily: 'Hanuman',
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (data['image'] != null)
             Center(
               child: Padding(
                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                 child: Container(
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(10),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.1),
                         blurRadius: 10,
                         offset: const Offset(0, 4),
                       ),
                     ],
                   ),
                   child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      data['image'],
                      width: 280, // Approximate from screenshot ratio
                      fit: BoxFit.contain,
                    ),
                   ),
                 ),
               ),
             ),
        ],
      ),
    );
  }
}

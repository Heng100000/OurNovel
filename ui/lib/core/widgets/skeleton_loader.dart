import 'package:flutter/material.dart';

class BaseSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsets? margin;

  const BaseSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  State<BaseSkeleton> createState() => _BaseSkeletonState();
}

class _BaseSkeletonState extends State<BaseSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class BookCardSkeleton extends StatelessWidget {
  const BookCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BaseSkeleton(
            height: 150,
            width: double.infinity,
            borderRadius: 22,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                BaseSkeleton(height: 16, width: 100),
                SizedBox(height: 8),
                BaseSkeleton(height: 12, width: 60),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BaseSkeleton(height: 16, width: 40),
                    BaseSkeleton(height: 24, width: 24, borderRadius: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BannerSkeleton extends StatelessWidget {
  const BannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseSkeleton(
      height: 160,
      width: double.infinity,
      borderRadius: 28,
    );
  }
}

class CategorySkeleton extends StatelessWidget {
  const CategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseSkeleton(
      height: 44,
      width: 100,
      borderRadius: 22,
    );
  }
}

class BookListSkeleton extends StatelessWidget {
  final bool isHorizontal;
  final int itemCount;

  const BookListSkeleton({
    super.key,
    this.isHorizontal = true,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return SizedBox(
        height: 230,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          itemBuilder: (context, index) => const BookCardSkeleton(),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const BaseSkeleton(height: 100, width: 70, borderRadius: 12),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  BaseSkeleton(height: 18, width: 150),
                  SizedBox(height: 8),
                  BaseSkeleton(height: 14, width: 80),
                  SizedBox(height: 16),
                  BaseSkeleton(height: 20, width: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const BaseSkeleton(height: 50, width: 50, borderRadius: 25),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                BaseSkeleton(height: 16, width: 200),
                SizedBox(height: 8),
                BaseSkeleton(height: 12, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

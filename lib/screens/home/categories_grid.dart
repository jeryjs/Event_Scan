import 'package:flutter/material.dart';
import 'package:event_scan/models/category_model.dart';
import '../scanner/scanner_view.dart';

class CategoriesGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final int selectedDay;

  const CategoriesGrid({super.key, required this.categories, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _CategoryCard(
                category: categories[index],
                categories: categories,
                selectedDay: selectedDay
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final List<CategoryModel> categories;
  final int selectedDay;

  const _CategoryCard({
    required this.category,
    required this.categories,
    required this.selectedDay
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScannerView(
              category: widget.category,
              categories: widget.categories,
              selectedDay: widget.selectedDay
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(widget.category.colorValue).withValues(alpha: 0.1),
                Color(widget.category.colorValue).withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.category.icon.data,
                size: 40,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 8),
              Text(
                widget.category.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';

class CustomStepSlider extends StatefulWidget {
  final List<String> values;
  final String selectedValue;
  final Function(String) onValueSelected;
  final Color? thumbColor;
  final Color? activeTextColor;
  final Color? inactiveTextColor;
  final double? containerHeight;
  final double? thumbSize;
  final double? activeFontSize;
  final double? inactiveFontSize;
  final Duration animationDuration;
  final BoxDecoration? sliderDecoration;
  final EdgeInsets thumbCorrection;

  const CustomStepSlider({
    super.key,
    required this.values,
    required this.selectedValue,
    required this.onValueSelected,
    this.thumbColor,
    this.activeTextColor,
    this.inactiveTextColor,
    this.containerHeight,
    this.thumbSize = 60.0,
    this.activeFontSize = 48.0,
    this.inactiveFontSize = 32.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.sliderDecoration,
    this.thumbCorrection = const EdgeInsets.only(left: -30.0, right: -30.0, top: 0.0, bottom: 0.0),
  });

  @override
  State<CustomStepSlider> createState() => _CustomStepSliderState();
}

class _CustomStepSliderState extends State<CustomStepSlider> {
  late double _sliderValue;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.values.indexOf(widget.selectedValue).toDouble();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.blue[100]!.withValues(alpha: 0.1),
          Colors.blue[600]!.withValues(alpha: 0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(24),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Force equal width for each item to ensure perfect alignment
        final itemWidth = widget.thumbSize!;
        final contentWidth = (itemWidth * widget.values.length).clamp(constraints.maxWidth, double.infinity);

        return Container(
          height: widget.containerHeight ?? widget.thumbSize! * 2,
          decoration: widget.sliderDecoration ?? defaultDecoration,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: _buildContent(contentWidth, itemWidth),
          )
        );
      },
    );
  }

  Widget _buildContent(double contentWidth, double itemWidth) {
    return SizedBox(
      width: contentWidth,
      height: widget.containerHeight ?? widget.thumbSize! * 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Text labels - positioned with equal spacing using y=mx+c
            ...widget.values.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              final isSelected = value == widget.selectedValue;
              
              // Calculate position using linear formula for perfect alignment with slider (y = mx + c)
              final availableWidth = contentWidth - 60.0; // Subtract padding
              final position = index * availableWidth / (widget.values.length - 1);
              
              return Positioned(
                left: position - (itemWidth / 2), // Center the text
                top: 0, bottom: 0,
                child: SizedBox(
                  width: itemWidth,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: widget.animationDuration,
                      style: TextStyle(
                        fontSize: isSelected 
                            ? widget.activeFontSize 
                            : widget.inactiveFontSize,
                        fontWeight: isSelected 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                        color: isSelected
                            ? (widget.activeTextColor ?? Theme.of(context).colorScheme.secondary)
                            : (widget.inactiveTextColor ?? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8)),
                      ),
                      child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              );
            }),
            
            // Slider
            Positioned.fill(
              top: widget.thumbCorrection.top, bottom: widget.thumbCorrection.bottom,
              left: widget.thumbCorrection.left, right: widget.thumbCorrection.right,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: widget.thumbSize! / 2,
                  ),
                  overlayShape: SliderComponentShape.noThumb,
                  thumbColor: widget.thumbColor ?? Colors.blue[100]!.withValues(alpha: 0.4),
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  trackHeight: 0,
                ),
                child: Slider(
                  value: _sliderValue,
                  min: 0,
                  max: (widget.values.length - 1).toDouble(),
                  divisions: widget.values.length - 1,
                  onChanged: (value) {
                    setState(() => _sliderValue = value);
                    widget.onValueSelected(widget.values[value.round()]);
                    _scrollToSelectedValue(value.round());
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToSelectedValue(int selectedIndex) {
    // Calculate the approximate position of the selected item
    final itemWidth = (_scrollController.position.maxScrollExtent + _scrollController.position.viewportDimension) / widget.values.length;
    final targetOffset = selectedIndex * itemWidth - _scrollController.position.viewportDimension / 2 + itemWidth / 2;
    
    // Clamp the offset to valid bounds
    final clampedOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
    
    _scrollController.animateTo(
      clampedOffset,
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
    );
  }
}

import 'package:flutter/material.dart';

class CustomStepSlider extends StatefulWidget {
  final List<String> values;
  final String selectedValue;
  final Function(String) onValueSelected;
  final Color? thumbColor;
  final Color? activeTextColor;
  final Color? inactiveTextColor;
  final double? thumbSize;
  final double? activeFontSize;
  final double? inactiveFontSize;
  final Duration animationDuration;
  final BoxDecoration? sliderDecoration;

  const CustomStepSlider({
    super.key,
    required this.values,
    required this.selectedValue,
    required this.onValueSelected,
    this.thumbColor,
    this.activeTextColor,
    this.inactiveTextColor,
    this.thumbSize = 60.0,
    this.activeFontSize = 48.0,
    this.inactiveFontSize = 32.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.sliderDecoration,
  });

  @override
  State<CustomStepSlider> createState() => _CustomStepSliderState();
}

class _CustomStepSliderState extends State<CustomStepSlider> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.values.indexOf(widget.selectedValue).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final defaultDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.blue[100]!.withOpacity(0.1),
          Colors.blue[600]!.withOpacity(0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(24),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: widget.thumbSize! * 2,
          decoration: widget.sliderDecoration ?? defaultDecoration,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Text labels
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: widget.values.map((value) {
                      bool isSelected = value == widget.selectedValue;
                      return AnimatedDefaultTextStyle(
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
                              : (widget.inactiveTextColor ?? Theme.of(context).colorScheme.secondary.withOpacity(0.8)),
                        ),
                        child: Text(
                          value,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                // Slider
                Positioned.fill(
                  left: -15, right: -15,
                  child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: widget.thumbSize! / 2,
                    ),
                    overlayShape: SliderComponentShape.noThumb,
                    thumbColor: widget.thumbColor ?? Colors.blue[100]!.withOpacity(0.4),
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
                      setState(() {
                        _sliderValue = value;
                      });
                      widget.onValueSelected(widget.values[value.round()]);
                    },
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}
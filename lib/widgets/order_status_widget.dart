import 'package:flutter/material.dart';

class OrderStatusWidget extends StatelessWidget {
  const OrderStatusWidget({super.key, required this.activeStep});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    const steps = ['Placed', 'Accepted', 'Picked up', 'Delivered'];
    return Row(
      children: List.generate(steps.length, (index) {
        final active = index <= activeStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(steps[index], textAlign: TextAlign.center),
          ),
        );
      }),
    );
  }
}

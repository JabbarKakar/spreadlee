import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';

class PriceTagWidget extends StatelessWidget {
  final String? priceTag;

  const PriceTagWidget({Key? key, this.priceTag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, Color> priceTagColors = {
      'High Price': ColorManager.customYellowF1D261,
      'Moderate Price': ColorManager.customBlue677BA9,
      'Low Price': ColorManager.customGreen759787,
      'Special Offers': ColorManager.customYellowF1D261,
    };

    Map<String, double> textSizes = {
      'High Price': 8.0,
      'Moderate Price': 8.0,
      'Low Price': 8.0,
      'Special Offers': 8.0,
    };

    Map<String, double> textWidths = {
      'High Price': 50.0,
      'Moderate Price': 65.0,
      'Low Price': 50.0,
      'Special Offers': 65.0,
    };

    if (priceTag == null || !priceTagColors.containsKey(priceTag)) {
      return const SizedBox(); // If no matching price tag, return an empty widget
    }

    return Row(
      children: [
        SizedBox(
          width: textWidths[priceTag]!,
          child: Text(
            priceTag!,
            softWrap: false,
            // overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: priceTagColors[priceTag],
              fontSize: textSizes[priceTag]!,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: priceTagColors[priceTag],
          ),
        ),
      ],
    );
  }
}

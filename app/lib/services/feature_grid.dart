import 'package:flutter/material.dart';
import 'package:matfixer/data/feature_data.dart';
import 'package:matfixer/models/feature_model.dart';

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final limitedFeatures = features.take(6).toList();
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 3;
    if (screenWidth < 1500)
    {
      crossAxisCount = 2;
    }
    if(screenWidth < 1100)
    {
      crossAxisCount = 1;
    }
    

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: screenWidth*0.75,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: limitedFeatures.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 32,
                mainAxisSpacing: 32,
                childAspectRatio:1.75
              ),
              itemBuilder: (context, index) =>
                  FeatureCard(feature: limitedFeatures[index]),
            ),
          ),
        );
      },
    );
  }
}
class FeatureCard extends StatefulWidget {
  final Feature feature;

  const FeatureCard({super.key, required this.feature});

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Card(
          elevation: _isHovered ? 10 : 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              // Handle tap if needed
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        widget.feature.icon,
                        height: 80,
                        width: 80,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.feature.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.feature.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

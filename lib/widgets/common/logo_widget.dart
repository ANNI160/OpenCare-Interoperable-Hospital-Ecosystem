import 'package:flutter/material.dart';
import '../../config/constants.dart';

class LogoWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final bool showText;

  const LogoWidget({
    super.key,
    this.width,
    this.height,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width ?? 200,
          height: height ?? 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.favorite,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'HOSPITAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                        letterSpacing: 3.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

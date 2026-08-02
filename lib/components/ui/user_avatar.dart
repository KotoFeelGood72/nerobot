import 'package:flutter/material.dart';

/// Аватар с безопасной загрузкой сети: при 404/битом URL — плейсхолдер.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 50,
    this.backgroundColor,
  });

  bool get _hasNetworkUrl {
    final url = imageUrl?.trim() ?? '';
    return url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final bg = backgroundColor ?? Colors.grey[200];

    if (!_hasNetworkUrl) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        backgroundImage: const AssetImage('assets/images/splash.png'),
      );
    }

    return ClipOval(
      child: Image.network(
        imageUrl!.trim(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          backgroundImage: const AssetImage('assets/images/splash.png'),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: SizedBox(
                width: radius,
                height: radius,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }
}

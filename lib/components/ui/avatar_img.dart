import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Divider.dart';

class AvatarImg extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String imageUrl;
  final bool isLocalImage;

  const AvatarImg({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.imageUrl,
    this.isLocalImage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white, // Белая граница
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF666666,
                ).withOpacity(0.16), // Тень с прозрачностью
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 56, // радиус CircleAvatar меньше, чтобы учесть границу
            backgroundColor: Colors.yellow,
            backgroundImage:
                isLocalImage
                    ? AssetImage(imageUrl) as ImageProvider
                    : NetworkImage(imageUrl),
          ),
        ),
        Square(),
        Text(
          '$lastName $firstName',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

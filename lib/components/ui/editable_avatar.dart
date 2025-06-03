import 'dart:io';

import 'package:flutter/material.dart';

class EditableAvatar extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EditableAvatar({
    Key? key,
    required this.imageUrl,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Аватар
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.yellow,
          backgroundImage: _getImageProvider(imageUrl), // Определение источника изображения
        ),
        // Иконка удаления
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: onDelete,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.close,
                color: Colors.red,
                size: 20,
              ),
            ),
          ),
        ),
        // Иконка редактирования
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onEdit,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.edit,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

ImageProvider _getImageProvider(String imageUrl) {
  if (imageUrl.isEmpty) {
    // Если путь пустой, используем изображение-заполнитель
    return const AssetImage('assets/images/splash.png');
  }

  if (imageUrl.startsWith('http')) {
    // Если это URL
    return NetworkImage(imageUrl);
  } else if (imageUrl.startsWith('/')) {
    // Если это локальный путь (например, из ImagePicker)
    return FileImage(File(imageUrl));
  } else {
    // Если это локальный ассет
    return AssetImage(imageUrl);
  }
}


}

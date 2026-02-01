import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/components/ui/Inputs.dart';

Future<void> showEditInput({
  required BuildContext context,
  required String initialValue, // Начальное значение
  required Color backgroundColor, // Цвет фона
  required Color textColor, // Цвет текста
  required Function(String) onSubmitted, // Callback для передачи данных
}) async {
  final TextEditingController controller = TextEditingController(
    text: initialValue,
  );

  await showModalBottomSheet(
    backgroundColor: Colors.white,
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(
          top: 40,
          left: 15,
          right: 16,
          bottom: 20,
        ),
        child: Wrap(
          spacing: 10,
          children: [
            Inputs(
              backgroundColor: backgroundColor,
              textColor: textColor,
              controller: controller,
              label: "Введите данные",
            ),
            Square(),
            SizedBox(
              width: double.infinity,
              child: Btn(
                text: 'Сохранить',
                theme: 'violet',
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                onPressed: () {
                  Navigator.pop(context, controller.text);
                },
              ),
            ),
            Square(),
          ],
        ),
      );
    },
  ).then((result) {
    if (result != null) {
      onSubmitted(result); // Передаём данные в родительский компонент
    }
  });
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';

Future<DateTime?> pickDate(
  BuildContext context, {
  DateTime? initialDate,
}) async {
  DateTime tempPickedDate = initialDate ?? DateTime.now();
  int selectedHour = tempPickedDate.hour;
  int selectedMinute = tempPickedDate.minute;

  return await showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Выберите дату",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                CalendarDatePicker(
                  initialDate: tempPickedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  onDateChanged: (date) {
                    setModalState(() {
                      tempPickedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        selectedHour,
                        selectedMinute,
                      );
                    });
                  },
                ),
                Square(),
                const Text(
                  "Выберите время",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 150, // Высота выбора времени
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedHour,
                          ),
                          itemExtent: 40, // Высота каждого элемента
                          onSelectedItemChanged: (int value) {
                            setModalState(() {
                              selectedHour = value;
                              tempPickedDate = DateTime(
                                tempPickedDate.year,
                                tempPickedDate.month,
                                tempPickedDate.day,
                                selectedHour,
                                selectedMinute,
                              );
                            });
                          },
                          children: List<Widget>.generate(
                            24,
                            (int index) => Center(
                              child: Text(index.toString().padLeft(2, '0')),
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        ":",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedMinute,
                          ),
                          itemExtent: 40,
                          onSelectedItemChanged: (int value) {
                            setModalState(() {
                              selectedMinute = value;
                              tempPickedDate = DateTime(
                                tempPickedDate.year,
                                tempPickedDate.month,
                                tempPickedDate.day,
                                selectedHour,
                                selectedMinute,
                              );
                            });
                          },
                          children: List<Widget>.generate(
                            60,
                            (int index) => Center(
                              child: Text(index.toString().padLeft(2, '0')),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Square(),
                SizedBox(
                  width: double.infinity,
                  child: Btn(
                    text: 'Готово',
                    theme: 'violet',
                    onPressed: () {
                      Navigator.pop(context, tempPickedDate);
                    },
                  ),
                ),
                Square(height: 40),
              ],
            ),
          );
        },
      );
    },
  );
}

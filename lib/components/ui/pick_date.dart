import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/utils/date_picker_utils.dart';

class PickDate extends StatefulWidget {
  final DateTime? initialDate;
  final void Function(DateTime selectedDate)? onDatePicked;
  final String label;
  final String dateFormat;

  const PickDate({
    Key? key,
    this.initialDate,
    this.onDatePicked,
    this.label = "Укажите дату и время",
    this.dateFormat = 'dd.MM.yyyy HH:mm',
  }) : super(key: key);

  @override
  State<PickDate> createState() => _PickDateState();
}

class _PickDateState extends State<PickDate> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await pickDate(
          context,
          initialDate: _selectedDate,
        );
        if (pickedDate != null) {
          setState(() {
            _selectedDate = pickedDate;
          });
          if (widget.onDatePicked != null) {
            widget.onDatePicked!(pickedDate.toUtc()); // Преобразуем дату в UTC
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Срок', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              color: AppColors.ulight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? DateFormat(widget.dateFormat).format(_selectedDate!)
                        : widget.label,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          _selectedDate != null ? Colors.black : AppColors.gray,
                    ),
                  ),
                ),
                const Text(
                  "Выбрать",
                  style: TextStyle(
                    color: AppColors.violet,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

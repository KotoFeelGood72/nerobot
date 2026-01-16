import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';

Future<void> showCitySelectionModal({
  required BuildContext context,
  required List<String> cities,
  required String? selectedCity,
  required Function(String) onCitySelected,
}) async {
  await showModalBottomSheet(
    backgroundColor: Colors.white,
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Wrap(
          children:
              cities.map((city) {
                int index = cities.indexOf(city);
                bool isActive = city == selectedCity;
                return Container(
                  decoration: BoxDecoration(
                    border:
                        index == cities.length - 1
                            ? null
                            : Border(
                              bottom: BorderSide(
                                color:
                                    isActive
                                        ? AppColors.violet
                                        : AppColors.gray,
                                width: 0.5,
                              ),
                            ),
                  ),
                  child: ListTile(
                    title: Text(
                      city,
                      style: TextStyle(
                        color: isActive ? AppColors.violet : AppColors.black,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onCitySelected(city);
                    },
                  ),
                );
              }).toList(),
        ),
      );
    },
  );
}

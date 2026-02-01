// import 'package:freelance/main.dart';
// import 'package:freelance/router/app_router.dart';
// import 'package:freelance/router/app_router.gr.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// void showGoToProfile(String message, String title) {
//   final context = Get.context;

//   if (context != null) {
//     Get.bottomSheet(
//       Container(
//         padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 24,
//               ),
//             ),
//             const Divider(),
//             Text(
//               message,
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 48),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Get.back();
//                   getIt<AppRouter>().replace(const ProfileEditRoute());
//                 },
//                 child: const Text('В профиль'),
//               ),
//             ),
//           ],
//         ),
//       ),
//       isScrollControlled: true,
//     );
//   } else {
//     print('Get.context is null. Unable to show the modal.');
//   }
// }

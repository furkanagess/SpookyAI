// COMMENTED OUT: Ghostface Trend Toggle widget disabled
// import 'package:flutter/material.dart';

// class GhostfaceTrendToggle extends StatelessWidget {
//   const GhostfaceTrendToggle({
//     super.key,
//     required this.enabled,
//     required this.usePresetImage,
//     required this.onEnabledChanged,
//     required this.onUsePresetChanged,
//   });

//   final bool enabled;
//   final bool usePresetImage;
//   final ValueChanged<bool> onEnabledChanged;
//   final ValueChanged<bool> onUsePresetChanged;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: const Color(0xFF1D162B),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.white.withOpacity(0.08)),
//           ),
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           child: Row(
//             children: [
//               const Icon(Icons.trending_up_rounded, color: Color(0xFFB25AFF)),
//               const SizedBox(width: 10),
//               const Expanded(
//                 child: Text(
//                   'Ghostface Trend',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//               Switch(
//                 value: enabled,
//                 activeColor: const Color(0xFFB25AFF),
//                 onChanged: onEnabledChanged,
//               ),
//             ],
//           ),
//         ),
//         if (enabled)
//           Padding(
//             padding: const EdgeInsets.only(top: 8),
//             child: Row(
//               children: [
//                 const Icon(
//                   Icons.image_rounded,
//                   color: Color(0xFF8C7BA6),
//                   size: 18,
//                 ),
//                 const SizedBox(width: 8),
//                 const Expanded(
//                   child: Text(
//                     'Use preset Ghostface Trend base image',
//                     style: TextStyle(color: Color(0xFFB9A8D0), fontSize: 12),
//                   ),
//                 ),
//                 Switch(
//                   value: usePresetImage,
//                   activeColor: const Color(0xFFB25AFF),
//                   onChanged: onUsePresetChanged,
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }
// }

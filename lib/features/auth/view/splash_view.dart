// import 'package:flutter/material.dart';

// class SplashView extends StatelessWidget {
//   const SplashView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               colorScheme.primary.withValues(alpha: 0.85),
//               colorScheme.primaryContainer,
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 height: 112,
//                 width: 112,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withValues(alpha: 0.14),
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: Colors.white.withValues(alpha: 0.3),
//                     width: 2,
//                   ),
//                 ),
//                 child: Icon(Icons.agriculture, size: 64, color: Colors.white),
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 'AgriFeed Solar',
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Smart solar-powered feeding control',
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   color: Colors.white.withValues(alpha: 0.82),
//                 ),
//               ),
//               const SizedBox(height: 32),
//               CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.85),
              colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 112,
                width: 112,
                // padding: const EdgeInsets.all(20), // Padding inside the circle
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 130, 223, 10).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color.fromARGB(255, 130, 223, 10).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                // child: Image.asset(
                //   'assets/icon/icon.png',
                //   fit: BoxFit.contain,
                // ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
              ),
              const SizedBox(height: 24),
              Text(
                'AgriFeed Solar',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Smart solar-powered feeding control',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
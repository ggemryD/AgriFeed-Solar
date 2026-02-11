// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../viewmodel/wifi_viewmodel.dart';

// class WiFiConfigView extends StatefulWidget {
//   const WiFiConfigView({super.key});

//   @override
//   State<WiFiConfigView> createState() => _WiFiConfigViewState();
// }

// class _WiFiConfigViewState extends State<WiFiConfigView> {
//   final _ssidController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _obscurePassword = true;

//   @override
//   void dispose() {
//     _ssidController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('WiFi Configuration'),
//       ),
//       body: Consumer<WiFiViewModel>(
//         builder: (context, viewModel, _) {
//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'ESP32 Connection Status',
//                             style: Theme.of(context).textTheme.titleMedium,
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             children: [
//                               Icon(
//                                 viewModel.isESP32Connected
//                                     ? Icons.wifi
//                                     : Icons.wifi_off,
//                                 color: viewModel.isESP32Connected
//                                     ? Colors.green
//                                     : Colors.red,
//                               ),
//                               const SizedBox(width: 8),
//                               Text(
//                                 viewModel.isESP32Connected
//                                     ? 'Connected'
//                                     : 'Not Connected',
//                                 style: TextStyle(
//                                   color: viewModel.isESP32Connected
//                                       ? Colors.green
//                                       : Colors.red,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),
//                           if (!viewModel.isESP32Connected)
//                             Text(
//                               'Make sure ESP32 is in AP mode (connect to Pig-Feeder-Setup WiFi first)',
//                               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                                 color: Colors.orange,
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TextFormField(
//                     controller: _ssidController,
//                     decoration: const InputDecoration(
//                       labelText: 'WiFi Network Name (SSID)',
//                       prefixIcon: Icon(Icons.wifi),
//                       border: OutlineInputBorder(),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter WiFi network name';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
//                   TextFormField(
//                     controller: _passwordController,
//                     obscureText: _obscurePassword,
//                     decoration: InputDecoration(
//                       labelText: 'WiFi Password',
//                       prefixIcon: const Icon(Icons.lock),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _obscurePassword ? Icons.visibility : Icons.visibility_off,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _obscurePassword = !_obscurePassword;
//                           });
//                         },
//                       ),
//                       border: const OutlineInputBorder(),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter WiFi password';
//                       }
//                       if (value.length < 8) {
//                         return 'Password must be at least 8 characters';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 24),
//                   if (viewModel.hasError)
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.red.withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.error, color: Colors.red, size: 20),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               viewModel.errorMessage!,
//                               style: const TextStyle(color: Colors.red),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           onPressed: viewModel.isTestingConnection
//                               ? null
//                               : () => viewModel.testESP32Connection(),
//                           icon: viewModel.isTestingConnection
//                               ? const SizedBox(
//                                   width: 16,
//                                   height: 16,
//                                   child: CircularProgressIndicator(strokeWidth: 2),
//                                 )
//                               : const Icon(Icons.search),
//                           label: Text(viewModel.isTestingConnection
//                               ? 'Testing...'
//                               : 'Test Connection'),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: (viewModel.isConfiguring || !viewModel.isESP32Connected)
//                               ? null
//                               : () => _configureWiFi(viewModel),
//                           icon: viewModel.isConfiguring
//                               ? const SizedBox(
//                                   width: 16,
//                                   height: 16,
//                                   child: CircularProgressIndicator(strokeWidth: 2),
//                                 )
//                               : const Icon(Icons.send),
//                           label: Text(viewModel.isConfiguring
//                               ? 'Configuring...'
//                               : 'Send Config'),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   const Card(
//                     child: Padding(
//                       padding: EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Instructions:',
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           SizedBox(height: 8),
//                           Text('1. Put ESP32 in AP mode'),
//                           Text('2. Connect your phone to "Pig-Feeder-Setup" WiFi'),
//                           Text('3. Test connection first'),
//                           Text('4. Enter your WiFi credentials'),
//                           Text('5. Send configuration to ESP32'),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Future<void> _configureWiFi(WiFiViewModel viewModel) async {
//     if (!_formKey.currentState!.validate()) return;

//     final success = await viewModel.configureWiFi(
//       ssid: _ssidController.text.trim(),
//       password: _passwordController.text,
//     );

//     if (success) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('WiFi configuration sent successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//       _ssidController.clear();
//       _passwordController.clear();
//     }
//   }
// }

// working ning babaw naay lng overflow na bug

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/wifi_viewmodel.dart';

class WiFiConfigView extends StatefulWidget {
  const WiFiConfigView({super.key});

  @override
  State<WiFiConfigView> createState() => _WiFiConfigViewState();
}

class _WiFiConfigViewState extends State<WiFiConfigView> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Configuration'),
      ),
      body: Consumer<WiFiViewModel>(
        builder: (context, viewModel, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESP32 Connection Status',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                viewModel.isESP32Connected
                                    ? Icons.wifi
                                    : Icons.wifi_off,
                                color: viewModel.isESP32Connected
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                viewModel.isESP32Connected
                                    ? 'Connected'
                                    : 'Not Connected',
                                style: TextStyle(
                                  color: viewModel.isESP32Connected
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (!viewModel.isESP32Connected)
                            Text(
                              'Make sure ESP32 is in AP mode (connect to Pig-Feeder-Setup WiFi first)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ssidController,
                    decoration: const InputDecoration(
                      labelText: 'WiFi Network Name (SSID)',
                      prefixIcon: Icon(Icons.wifi),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter WiFi network name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'WiFi Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter WiFi password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (viewModel.hasError)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              viewModel.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: viewModel.isTestingConnection
                              ? null
                              : () => viewModel.testESP32Connection(),
                          icon: viewModel.isTestingConnection
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                          label: Text(viewModel.isTestingConnection
                              ? 'Testing...'
                              : 'Test Connection'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (viewModel.isConfiguring || !viewModel.isESP32Connected)
                              ? null
                              : () => _configureWiFi(viewModel),
                          icon: viewModel.isConfiguring
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: Text(viewModel.isConfiguring
                              ? 'Configuring...'
                              : 'Send Config'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instructions:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('1. Put ESP32 in AP mode'),
                          Text('2. Connect your phone to "Pig-Feeder-Setup" WiFi'),
                          Text('3. Test connection first'),
                          Text('4. Enter your WiFi credentials'),
                          Text('5. Send configuration to ESP32'),
                        ],
                      ),
                    ),
                  ),
                  // Add extra space at bottom for keyboard
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _configureWiFi(WiFiViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await viewModel.configureWiFi(
      ssid: _ssidController.text.trim(),
      password: _passwordController.text,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WiFi configuration sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _ssidController.clear();
      _passwordController.clear();
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/products/productos_lista_screen.dart';

void main() {
  runApp(const ProviderScope(child: PulpeApp()));
}

class PulpeApp extends StatelessWidget {
  const PulpeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Pulpe',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6F4E)),
          useMaterial3: true,
        ),
        home: const ProductosListaScreen(),
      );
}

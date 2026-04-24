import 'package:flutter/material.dart';

import '../features/board/board_providers.dart';
import '../features/board/presentation/widgets/board_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BoardProviders(child: BoardScreen());
  }
}

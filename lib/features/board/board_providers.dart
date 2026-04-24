import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import 'data/board_http_source.dart';
import 'domain/board_interactor.dart';
import 'domain/board_source.dart';
import 'presentation/bloc/board_cubit.dart';

class BoardProviders extends StatelessWidget {
  const BoardProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient.create()),
        Provider<BoardSource>(
          create: (ctx) => BoardHttpSource(apiClient: ctx.read<ApiClient>()),
        ),
        Provider<BoardInteractor>(
          create: (ctx) => BoardInteractor(source: ctx.read<BoardSource>())..init(),
          dispose: (_, interactor) => interactor.dispose(),
        ),
        BlocProvider<BoardCubit>(
          create: (ctx) => BoardCubit(interactor: ctx.read<BoardInteractor>()),
        ),
      ],
      child: child,
    );
  }
}

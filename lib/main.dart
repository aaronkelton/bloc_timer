import 'dart:async';

import 'package:bloc_timer/ticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Timer',
      theme: ThemeData(
        primaryColor: const Color.fromRGBO(109, 234, 255, 1),
        colorScheme: const ColorScheme.light(
          secondary: Color.fromRGBO(72, 74, 126, 1),
        ),
      ),
      home: BlocProvider(
        create: (BuildContext context) => TimerBloc(),
        child: const TimerPage(),
      ),
    );
  }
}

class TimerPage extends StatelessWidget {
  const TimerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const TimerView();
  }
}

class TimerView extends StatelessWidget {
  const TimerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Timer')),
      body: const Stack(
        children: [
          Background(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 100.0),
                child: Center(child: TimerText()),
              ),
              Actions(),
            ],
          ),
        ],
      ),
    );
  }
}

class TimerText extends StatelessWidget {
  const TimerText({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final duration = context.select((TimerBloc bloc) => bloc.state.duration);
    final minutesStr =
        ((duration / 60) % 60).floor().toString().padLeft(2, '0');
    final secondsStr = (duration % 60).floor().toString().padLeft(2, '0');
    return Text(
      '$minutesStr:$secondsStr',
      style: Theme.of(context).textTheme.displayLarge,
    );
  }
}

class TimerEvent {}

class TimerStarted extends TimerEvent {
  final int duration;

  TimerStarted(this.duration);
}

class _TimerTicked extends TimerEvent {
  final int duration;

  _TimerTicked(this.duration);
}

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  TimerBloc() : super(TimerInitial(60)) {
    on<TimerStarted>(_onStarted);
    on<_TimerTicked>(_onTicked);
  }

  StreamSubscription<int>? _tickerSubscription;

  final Ticker _ticker = const Ticker();

  // @override
  // Future<void> close() {
  //   _tickerSubscription?.cancel();
  //   return super.close();
  // }

  _onStarted(event, emit) {
    emit(TimerRunInProgress(event.duration));
    _tickerSubscription?.cancel();
    _tickerSubscription = _ticker
        .tick(ticks: 60)
        .listen((duration) => add(_TimerTicked(duration)));
  }

  _onTicked(event, emit) {
    emit(TimerRunInProgress(event.duration));
  }
}

class TimerState {
  final int duration;

  TimerState(this.duration);
}

class TimerInitial extends TimerState {
  TimerInitial(super.duration);

  @override
  String toString() => 'TimerInitial { duration: $duration }';
}

class TimerRunInProgress extends TimerState {
  TimerRunInProgress(super.duration);

  @override
  String toString() => 'TimerRunInProgress { duration: $duration }';
}

class Actions extends StatelessWidget {
  const Actions({super.key});

  Widget playButton(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.play_arrow),
      onPressed: () {
        context.read<TimerBloc>().add(TimerStarted(60));
      },
    );
  }
  Widget pauseButton(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.pause),
      onPressed: () {},
    );
  }
  Widget resetButton(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.replay),
      onPressed: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        var buttons = [];
        if (state.runtimeType == TimerInitial) {
          buttons.add(playButton(context));
        }
        if (state.runtimeType == TimerRunInProgress) {
          buttons.add(pauseButton(context));
          buttons.add(resetButton(context));
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...buttons,
          ],
        );
      },
    );
  }
}

class Background extends StatelessWidget {
  const Background({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade500,
          ],
        ),
      ),
    );
  }
}

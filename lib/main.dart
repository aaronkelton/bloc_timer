import 'dart:async';

import 'package:bloc_timer/ticker.dart';
import 'package:bloc_timer/timer_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  Bloc.observer = TimerObserver();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    print('building material app');
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
    print('building timer view');
    return const TimerView();
  }
}

class TimerView extends StatelessWidget {
  const TimerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('building scaffold');
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
    print('building the Timer Text: $duration');
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

class TimerPaused extends TimerEvent {
  // this event doesn't accept a duration !!!
  // so I guess we don't need to pass the duration from UI to the event space
  // this is because we have access to the duration via state inside the Bloc
  TimerPaused();
}

class TimerResumed extends TimerEvent {
  TimerResumed();
}

class TimerReset extends TimerEvent {
  TimerReset();
}

class _TimerTicked extends TimerEvent {
  final int duration;

  _TimerTicked(this.duration);
}

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  TimerBloc() : super(TimerInitial(_duration)) {
    on<TimerStarted>(_onStarted);
    on<TimerPaused>(_onPaused);
    on<TimerResumed>(_onResumed);
    on<TimerReset>(_onReset);
    on<_TimerTicked>(_onTicked);
  }

  StreamSubscription<int>? _tickerSubscription;

  final Ticker _ticker = const Ticker();
  static const int _duration = 60;

  // @override
  // Future<void> close() {
  //   _tickerSubscription?.cancel();
  //   return super.close();
  // }

  _onStarted(event, emit) {
    emit(TimerRunInProgress(event.duration));
    _tickerSubscription?.cancel();
    _tickerSubscription = _ticker
        .tick(ticks: _duration)
        .listen((duration) => add(_TimerTicked(duration)));
  }

  _onPaused(event, emit) {
    emit(TimerRunPaused(state.duration));
    _tickerSubscription?.pause();
  }

  _onResumed(event, emit) {
    emit(TimerRunInProgress(state.duration));
    _tickerSubscription?.resume();
  }

  _onReset(event, emit) {
    emit(TimerInitial(_duration));
    _tickerSubscription?.cancel();
  }

  _onTicked(event, emit) {
    if (event.duration > 0) {
      emit(TimerRunInProgress(event.duration));
    } else {
      emit(TimerRunComplete());
    }
  }
}

class TimerState {
  TimerState(this.duration);
  final int duration;

  // the app run just fine without this equatable override!
  // @override
  // List<Object> get props => [duration];
}

class TimerInitial extends TimerState {
  TimerInitial(super.duration);

  @override
  String toString() => 'TimerInitial { duration: $duration }';
}

class TimerRunPaused extends TimerState {
  TimerRunPaused(super.duration);

  @override
  String toString() => 'TimerRunPaused { duration: $duration }';
}

class TimerRunInProgress extends TimerState {
  TimerRunInProgress(super.duration);

  @override
  String toString() => 'TimerRunInProgress { duration: $duration }';
}


class TimerRunComplete extends TimerState {
  TimerRunComplete() : super(0);

  @override
  String toString() => 'TimerRunComplete { duration: $duration }';
}

class Actions extends StatelessWidget {
  const Actions({super.key});

  Widget playButton(BuildContext context, TimerState state) {
    return FloatingActionButton(
      child: const Icon(Icons.play_arrow),
      onPressed: () {
        state.runtimeType == TimerInitial
            ? context.read<TimerBloc>().add(TimerStarted(state.duration))
            : context.read<TimerBloc>().add(TimerResumed());
      },
    );
  }

  Widget pauseButton(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.pause),
      onPressed: () {
        context.read<TimerBloc>().add(TimerPaused());
      },
    );
  }

  Widget resetButton(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.replay),
      onPressed: () {
        context.read<TimerBloc>().add(TimerReset());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('building the action buttons');
    return BlocBuilder<TimerBloc, TimerState>(
      // we actually don't even need buildWhen because our states are class-based???
      buildWhen: (prev, state) => prev.runtimeType != state.runtimeType,
      builder: (context, state) {
        var buttons = [];
        if (state.runtimeType == TimerInitial) {
          buttons.add(playButton(context, state));
        }
        if (state.runtimeType == TimerRunInProgress) {
          buttons.add(pauseButton(context));
          buttons.add(resetButton(context));
        }
        if (state.runtimeType == TimerRunPaused) {
          buttons.add(playButton(context, state));
          buttons.add(resetButton(context));
        }
        if (state.runtimeType == TimerRunComplete) {
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
    print('building the background');
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

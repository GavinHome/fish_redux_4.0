import 'package:fish_redux/fish_redux.dart';

enum CounterAction { increment }

class CounterActionCreator {
  static Action increment() {
    return const Action(CounterAction.increment, payload: 1);
  }
}

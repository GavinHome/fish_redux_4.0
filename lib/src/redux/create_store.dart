import 'dart:async';

import 'basic.dart';

Reducer<T> _noop<T>() => (T state, Action action) => state;

typedef _VoidCallback = void Function();

void _throwIfNot(bool condition, [String? message]) {
  if (!condition) {
    throw ArgumentError(message);
  }
}

Store<T> _createStore<T>(final T? preloadedState, final Reducer<T>? reducer,
    {List<Middleware<T>>? middleware}) {
  _throwIfNot(
    preloadedState != null,
    'Expected the preloadedState to be non-null value.',
  );

  final List<_VoidCallback> listeners = <_VoidCallback>[];
  final StreamController<T> notifyController =
      StreamController<T>.broadcast(sync: true);

  T state = preloadedState!;
  Reducer<T> _reducer = reducer ?? _noop<T>();
  bool isDispatching = false;
  bool isDisposed = false;

  Dispatch dispatch = (Action action) {
    _throwIfNot(action != null, 'Expected the action to be non-null value.');
    _throwIfNot(
        action.type != null, 'Expected the action.type to be non-null value.');
    _throwIfNot(!isDispatching, 'Reducers may not dispatch actions.');

    if (isDisposed) {
      return;
    }

    try {
      isDispatching = true;
      state = _reducer(state, action);
    } finally {
      isDispatching = false;
    }

    final List<_VoidCallback> notifyListeners = listeners.toList(
      growable: false,
    );
    for (_VoidCallback listener in notifyListeners) {
      listener();
    }

    notifyController.add(state);
  };
  final Get<T> getState = (() => state);

  dispatch = (middleware?.isNotEmpty ?? false)
      ? middleware!
          .map((Middleware<T> middleware) => middleware(
                dispatch: (Action action) => dispatch(action),
                getState: getState,
              ))
          .fold(
            dispatch,
            (Dispatch previousValue, Dispatch Function(Dispatch) element) =>
                element(previousValue),
          )
      : dispatch;
  final ReplaceReducer<T> replaceReducer = (Reducer<T>? replaceReducer) {
    _reducer = replaceReducer ?? _noop();
  };
  final Subscribe subscribe = (_VoidCallback listener) {
    _throwIfNot(
      listener != null,
      'Expected the listener to be non-null value.',
    );
    _throwIfNot(
      !isDispatching,
      'You may not call store.subscribe() while the reducer is executing.',
    );

    listeners.add(listener);

    return () {
      _throwIfNot(
        !isDispatching,
        'You may not unsubscribe from a store listener while the reducer is executing.',
      );
      listeners.remove(listener);
    };
  };
  final Observable<T> observable = (() => notifyController.stream);
  return Store<T>()
    ..getState = getState
    ..dispatch = dispatch
    ..replaceReducer = replaceReducer
    ..subscribe = subscribe
    ..observable = observable
    ..teardown = () {
      isDisposed = true;
      listeners.clear();
      return notifyController.close();
    };
}

/// create a store with enhancer
Store<T> createStore<T>(
  T? preloadedState,
  Reducer<T>? reducer, {
  List<Middleware<T>>? middleware,
}) =>
    _createStore(preloadedState, reducer, middleware: middleware);

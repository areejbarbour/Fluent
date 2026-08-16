import 'package:flutter_bloc/flutter_bloc.dart';

/// A [Cubit] that guards against the classic
/// "Bad state: Cannot emit new states after calling close" crash.
///
/// This happens whenever a cubit is closed — usually because the screen
/// that owns it (via `BlocProvider`) was popped/disposed — while an async
/// operation (typically an API call) it kicked off is still in flight.
/// When that operation finishes and the cubit method calls `emit(...)`,
/// the cubit is already closed and the base [Cubit.emit] throws.
///
/// Every cubit in this app extends [SafeCubit] instead of [Cubit] directly.
/// [emit] is overridden to silently no-op once the cubit is closed instead
/// of throwing — nothing is lost, since there's no longer a screen around
/// to receive that state anyway.
abstract class SafeCubit<State> extends Cubit<State> {
  SafeCubit(super.initialState);

  @override
  void emit(State state) {
    if (isClosed) return;
    super.emit(state);
  }
}

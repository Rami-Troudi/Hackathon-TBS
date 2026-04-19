enum GuardianAlertState {
  active,
  acknowledged,
  resolved,
}

GuardianAlertState guardianAlertStateFromRaw(String raw) => switch (raw) {
      'acknowledged' => GuardianAlertState.acknowledged,
      'resolved' => GuardianAlertState.resolved,
      _ => GuardianAlertState.active,
    };

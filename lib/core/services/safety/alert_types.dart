enum AlertTier {
  warning,
  critical,
}

enum AlertDirection {
  below,
  above,
}

typedef AlertPayload = ({
  String title,
  String body,
  AlertTier tier,
  String routePayload,
});

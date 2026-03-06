import 'dart:math';

String generateDeliveryCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rand = Random.secure();
  final code = List.generate(
    7,
    (_) => chars[rand.nextInt(chars.length)],
  ).join();

  return 'DLV-${DateTime.now().year}-$code';
}
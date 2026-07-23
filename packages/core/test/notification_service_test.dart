import 'package:nikatru_core/nikatru_core.dart';
import 'package:test/test.dart';

void main() {
  test('NoOpNotificationService is safe (never throws), grants nothing',
      () async {
    const NotificationService svc = NoOpNotificationService();
    await svc.init();
    expect(await svc.requestPermission(), isFalse);
    await svc.showNow(title: 'hi', body: 'there');
    await svc.scheduleDaily(
        const DailyReminder(id: 1, title: 't', body: 'b', hour: 9, minute: 0));
    await svc.cancel(1);
    await svc.cancelAll();
    // Reaching here without throwing is the assertion.
  });

  test('DailyReminder carries its schedule', () {
    const DailyReminder r = DailyReminder(
      id: 7,
      title: 'Keep your streak',
      body: 'A quick session keeps it alive.',
      hour: 20,
      minute: 30,
    );
    expect(r.id, 7);
    expect(r.hour, 20);
    expect(r.minute, 30);
  });
}

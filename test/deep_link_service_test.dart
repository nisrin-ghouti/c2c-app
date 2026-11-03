import 'package:c2c/core/routing/deep_link_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const eventId = 'b3f1c2d4-5e6a-4b7c-8d9e-0f1a2b3c4d5e';

  group('DeepLinkService.eventIdFromLink', () {
    test('reads the custom-scheme event link the web page hands off to', () {
      expect(
        DeepLinkService.eventIdFromLink(
          Uri.parse('com.c2c.connecttocollect://events/$eventId'),
        ),
        eventId,
      );
    });

    test('tolerates the empty-authority spelling of the same link', () {
      expect(
        DeepLinkService.eventIdFromLink(
          Uri.parse('com.c2c.connecttocollect:///events/$eventId'),
        ),
        eventId,
      );
    });

    test('tolerates a truncated connecttocollect scheme some platforms emit', () {
      expect(
        DeepLinkService.eventIdFromLink(
          Uri.parse('com.connecttocollect://events/$eventId'),
        ),
        eventId,
      );
    });

    test('reads the shareable https link', () {
      expect(
        DeepLinkService.eventIdFromLink(
          Uri.parse('https://connecttocollect-858b6.web.app/e/$eventId'),
        ),
        eventId,
      );
    });

    test('ignores the password-recovery link on the same scheme', () {
      expect(
        DeepLinkService.eventIdFromLink(
          Uri.parse('com.c2c.connecttocollect://reset-password'),
        ),
        isNull,
      );
    });

    test('ignores the benefit-redemption page on the same host', () {
      expect(
        DeepLinkService.eventIdFromLink(
          Uri.parse('https://connecttocollect-858b6.web.app/r/sometoken'),
        ),
        isNull,
      );
    });

    test('ignores an event path on another host', () {
      expect(
        DeepLinkService.eventIdFromLink(
          Uri.parse('https://evil.example.com/e/$eventId'),
        ),
        isNull,
      );
    });

    test('ignores a bare /e/ with no id', () {
      expect(
        DeepLinkService.eventIdFromLink(
          Uri.parse('https://connecttocollect-858b6.web.app/e/'),
        ),
        isNull,
      );
    });
  });
}

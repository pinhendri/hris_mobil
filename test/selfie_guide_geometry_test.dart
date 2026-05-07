import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/screens/attendance/selfie_camera_screen.dart';

void main() {
  test('selfie guide head stays round on a portrait camera viewport', () {
    const geometry = SelfieGuideGeometry();
    const cameraViewport = Size(463, 742);

    final headBounds = geometry.headBounds(cameraViewport);

    expect(headBounds.height / headBounds.width, closeTo(1, 0.02));
  });

  test('selfie guide matches the reference head and shoulder proportions', () {
    const geometry = SelfieGuideGeometry();
    const cameraViewport = Size(463, 742);

    final headBounds = geometry.headBounds(cameraViewport);
    final guideBounds = geometry.guideBounds(cameraViewport);
    final neckWidth = geometry.neckWidth(cameraViewport);

    expect(headBounds.width / cameraViewport.width, closeTo(0.48, 0.02));
    expect(headBounds.top / cameraViewport.height, closeTo(0.12, 0.02));
    expect(neckWidth / cameraViewport.width, closeTo(0.24, 0.02));
    expect(neckWidth, lessThan(headBounds.width * 0.55));
    expect(guideBounds.left / cameraViewport.width, closeTo(0.12, 0.02));
    expect(guideBounds.right / cameraViewport.width, closeTo(0.88, 0.02));
  });
}

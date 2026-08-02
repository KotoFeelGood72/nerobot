import Flutter
import UIKit
import FirebaseAuth

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    if let url = URLContexts.first?.url, Auth.auth().canHandle(url) {
      return
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}

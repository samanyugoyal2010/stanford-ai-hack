import SwiftUI
import SceneKit

struct ScenePreview: NSViewRepresentable {
    let spec: SceneSpec
    func makeNSView(context: Context) -> SCNView { let view = SCNView(); view.allowsCameraControl = true; view.autoenablesDefaultLighting = true; view.backgroundColor = NSColor(calibratedWhite: 0.08, alpha: 1); return view }
    func updateNSView(_ view: SCNView, context: Context) {
        let scene = SCNScene(); scene.rootNode.addChildNode(camera()); scene.rootNode.addChildNode(light());
        for item in spec.objects { let node = SCNNode(geometry: geometry(for: item)); node.position = SCNVector3(item.position.map(Float.init)); node.scale = SCNVector3(item.scale.map(Float.init)); scene.rootNode.addChildNode(node) }
        view.scene = scene
    }
    private func geometry(for item: SceneSpec.Object) -> SCNGeometry { let geometry: SCNGeometry; switch item.primitive.lowercased() { case "sphere": geometry = SCNSphere(radius: 0.65); case "cylinder": geometry = SCNCylinder(radius: 0.55, height: 1.2); case "plane": geometry = SCNPlane(width: 1.4, height: 1.4); default: geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.08) }; let material = SCNMaterial(); material.diffuse.contents = NSColor(hex: item.color); geometry.materials = [material]; return geometry }
    private func camera() -> SCNNode { let node = SCNNode(); node.camera = SCNCamera(); node.position = SCNVector3(0, 1.5, 7); return node }
    private func light() -> SCNNode { let node = SCNNode(); node.light = SCNLight(); node.light?.type = .omni; node.light?.intensity = 1200; node.position = SCNVector3(3, 5, 5); return node }
}

private extension NSColor { convenience init(hex: String) { var value: UInt64 = 0; Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&value); self.init(red: CGFloat((value >> 16) & 0xff) / 255, green: CGFloat((value >> 8) & 0xff) / 255, blue: CGFloat(value & 0xff) / 255, alpha: 1) } }

/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import Combine
import SceneKit

class ViewController: UIViewController, ARSessionDelegate,ARSCNViewDelegate {

  //  @IBOutlet var arView: ARView!
    @IBOutlet weak var arView: ARView!
    
        @IBOutlet weak var lbl_angle: UILabel!
    
    var n = SCNNode()
    
    var arSCNView = ARSCNView()
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [-1.0, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
       // arView.delegate = self
         arView.scene.addAnchor(characterAnchor)
         
        //arView.scene.addanc
        
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                // Scale the character to human size
                character.scale = [1.0, 1.0, 1.0]
                self.character = character
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
        let text = SCNText(string: "Foot", extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 1)
        text.flatness = 0.005
        n = SCNNode(geometry: text)
        let fontScale: Float = 0.02
        n.scale = SCNVector3(fontScale, fontScale, fontScale)
        
        
       // self.arSCNView.scene.rootNode.addChildNode(n)
        
       // self.arView.scene.rootNode.addChildNode(n)
        
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            
             //Update the position of the character anchor's position.
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            characterAnchor.position = bodyPosition + characterOffset
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation

                        
                              let arSkeleton = bodyAnchor.skeleton
                              let leftFootJoint = arSkeleton.modelTransform(for:.init(rawValue: "spine_3_joint"))
                              let leftToesEnd = arSkeleton.modelTransform(for:.init(rawValue: "left_leg_joint"))
                              let matrix1 = SCNMatrix4(leftFootJoint!)
                              let matrix2 = SCNMatrix4(leftToesEnd!)

                              let n1 = SCNNode()
                              n.transform = matrix1
                              n1.transform = matrix2
                              let position = n.position
                              let position1 = n1.position
                              let angle = SCNVector3.angleBetween(position, position1)

                              DispatchQueue.main.async {
                                  self.lbl_angle.text = "angle :\( angle * 180.0 / Float.pi)"
                                
                                
                              }
            
                              print("angle : ", angle * 180.0 / Float.pi)
                              //let leftFootJPosi = matrix1.
                          
            if let character = character, character.parent == nil {
                // Attach the character to its anchor as soon as
                // 1. the body anchor was detected and
                // 2. the character was loaded.
                characterAnchor.addChild(character)
            }
            
        }
    }

    
    //MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer,
                    didUpdate node: SCNNode,
                    for anchor: ARAnchor) {
        
        // Convert the node's position to screen coordinates
               let screenCoordinate = self.arSCNView.projectPoint(node.position)

               DispatchQueue.main.async {
               // Move the label
                self.lbl_angle.center = CGPoint(x: CGFloat(screenCoordinate.x), y: CGFloat(screenCoordinate.y))

               // Hide the label if the node is "behind the screen"
                self.lbl_angle.isHidden = (screenCoordinate.z > 1)

               // Rotate the label
                if let rotation = self.arSCNView.session.currentFrame?.camera.eulerAngles.z {
                    self.lbl_angle.transform = CGAffineTransform(rotationAngle: CGFloat(rotation + Float.pi/2))
               }
               }
        
        
            if let anchor = anchor as? ARBodyAnchor{
                let arSkeleton = anchor.skeleton
                let leftFootJoint = arSkeleton.modelTransform(for:.init(rawValue: "spine_3_joint"))
                let leftToesEnd = arSkeleton.modelTransform(for:.init(rawValue: "left_leg_joint"))
                let matrix1 = SCNMatrix4(leftFootJoint!)
                let matrix2 = SCNMatrix4(leftToesEnd!)

                let n1 = SCNNode()
                n.transform = matrix1
                n1.transform = matrix2
                let position = n.position
                let position1 = n1.position
                let angle = SCNVector3.angleBetween(position, position1)

                DispatchQueue.main.async {
                    self.lbl_angle.text = "angle :\( angle * 180.0 / Float.pi)"
                }
                print("angle : ", angle * 180.0 / Float.pi)
                //let leftFootJPosi = matrix1.
            }
    }
}

extension SCNVector3{
    
    ///Get angle in radian
    static func angleBetween(_ v1:SCNVector3, _ v2:SCNVector3)->Float{
        let cosinus = SCNVector3.dotProduct(left: v1, right: v2) / v1.length / v2.length
        let angle = acos(cosinus)
        return angle
    }
    
    /// Computes the dot product between two SCNVector3 vectors
    static func dotProduct(left: SCNVector3, right: SCNVector3) -> Float {
        return left.x * right.x + left.y * right.y + left.z * right.z
    }
    
    var length:Float {
        get {
            return sqrtf(x*x + y*y + z*z)
        }
//        set {
//            self = self.unit * newValue
//        }
    }
}

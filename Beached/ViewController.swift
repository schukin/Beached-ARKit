//
//  ViewController.swift
//  Beached
//
//  Created by Dave Schukin on 7/5/17.
//  Copyright © 2017 Buglife, Inc. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

private let beachedManScaleFactor: CGFloat = 0.0015

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    private var beachedManWithShadowNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
//        sceneView.autoenablesDefaultLighting = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognized(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateGestureRecognized(_:)))
        sceneView.addGestureRecognizer(rotateGesture)
    }
    
    @objc func tapGestureRecognized(_ tapGesture: UITapGestureRecognizer) {
        guard let beachedManWithShadowNode = beachedManWithShadowNode else {
            return
        }
        
        let point = tapGesture.location(in: tapGesture.view)
        let results = sceneView.hitTest(point, types: .existingPlane)
        
        if let result = results.first {
            let worldTransform = result.worldTransform
            beachedManWithShadowNode.transform = SCNMatrix4(worldTransform)
        }
    }
    
    private var panStart: SCNVector3?
    
    @objc func panGestureRecognized(_ panGesture: UIPanGestureRecognizer) {
        guard let beachedManWithShadowNode = beachedManWithShadowNode else {
            return
        }
        
        let panScaleFactor: Float = 500.0
        
        switch (panGesture.state) {
        case .began:
            panStart = beachedManWithShadowNode.position
        case .changed:
            if let panStart = panStart {
                let translation = panGesture.translation(in: panGesture.view)
                beachedManWithShadowNode.position.x = panStart.x + Float(translation.x) / panScaleFactor
                beachedManWithShadowNode.position.z = panStart.y + Float(translation.y) / panScaleFactor
            }
        default:
            panStart = nil
        }
    }
    
    @objc func rotateGestureRecognized(_ gesture: UIRotationGestureRecognizer) {
        guard let beachedManWithShadowNode = beachedManWithShadowNode else {
            return
        }
        
        let rotation = Float(gesture.rotation)
        beachedManWithShadowNode.eulerAngles = SCNVector3Make(0, rotation, 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let _ = anchor as? ARPlaneAnchor {
                if self.beachedManWithShadowNode == nil {
                    print("Found a plane, adding node")
                    
                    let totalNode = SCNNode.beached_manWithShadowNode(scaleFactor: beachedManScaleFactor)
                    totalNode.position = node.position
                    
                    self.beachedManWithShadowNode = totalNode
                    self.sceneView.scene.rootNode.addChildNode(totalNode)
                }
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

extension SCNNode {
    class func beached_manWithShadowNode(scaleFactor: CGFloat) -> SCNNode {
        let imageSize = UIImage.beached_man.size
        let scaledSize = imageSize.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
        let node = SCNNode()
        node.addChildNode(beached_shadowNode(size: scaledSize))
        node.addChildNode(beached_manNode(size: scaledSize))
        return node
    }
    
    private class func beached_manNode(size: CGSize) -> SCNNode {
        let node = beached_planeNode(image: UIImage.beached_man, size: size)
        
        // Raise the image up half of its height so that it just touches the floor
        node.position.y = Float(size.height / 2.0)
        return node
    }
    
    private class func beached_shadowNode(size: CGSize) -> SCNNode {
        let node = beached_planeNode(image: UIImage.beached_shadow, size: size)
        
        node.eulerAngles = SCNVector3Make(-Float.pi / 2, 0, 0)
        node.position.z = -Float(size.height / 2.0)
        return node
    }
    
    private class func beached_planeNode(image: UIImage, size: CGSize) -> SCNNode {
        let plane = SCNPlane(width: size.width, height: size.height)
        let material = SCNMaterial()
        material.diffuse.contents = image
        plane.firstMaterial = material
        return SCNNode(geometry: plane)
    }
}

extension UIImage {
    class var beached_man: UIImage {
        return UIImage(named: "man")! // Hi kids, don't force-unwrap at home, k?
    }
    
    class var beached_shadow: UIImage {
        return UIImage(named: "shadow")!
    }
}

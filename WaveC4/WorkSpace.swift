//
//  WorkSpace.swift
//  WaveC4
//
//  Created by Takahiko Inayama on 3/21/16.
//  Copyright © 2016 TETRA2000. All rights reserved.
//

import UIKit


class WorkSpace: CanvasController, RemoteRippleManagerDelegate {
    private var remoteRipple = RemoteRipple.sharedInstance
    
    override func setup() {
        let remoteRippleManager = RemoteRippleManager.sharedInstance
        remoteRippleManager.delegate = self
        remoteRippleManager.startScan()
        
        RemoteRipple.sharedInstance.startAdvertise()
        
        canvas.addTapGestureRecognizer { (locations, center, state) -> () in
            print(center)
            self.startRipple(center)
            self.remoteRipple.updateRippleState(true)
        }
        
    }
    
    private func startRipple(position: Point) {
        let animDuration = 1.6
        
        let ripple = Circle(center: position, radius: 24.0)
        ripple.strokeColor = Color.init(UIColor.clearColor())
        canvas.add(ripple)
        
        let anim = ViewAnimation(duration: animDuration, animations: {
            ripple.transform.scale(24.0, 24.0)
            ripple.fillColor = Color.init(UIColor.clearColor())
        })
        
        anim.animate()
        wait(animDuration) {
            self.canvas.remove(ripple)
        }
    }
    
    private func startReverseRipple() {
        let animDuration = 1.6
        
        let ripple = Circle(center: canvas.center, radius: 576.0)
        ripple.fillColor = Color.init(UIColor.clearColor())
        ripple.strokeColor = Color.init(UIColor.clearColor())
        canvas.add(ripple)
        
        let anim = ViewAnimation(duration: animDuration, animations: {
            ripple.transform.scale(1.0/24.0, 1.0/24.0)
            ripple.fillColor = C4Pink
        })
        
        anim.animate()
        wait(animDuration) {
            self.canvas.remove(ripple)
        }
    }
    
    //MARK: - RemoteRippleManagerDelegate
    
    func onRipple() {
        print("onRipple")
        
        startReverseRipple()
    }
}


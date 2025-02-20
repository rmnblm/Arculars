//
//  RateHandler.swift
//  Arculars
//
//  Created by Roman Blum on 13/04/15.
//  Copyright (c) 2015 RMNBLM. All rights reserved.
//

import Foundation

class RateHandler {
    
    static let RATE_INTERVAL   = 50 // after played games
    static let RATE_DONTSHOWAGAIN = "rate_dontshowagain"
    
    class func checkIfRate(playedgames: Int) -> Bool {
        if (playedgames == 0) { return false }
        
        var dontshowagain = NSUserDefaults.standardUserDefaults().boolForKey(RATE_DONTSHOWAGAIN)
        if (playedgames % RATE_INTERVAL) == 0 && (!dontshowagain) {
            return true
        }
        return false
    }
    
    class func dontShowAgain() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: RATE_DONTSHOWAGAIN)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    class func reset() {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: RATE_DONTSHOWAGAIN)
    }
}
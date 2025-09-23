//
//  AppDelegate.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import UIKit
import StripePaymentSheet

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        StripeAPI.defaultPublishableKey = "pk_test_51S8PNiKTemOlkuQhCDfEcMAmPRnLb0ly5HRiKxEfsMjmxMJOwWtW1l1sJCyo8DCTsCTuQDXTHiqvUnzBajD1F3PI007O04DVsY"
        // do any other necessary launch configuration
        return true
    }
}
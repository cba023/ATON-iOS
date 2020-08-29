//
//  CommonUtilities.swift
//  platonWallet
//
//  Created by matrixelement on 16/10/2018.
//  Copyright © 2018 ju. All rights reserved.
//

import Foundation
import UIKit

let kDocumentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first

let kCachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
let kTempPath = NSTemporaryDirectory()

let kUIScreenSize = UIScreen.main.responds(to: #selector(getter: UIScreen.nativeBounds)) ? CGSize(width: UIScreen.main.nativeBounds.size.width / UIScreen.main.nativeScale, height: UIScreen.main.nativeBounds.size.height / UIScreen.main.nativeScale) : UIScreen.main.bounds.size
let kUIScreenWidth = kUIScreenSize.width
let kUIScreenHeight = kUIScreenSize.height
let kUIScreenBounds = UIScreen.main.bounds
let kStatusBarHeight = UIApplication.shared.statusBarFrame.height

let kAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"]

let kVersion = (UIDevice.current.systemVersion as NSString).floatValue

let kiOS12 = (kVersion >= 12.0)
let kiOS11 = (kVersion >= 11.0 && kVersion < 12.0)
let kiOS10 = (kVersion >= 10.0 && kVersion < 11.0)
let kiOS9 = (kVersion >= 9.0 && kVersion < 10.0)
let kiOS8 = (kVersion >= 8.0 && kVersion < 9.0)
let kiOS12Later = (kVersion >= 12.0)
let kiOS11Later = (kVersion >= 11.0)
let kiOS10Later = (kVersion >= 10.0)
let kiOS9Later = (kVersion >= 9.0)
let kiOS8Later = (kVersion >= 8.0)


/// 安全区底部缩进
var kSafeAreaBottomInset: CGFloat {
    if #available(iOS 11.0, *), let keyWindow = UIApplication.shared.keyWindow {
        return keyWindow.safeAreaInsets.bottom
    }
    return 0.0
}

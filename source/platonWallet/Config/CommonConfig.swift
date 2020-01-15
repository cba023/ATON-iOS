//
//  CommonConfig.swift
//  platonWallet
//
//  Created by Admin on 10/9/2019.
//  Copyright © 2019 ju. All rights reserved.
//

import Foundation
import Localize_Swift

struct AppConfig {
    struct Keys {
        static let BuglyAppleID = "e8f57be7d2"
        static let Production_Umeng_key = "5d551ffd3fc1959f6b000113"
        static let Test_Umeng_key = "5d57a9ba570df380e2000b23"
    }

    struct ChainID {
        static let VERSION_074 = "97"
        static let VERSION_0741 = "96"
        static let VERSION_MAINNET = "95"
        static let VERSION_UATNET = "299"
        static let TEST = "103"
        #if UAT //测试网络
        static let PRODUCT = "101"
        #elseif PARALLELNET // 平行网络
        static let PRODUCT = AppConfig.ChainID.VERSION_UATNET
        #else
        static let PRODUCT = AppConfig.ChainID.VERSION_MAINNET
        #endif
    }

    struct NodeURL {
        static let DefaultNodeURL_Alpha_V071 = ServerURL.HOST.TESTNET + "/rpc"
        static let DefaultNodeURL_Alpha_V071_DEV = ServerURL.HOST.DEVNET + "/rpc"
        static let DefaultNodeURL_UAT = ServerURL.HOST.UATNET + "/rpc"
        static let DefaultNodeURL_PRODUCT = ServerURL.HOST.PRODUCTNET + "/rpc"

        #if UAT
        static let defaultNodesURL = [
            (nodeURL: AppConfig.NodeURL.DefaultNodeURL_Alpha_V071, desc: "SettingsVC_nodeSet_defaultTestNetwork_test_des", chainId: AppConfig.ChainID.PRODUCT, isSelected: true),
            (nodeURL: AppConfig.NodeURL.DefaultNodeURL_Alpha_V071_DEV, desc: "SettingsVC_nodeSet_defaultTestNetwork_develop_des", chainId: AppConfig.ChainID.TEST, isSelected: false)
        ]
        #elseif PARALLELNET
        static let defaultNodesURL = [
            (nodeURL: DefaultNodeURL_UAT, desc: "SettingsVC_nodeSet_parallel_des", chainId: AppConfig.ChainID.PRODUCT, isSelected: false),
        ]
        #else
        static let defaultNodesURL = [
            (nodeURL: DefaultNodeURL_PRODUCT, desc: "SettingsVC_nodeSet_NewBaleyworld_des", chainId: AppConfig.ChainID.PRODUCT, isSelected: false),
        ]
        #endif
    }

    struct TimerSetting {
        static let pendingTransactionPollingTimerEnable = true
        static let pendingTransactionPollingTimerInterval = 3
        static let balancePollingTimerInterval = 5
        static let viewControllerUpdateInterval = 3
    }

    struct H5URL {
        struct LisenceURL {
            static let serviceurl_en = SettingService.shareInstance.getCentralizationHost() + "/aton-agreement/en-us/agreement.html"
            static let serviceurl_cn = SettingService.shareInstance.getCentralizationHost() + "/aton-agreement/zh-cn/agreement.html"

            static var serviceurl: String {
                return Localize.currentLanguage() == "en" ? serviceurl_en : serviceurl_cn
            }
        }

        struct FAQURL {
            static let faq_en = "https://platon.zendesk.com/hc/en-us/articles/360037373194-Common-questions-about-PlatON-Delegators"
            static let faq_cn = "https://platon.zendesk.com/hc/zh-cn/articles/360037373194-%E5%A7%94%E6%89%98%E4%BA%BA%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98"

            static var faqurl: String {
                return Localize.currentLanguage() == "en" ? faq_en : faq_cn
            }
        }

        struct TutorialURL {
            static let tutorial_en = "https://platon.zendesk.com/hc/en-us/categories/360002193633"
            static let tutorial_cn = "https://platon.zendesk.com/hc/zh-cn/categories/360002193633"

            static var tutorialurl: String {
                return Localize.currentLanguage() == "en" ? tutorial_en : tutorial_cn
            }
        }

        struct FeedbackURL {
            static let feedback_en = "https://platon.zendesk.com/hc/en-us"
            static let feedback_cn = "https://platon.zendesk.com/hc/zh-cn"

            static var feedbackurl: String {
                return Localize.currentLanguage() == "en" ? feedback_en : feedback_cn
            }
        }

        struct PrivacyPolicyURL {
            static let policy_en = SettingService.shareInstance.getCentralizationHost() +  "/aton-agreement/en-us/privacyAgreement.html"
            static let policy_cn = SettingService.shareInstance.getCentralizationHost() + "/aton-agreement/zh-cn/privacyAgreement.html"

            static var policyurl: String {
                return Localize.currentLanguage() == "en" ? policy_en : policy_cn
            }
        }
    }

    struct ServerURL {
        struct HOST {
            static let UATNET = "https://aton.uatnet.platon.network"
            static let PRODUCTNET = "https://aton.main.platon.network"
//            static let TESTNET = "http://192.168.9.190:1000"
            static let TESTNET = "http://58.250.250.234:1000"
//            static let TESTNET = "http://58.250.250.234:1000"
            static let DEVNET = "http://192.168.9.190:443"
//            static let DEVNET = "http://192.168.120.141:6789"
        }
        static let PATH = "/app/v0760"
    }

    struct AppInfo {
        static let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }

    struct OvertimeTranction {
        static let overtime = 2*60*60*1000
    }
}

extension String {
    var chainid: String {
        switch self {
        case AppConfig.NodeURL.DefaultNodeURL_Alpha_V071_DEV:
            return AppConfig.ChainID.TEST
        default:
            return AppConfig.ChainID.PRODUCT
        }
    }
}

//
//  NodeModel+Extension.swift
//  platonWallet
//
//  Created by Admin on 12/8/2019.
//  Copyright © 2019 ju. All rights reserved.
//

import Foundation
import UIKit

extension Node {
    var nStatus: NodeStatus {
        switch nodeStatus {
        case "Active":
            return .Active
        case "Candidate":
            return .Candidate
        case "Exiting":
            return .Exiting
        case "Exited":
            return .Exited
        default:
            return .Active
        }
    }

    var delegateAmount: String {
        return (deposit?.vonToLATString ?? "0.00").ATPSuffix()
    }

    var status: (String, UIColor) {
        switch nStatus {
        case .Active:
            return (nStatus.description, status_blue_color)
        case .Candidate:
            return (nStatus.description, status_green_color)
        case .Exiting:
            return (nStatus.description, status_darkgray_color)
        case .Exited:
            return (nStatus.description, status_lightgray_color)
        }
    }

    var rate: String {
        if isInit {
            return "--"
        }
        guard let ratePAf = Float(ratePA ?? "0"), ratePAf > 0.0 else { return "0.00%" }
        return String(format: "%.2f", (ratePAf / 100.0)).balanceFixToDisplay(maxRound: 2) + "%"
    }

    var rank: (String, UIImage?) {
        switch ranking {
        case 1:
            return ("1", UIImage(named: "3.img_mark1"))
        case 2:
            return ("2", UIImage(named: "3.img_mark2"))
        case 3:
            return ("3", UIImage(named: "3.img_mark3"))
        default:
            return (String(format: "%d", ranking), UIImage(named: "3.img_mark4"))
        }
    }
}

extension NodeDetail {

    var totalStaked: String {
        return node.deposit?.vonToLATString ?? "0"
    }

    var delegations: String {
        return delegateSum?.vonToLATString ?? "0"
    }

    var slash: String {
        return String(format: "%d", punishNumber ?? 0)
    }

    var blockOut: String {
        return String(format: "%d", blockOutNumber ?? 0)
    }

    var bRate: String {
        return String(format: "%.2f", ((Float(blockRate ?? "0") ?? 0) / 100.0)) + "%"
    }

    var websiteForDisplay: String {
        if (website ?? "").count > 0 {
            return website!
        }
        return "--"
    }

    var institutionalForDisplay: String {
        if (intro ?? "").count > 0 {
            return intro!
        }
        return "--"
    }
}

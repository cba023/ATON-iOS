//
//  VoteManager+Centralization.swift
//  platonWallet
//
//  Created by Ned on 2019/3/26.
//  Copyright © 2019 ju. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import Localize_Swift

//let CentralizationURL = "http://192.168.9.190:18060/browser-server/"
let DEBUG_CentralizationURL = "http://192.168.9.190:10061/api-203/api/"
let chaindId = "203"
let DefaultCentralizationURL = "https://aton.platon.network/"
let requestTimeout : TimeInterval = 30

extension VoteManager{
    
    public func getCentralizationURL() -> String{
        let url = SettingService.getCurrentNodeURLString()
        if url == DefaultNodeURL_Alpha{
            return DefaultCentralizationURL + "api-" + self.getChainID() + "/api/"
        }else if url == DefaultNodeURL_Beta{
            return DefaultCentralizationURL + "api-" + self.getChainID() + "/api/"
        }else if url == "http://192.168.120.81:6789"{
            
            return DEBUG_CentralizationURL
        }
        return DefaultCentralizationURL + "api-" + self.getChainID() + "/api/"
    }
    
    public func getChainID() -> String{
        let url = SettingService.getCurrentNodeURLString()
        if url == DefaultNodeURL_Alpha{
            return "103"
        }else if url == DefaultNodeURL_Beta{
            return "104"
        }
        return chaindId
    } 
    
    public func getBatchVoteSummary(addressList: [String], completion: PlatonCommonCompletion?) {
        var completion = completion
        var values : Dictionary<String,Any> = [:]
        
        values["cid"] = self.getChainID()
        values["addressList"] = addressList
        let url = self.getCentralizationURL() + "getBatchVoteSummary" 
        
        var request = URLRequest(url: try! url.asURL())
        request.httpBody = try! JSONSerialization.data(withJSONObject: values)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = requestTimeout
        
        Alamofire.request(request).responseJSON { (response) in
            switch response.result{
                
            case .success(let resp):
                
                guard let respmap = resp as? [String:Any], let data = respmap["data"] as? [Dictionary<String,Any>] else {
                    self.failCompletionOnMainThread(code: -1, errorMsg: "", completion: &completion)
                    return
                }
                let nodesum = MyVoteStatic.parserAllNodeSummary(mapArray: data)
                self.successCompletionOnMain(obj: nodesum as AnyObject, completion: &completion)
                
            case .failure(let error):
                self.failCompletionOnMainThread(code: -1, errorMsg: error.localizedDescription, completion: &completion)
            }
        }

    }
    
    public func getBatchVoteTransaction(pageNo:Int = 1, pageSize: Int = 2<<16, completion: PlatonCommonCompletion?) {
        var completion = completion
        var values : Dictionary<String,Any> = [:]
        var walletAddrs: [String] = []
        
        for item in WalletService.sharedInstance.wallets{
            walletAddrs.append((item.key?.address)!)
        }
        
        values["cid"] = self.getChainID()
        values["walletAddrs"] = walletAddrs
        values["pageNo"] = pageNo
        values["pageSize"] = pageSize
         
        let url = self.getCentralizationURL() + "getBatchVoteTransaction"
         
        var request = URLRequest(url: try! url.asURL())
        request.httpBody = try! JSONSerialization.data(withJSONObject: values)
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        Alamofire.request(request).responseString { str in
            print("getBatchVoteTransaction response:\(str)")
        }
        Alamofire.request(request).responseJSON { (response) in
            switch response.result{
                
            case .success(let resp):
                
                guard let respd = resp as? [String:Any], let data = respd["data"] as? [Dictionary<String,Any>] else {
                    self.failCompletionOnMainThread(code: -1, errorMsg: Localized("data_parser_error"), completion: &completion)
                    return
                }
                
                DispatchQueue.global().async {
                    let nodesum = NodeVoteSummary.parserWithDicArray(mapArray: data)
                    self.successCompletionOnMain(obj: nodesum as AnyObject, completion: &completion)
                }
                
            case .failure(let error):
                self.failCompletionOnMainThread(code: -1, errorMsg: error.localizedDescription, completion: &completion)
            }
        }
    }
    
    

}
//
//  PTextFieldView.swift
//  platonWallet
//
//  Created by juzix on 2019/3/5.
//  Copyright © 2019 ju. All rights reserved.
//

import UIKit

enum CheckMode {
    case endEdit
    case textChange
    case all
}

class PTextFieldView: UIView {
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var textField: UITextField!
    
    var textFieldShouldReturnCompletion : ((_ textField: UITextField) -> (Bool))?
    
    var shouldChangeCharactersCompletion: ((_ concatenated : String, _ replacement: String) -> (Bool))?
    
    var endEditCompletion: ((_ string : String) -> ())?
    
    @IBOutlet weak var line: UIView!

    @IBOutlet weak var tipsLabel: UILabel!
    
    @IBOutlet weak var textFieldRightConstraint: NSLayoutConstraint!
    
    private var actions:[()->Void] = []
    
    var internalHeight: Float = 65.0
    
    var appendText = ""
    
    private var mode: CheckMode = .endEdit
    
    private var check:((String)->(correct:Bool, errMsg:String))?
    
    private var heightChange:((PTextFieldView)->Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
        textField.textAlignment = .left
        NotificationCenter.default.addObserver(self, selector: #selector(textDidBeginEditing(_:)), name: UITextField.textDidBeginEditingNotification, object: nil)
    }
    
    class func create(title: String) -> PTextFieldView {
        let textFieldView = UIView.viewFromXib(theClass: PTextFieldView.self) as! PTextFieldView
        textFieldView.title.text = title
        return textFieldView
    }
    
    func addAction(title: String? = nil, icon: UIImage? = nil, action:@escaping (()->Void)) {
        
        let btn = UIButton(type: .custom)
        if title != nil {
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(common_blue_color, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        }
        if icon != nil {
            btn.setImage(icon, for: .normal)
            btn.imageView?.contentMode = .center
        }
        
        btn.tag = actions.count
        btn.addTarget(self, action: #selector(action(_:)), for: .touchUpInside)
        addSubview(btn)
        btn.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(24.5)
            make.height.equalTo(40)
            make.width.equalTo(32)
            make.right.equalToSuperview().offset(-12 - (actions.count * 32))
        }
        
        actions.append(action)
        
        textFieldRightConstraint.constant = CGFloat(16 + (actions.count * 32))
        
        layoutIfNeeded()
    }
    
    func checkInput(mode:CheckMode, check:@escaping ((String)->(Bool,String)), heightChange:@escaping ((PTextFieldView)->Void)) {
        self.mode = mode
        self.check = check
        self.heightChange = heightChange
    }
    
    public func checkInvalidNow(showText: Bool) -> (correct:Bool, errMsg:String)? {
        if self.check == nil{
            assert(false, "Fatal Error:no check logic")
        } 
        return self.startCheck(text: self.textField.text ?? "" , showErrorMsg: false)
    }
    
    public func cleanErrorState(){
        tipsLabel.text = ""
        line.backgroundColor = UIColor(rgb: 0xD5D8DF)
        internalHeight = 65.0
        tipsLabel.isHidden = true
        heightChange?(self)
    }
    
    @objc private func action(_ sender: UIButton) {
        actions[sender.tag]()
    }
    
    private func startCheck(text: String, showErrorMsg: Bool = true, isEditing: Bool = false) -> (correct:Bool, errMsg:String)? {
        guard check != nil else {
            return nil
        }
                
        //let curState = internalHeight == 65.0 ? true:false
        let res = check!(text)
        if !showErrorMsg{
            return res
        }
        if res.correct  {
            if isEditing{
                line.backgroundColor = bottomLineEditingColor
            }else{
                line.backgroundColor = bottomLineNormalColor
            }
            
            internalHeight = 65.0
            tipsLabel.isHidden = true
            heightChange?(self)
        }else if !res.correct {
            tipsLabel.isHidden = false
            line.backgroundColor = bottomLineErrorColor
            tipsLabel.text = res.errMsg
            internalHeight = 90.0
            
            heightChange?(self)
        }
        return res
    }
    
    
    
}

extension PTextFieldView: UITextFieldDelegate {
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard self.endEditCompletion != nil else {
            return 
        }
        
        self.endEditCompletion!(textField.text!)
        
        //check must be in the last
        if mode == .endEdit || mode == .all{
            let _ = startCheck(text: textField.text ?? "")
        }
    } 
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if mode == .textChange || mode == .all {
            if let text = textField.text,let textRange = Range(range, in: text) {
                let appendtext = text.replacingCharacters(in: textRange, with: string)
                let _ = startCheck(text: appendtext,isEditing: true)
            }
        }
        
        if let text = textField.text,let textRange = Range(range, in: text) {
            let appendtext = text.replacingCharacters(in: textRange, with: string)
            guard shouldChangeCharactersCompletion != nil else{
                return true
            }
            return self.shouldChangeCharactersCompletion!(appendtext,string)
        }
        
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard self.textFieldShouldReturnCompletion != nil else {
            return false
        }
        return self.textFieldShouldReturnCompletion!(textField)
    }
    
    //MARK: - TextField Notification
    @objc func textDidBeginEditing(_ notification: Notification){
        if let theTextField = notification.object as? UITextField, theTextField == self.textField{
            line.backgroundColor = bottomLineEditingColor
        } 
    }
    
}

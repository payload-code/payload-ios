//
//  CheckoutViewController.swift
//  Payload
//
//  Copyright © 2020 Payload. All rights reserved.
//

import UIKit
import AMPopTip
import InputMask
import SwiftSVG

class CheckoutViewController: UIViewController, MaskedTextFieldDelegateListener, UITextFieldDelegate {

    @IBOutlet weak var title_label: PayloadTitle!
    @IBOutlet var card_number_listener: MaskedTextFieldDelegate!
    @IBOutlet var expiry_listener: MaskedTextFieldDelegate!
    @IBOutlet var card_code_listener: MaskedTextFieldDelegate!
    @IBOutlet var zipcode_listner: MaskedTextFieldDelegate!
    @IBOutlet weak var card_number: PayloadTextField!
    @IBOutlet weak var zipcode: PayloadTextField!
    @IBOutlet weak var card_code: PayloadTextField!
    @IBOutlet weak var expiry: PayloadTextField!
    @IBOutlet weak var pay_btn: PayloadPayBtn!
    @IBOutlet weak var cardbg: PayloadCard!
    @IBOutlet weak var card_number_display: PayloadCardLabel!
    @IBOutlet weak var expiry_display: PayloadCardLabel!
    @IBOutlet weak var cardholder_display: PayloadCardLabel!
    @IBOutlet weak var cardholder_name: PayloadTextField!
    @IBOutlet weak var emv_icon_view: UIView!
    
    @IBOutlet weak var bottom_padding: NSLayoutConstraint!
    @IBOutlet weak var total_label: UILabel!
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var form_view: UIView!
    @IBOutlet weak var card_view: UIView!
    
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var cardbg_height: NSLayoutConstraint!
    @IBOutlet weak var content_view: UIView!
    
    @IBOutlet weak var height_cardbg: NSLayoutConstraint!
    
    @IBAction func cardholderChanged(_ sender: Any) {
        self.update_card_text_display(cardholder_name)
    }
    
    var first_run:Bool = true;
    
    var checkout:Payload.Checkout;
        
    var cc_brand:UIView?
    
    var cardnumber_tip:PopTip;
    var expiry_tip:PopTip;
    var card_code_tip:PopTip;
    var zipcode_tip:PopTip;
    
    var alert_visible = false;
    
    open func textField(
        _ textField: UITextField,
        didFillMandatoryCharacters complete: Bool,
        didExtractValue value: String
        ) {
        self.update_card_text_display(textField)
        
        if textField == card_number {
            self.cardnumber_tip.hide()
        } else if textField == expiry {
            self.expiry_tip.hide()
        } else if textField == card_code {
            self.card_code_tip.hide()
        } else if textField == zipcode {
            self.zipcode_tip.hide()
        }
    }
    
    func update_card_text_display(_ textField: UITextField) {
        if textField == card_number {
            if card_number.text?.isEmpty ?? true {
                card_number_display.textColor = card_number_display.textColor.withAlphaComponent(0.5)
                card_number_display.text = "•••• •••• •••• ••••"
            } else {
                card_number_display.textColor = card_number_display.textColor.withAlphaComponent(1)
                let len = card_number.text!.count
                let unmasked = len % 5
                card_number_display.text = String("•••• •••• •••• ••••".prefix(max(len-unmasked,0)))+String(card_number.text!.suffix(unmasked))
            }
            self.update_card_brand()
        } else if textField == expiry {
            if expiry.text?.isEmpty ?? true {
                expiry_display.text = "MM/YY"
                expiry_display.textColor = expiry_display.textColor.withAlphaComponent(0.5)
            } else {
                expiry_display.text = expiry.text?.replacingOccurrences(of: " ", with: "")
                expiry_display.textColor = expiry_display.textColor.withAlphaComponent(1)
            }
        } else if textField == cardholder_name {
            if cardholder_name.text?.isEmpty ?? true {
                cardholder_display.text = "First Last"
                cardholder_display.textColor = cardholder_display.textColor.withAlphaComponent(0.5)
            } else {
                cardholder_display.text = cardholder_name.text
                cardholder_display.textColor = cardholder_display.textColor.withAlphaComponent(1)
            }
        }
    }
    
    @IBAction func exitText(_ sender: Any) {
        self.view.endEditing(true);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        card_number_listener.delegate = self
        expiry_listener.delegate = self
        card_code_listener.delegate = self
        zipcode_listner.delegate = self
        cardholder_name.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
        
        if #available(iOS 10.0, *) {
            card_number.keyboardType = UIKeyboardType.asciiCapableNumberPad;
            expiry.keyboardType = UIKeyboardType.asciiCapableNumberPad;
            zipcode.keyboardType = UIKeyboardType.asciiCapableNumberPad;
            card_code.keyboardType = UIKeyboardType.asciiCapableNumberPad;
        }
        
        cardholder_name.tag = 0
        card_number.tag = 1
        expiry.tag = 2
        card_code.tag = 3
        zipcode.tag = 4
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
        
        if self.checkout.payment["type"] as! String == "refund" {
            self.pay_btn.setTitle("Refund", for: .normal)
            self.title_label.text = "Refund"
        }
        
        self.total_label.text = String(format: "Total: $%.02f", self.checkout.payment.amount ?? 0)
        
        card_number.attributedPlaceholder = NSAttributedString(string:"Card Number", attributes: [
                NSAttributedString.Key.foregroundColor: card_number.placeholder_color
            ])
        
        cardholder_name.attributedPlaceholder = NSAttributedString(string:"Cardholder Name", attributes: [
                NSAttributedString.Key.foregroundColor: cardholder_name.placeholder_color
            ])
        
        expiry.attributedPlaceholder = NSAttributedString(string:"Expiration", attributes: [
                NSAttributedString.Key.foregroundColor: expiry.placeholder_color
            ])
        
        zipcode.attributedPlaceholder = NSAttributedString(string:"Zipcode", attributes: [
                NSAttributedString.Key.foregroundColor: zipcode.placeholder_color
            ])
        
        card_code.attributedPlaceholder = NSAttributedString(string:"CVV", attributes: [
                NSAttributedString.Key.foregroundColor: card_code.placeholder_color
            ])
        
        navigationItem.titleView = title_label
    }
    
    func set_modal_style(_ modal_style:UIModalPresentationStyle) {
        if ( modal_style == .formSheet ) {
            let height:CGFloat = 500.0
            let width:CGFloat = 500.0
            view.superview?.bounds.size.height = height
            view.superview?.frame.size.height = height
            view.frame.size.height = height
            view.bounds.size.height = height
            view.superview?.sizeToFit()
            view.superview?.layoutIfNeeded()
            view.superview?.layoutSubviews()
            //view.superview?.layer.shadowColor = UIColor.clear.cgColor
            navigationController?.view.superview?.bounds.size.height = height
            navigationController?.view.superview?.frame = CGRect( 0, 0, width, height)
            navigationController?.view.superview?.center = self.view.center
            navigationController?.preferredContentSize = CGSize(width: width,height: height)
            
            
            //card_view.autoresizesSubviews = true
            card_view.isHidden = true
        }
        
        navigationController?.modalPresentationStyle = modal_style
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.setcardsize()
        self.update_card_text_display(card_number)
        self.update_card_text_display(expiry)
        self.update_card_text_display(cardholder_name)
        
        if ( navigationController?.modalPresentationStyle == .formSheet ) {
            height_cardbg.constant = 29 + (navigationController?.navigationBar.frame.height)!
            bottom_padding.constant = 20
            card_view.isHidden = true
        }
        
    }
    
    @objc func keyboardWillShow(notification:NSNotification){
        if ( navigationController?.modalPresentationStyle == .formSheet ) {
            return
        }
        
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = self.scrollview.contentInset
        contentInset.bottom = keyboardFrame.size.height
        scrollview.contentInset = contentInset
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        scrollview.contentInset = contentInset
    }
    
    let visa = try! NSRegularExpression(pattern: "^4");
    let mastercard = try! NSRegularExpression(pattern: "^[52]")
    let discover = try! NSRegularExpression(pattern: "^6");
    let amex = try! NSRegularExpression(pattern: "^3");
    
    func update_card_brand() {
        if self.cc_brand != nil {
          self.cc_brand?.removeFromSuperview()
        }
        
        if card_number.text == nil {
            return
        }
        
        let range = NSRange(location:0, length: card_number.text!.count );

        var icon:URL?;
        
        if visa.firstMatch(in: card_number.text!, options: [], range: range ) != nil {
            icon = Bundle(for: Payload.self).url(forResource:"visa", withExtension:"svg")
        } else if mastercard.firstMatch(in: card_number.text!, options: [], range: range ) != nil {
            icon = Bundle(for: Payload.self).url(forResource:"mastercard", withExtension:"svg")
        } else if discover.firstMatch(in: card_number.text!, options: [], range: range ) != nil {
            icon = Bundle(for: Payload.self).url(forResource:"discover", withExtension:"svg")
        } else if amex.firstMatch(in: card_number.text!, options: [], range: range ) != nil {
            icon = Bundle(for: Payload.self).url(forResource:"amex", withExtension:"svg")
        }
        
        if icon != nil {
            self.cc_brand = UIView(SVGURL: icon!) { (svgLayer) in
                svgLayer.fillColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.00).cgColor
                let scale = CGAffineTransform(scaleX:0.15, y:0.15)
                DispatchQueue.main.async {
                    svgLayer.setAffineTransform(scale)
                }

                svgLayer.frame.origin.x = self.cardbg.frame.size.width - 100
                svgLayer.frame.origin.y = 0
            }
            self.cardbg.addSubview(self.cc_brand!)
        }
    }
    
    func setcardsize() {
        let ratio = CGFloat(1.586);
        let max_ratio = CGFloat(1.8);
        let screenRect = UIScreen.main.bounds
        let min_top:CGFloat = 80
        let min_padding:CGFloat = 20
        var h = screenRect.size.height*0.4 - min_top - min_padding
        let w = screenRect.size.width - min_padding

        h = max(h, 170)
        h = min(h, 250)
        
        cardbg.autoresizesSubviews = true
        
        cardbg.frame.size.height = h

        if w/h / max_ratio < 1.25 {
            cardbg.frame.size.width = min(h*max_ratio, w)
        } else {
            cardbg.frame.size.width = h*ratio
        }
        cardbg.frame.origin.y = min_top
        cardbg.frame.origin.x = (self.view.superview!.frame.size.width-cardbg.frame.size.width)/2
        
        height_cardbg.constant = h + min_top + min_padding
        
        if ( first_run && cardbg.drop_shadow ) {
            cardbg.dropShadow()
        }
        first_run = false
        
        if h > 200 {
            if let url = Bundle(for: Payload.self).url(forResource:"emv", withExtension: "svg") {
                print(url)
                let emv = UIView(SVGURL: url) { (svgLayer) in
                    svgLayer.fillColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.00).cgColor
                    let scale = CGAffineTransform(scaleX:8, y:8)
                    DispatchQueue.main.async {
                        svgLayer.setAffineTransform(scale)
                    }
                }
                emv_icon_view.addSubview(emv)
            }
        } else if emv_icon_view.subviews.count > 0 {
            emv_icon_view.subviews[0].removeFromSuperview()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
            self.cardbg.layer.shadowOpacity = 0
            coordinator.animate(alongsideTransition: nil) { _ in
                if self.cardbg.drop_shadow {
                    self.cardbg.dropShadow()
                }
            }
    }

    @IBAction func clickPay(_ sender: Any) {
        
        var invalid:Int = 0
        
        let range = NSRange(location:0, length: self.card_number.text!.count );
        let isamex = amex.firstMatch(in: card_number.text!, options: [], range: range ) != nil
        
        if (!isamex && self.card_number.text?.count != 19) || (isamex && self.card_number.text?.count != 18) {
            self.cardnumber_tip.show(text: "Not enough digits", direction: .up, maxWidth: 200, in: self.card_number.superview!, from: self.card_number.frame)
            invalid+=1
        } else {
            self.cardnumber_tip.hide()
        }
        
        if self.expiry.text?.count != 7 {
            self.expiry_tip.show(text: "Not enough digits", direction: .up, maxWidth: 200, in: self.expiry.superview!, from: self.expiry.frame)
            invalid+=1
        } else {
            self.expiry_tip.hide()
        }
        
        if self.zipcode.text?.count != 5 {
            self.zipcode_tip.show(text: "Not enough digits", direction: .up, maxWidth: 200, in: self.zipcode.superview!, from: self.zipcode.frame)
            invalid+=1
        } else {
            self.zipcode_tip.hide()
        }
        
        if self.card_code.text?.count ?? 0 < 3 {
            self.card_code_tip.show(text: "Not enough digits", direction: .up, maxWidth: 200, in: self.card_code.superview!, from: self.card_code.frame)
            invalid+=1
        } else {
            self.card_code_tip.hide()
        }
        
        if invalid > 0 {
            print(invalid)
            return
        }
        
        let enc_cc = self.encrypt(self.card_number.text!);
        
        self.checkout.payment.payment_method = [
            "type": "card",
            "account_holder": self.cardholder_name.text,
            "card": [
                "card_number": enc_cc as Any?,
                "expiry": self.expiry.text,
                "card_code": self.card_code.text
            ],
            "billing_address": [
                "postal_code": self.zipcode.text
            ]
        ]
        
        self.showLoader()

        self.checkout.transactionReady({(payment:Payload.Transaction) in
            DispatchQueue.main.async {
                if payment.status == "processed" || payment.status == "stored" || payment.status == "authorized" {
                    self.checkout.transactionFinished(payment: payment)
                    if !Payload.manual_keyed_view_dismissal {
                        self.closeKeyedUI()
                    }
                } else {
                    self.dismiss(animated: true, completion: {
                        self.alert_visible = false
                        self.showDeclined(payment.obj["status_message"] as! String?)
                    })
                }
            }
        },{(error: Payload.PayloadError) in
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: {
                    self.alert_visible = false
                    if let req_error = error as? Payload.Errors.RequestError {
                        if req_error.error_type == "InvalidAttributes" {
                            var details = req_error.details
                            details = (details?["payment_method"] as? Dictionary<String,Any>)
                            
                            if details != nil {
                                if details?["card"] != nil {
                                    var card = details?["card"] as! Dictionary<String,Any>
                                    if card["card_number"] != nil {
                                        self.cardnumber_tip.show(text: card["card_number"] as! String, direction: .up, maxWidth: 200, in: self.card_number.superview!, from: self.card_number.frame)
                                    }
                                    if card["expiry"] != nil {
                                        self.expiry_tip.show(text: card["expiry"] as! String, direction: .up, maxWidth: 200, in: self.expiry.superview!, from: self.expiry.frame)
                                    }
                                    if card["card_code"] != nil {
                                        self.card_code_tip.show(text: card["card_code"] as! String, direction: .up, maxWidth: 200, in: self.card_code.superview!, from: self.card_code.frame)
                                    }
                                }
                                
                                if details?["billing_address"] != nil {
                                    var billing_address = details?["billing_address"] as! Dictionary<String,Any>
                                    if billing_address["postal_code"] != nil {
                                        self.zipcode_tip.show(text: billing_address["postal_code"] as! String, direction: .up, maxWidth: 200, in: self.zipcode.superview!, from: self.zipcode.frame)
                                    }
                                }
                            }
                        } else {
                            self.showAlert(str: req_error.error_description)
                        }
                    } else {
                        print(error)
                        self.showAlert(str:"Unknown Error")
                    }
                })
            }
        })
    }
    
    func closeKeyedUI() {
        self.dismiss(animated: true, completion: {
            if self.alert_visible {
                self.alert_visible = false
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    func encrypt(_ plain_text:String) -> String {
        
        let data = UserDefaults.standard.value(forKey: "public_key")
        if data == nil {
            return plain_text
        }
        
        let key = NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as! String
        
        let key_lines = (key as! String).components(separatedBy: "\n")
        let serverPublicKey = key_lines[1...(key_lines.count - 3)].joined(separator: "")
        
        let data2 = Data.init(base64Encoded: serverPublicKey)
        
        if data2 == nil {
            return plain_text
        }
        
        let keyDict:[NSObject:NSObject] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: NSNumber(value: 3072),
            kSecReturnPersistentRef: true as NSObject
        ]
        
        if #available(iOS 10.0, *) {
            let publickeysi = SecKeyCreateWithData(data2! as CFData, keyDict as CFDictionary, nil)
        
            //Encrypt a string with the public key
            let message = plain_text
            let blockSize = SecKeyGetBlockSize(publickeysi!)
            
            let error:UnsafeMutablePointer<Unmanaged<CFError>?>? = nil;
            let messageEncrypted = SecKeyCreateEncryptedData(publickeysi!, .rsaEncryptionOAEPSHA256, message.data(using:.utf8) as! CFData, error)
            
            if error != nil {
                print("Encryption Error!")
            }
            
            return (messageEncrypted as! Data).base64EncodedString()
            
        } else {
            // Fallback on earlier versions
            return plain_text
        }
    }

    @IBAction func clickBack(_ sender: Any) {
        self.closeKeyedUI()
        //dismiss(animated: true, completion: nil)
        self.checkout.cancelKeyed()
    }
    
    init(_ checkout:Payload.Checkout) {
        self.checkout = checkout
        self.cardnumber_tip = PopTip()
        self.expiry_tip = PopTip()
        self.card_code_tip = PopTip()
        self.zipcode_tip = PopTip()
        
        //let podBundle = Bundle(for: CheckoutViewController.classForCoder())

        //let bundleURL = podBundle.url(forResource: "Payload", withExtension: "bundle")
        
        
        let podBundle = Bundle(for:CheckoutViewController.self)
        let bundleURL = podBundle.url(forResource: "Payload", withExtension: "bundle")!
        let bundle = Bundle(url: bundleURL)
        
        super.init(nibName: "CheckoutViewController", bundle: bundle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showLoader() {
        let alert = UIAlertController(title: nil, message: "Processing...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
        
        self.alert_visible = true
    }
    
    func showDeclined(_ message:String?) {
        let alert = UIAlertController(title: nil, message: message ?? "Payment Declined", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment: "Default action"), style: .default, handler: {_ in
            
        }))
                
        self.present(alert, animated: true) {
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertControllerBackgroundTapped)))
        }
        
        self.alert_visible = true
    }
    
    func showAlert(str:String) {
        let alert = UIAlertController(title: nil, message: str, preferredStyle: .alert)
        
        self.present(alert, animated: true) {
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertControllerBackgroundTapped)))
        }
        
        self.alert_visible = true
    }
    
    @objc func alertControllerBackgroundTapped()
    {
        if self.alert_visible {
            self.dismiss(animated: true, completion: nil)
            self.alert_visible = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1

        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        //textField.resignFirstResponder()
        return true
    }


}

@objc public class PayloadKeyedView: UIView {
    
}

@objc public class PayloadTextField: UITextField {
    
    let padding = UIEdgeInsets(top: 8, left: 10, bottom: 10, right: 10);
    
    override public func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override public func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override public func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        for subview in subviews {
            if let label = subview as? UILabel {
                label.minimumScaleFactor = 0.3
                label.adjustsFontSizeToFitWidth = true
            }
        }
    }
    
    var placeholder_color = UIColor( white: 0, alpha: 0)
    
    @objc dynamic public var showPlaceholder: Bool {
        get {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            placeholder_color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return alpha != 0
        }
        set {
            if newValue {
                placeholder_color = UIColor( white: 0, alpha: 0.2)
            } else {
                placeholder_color = UIColor( white: 0, alpha: 0)
            }
            
            if placeholder != nil {
                attributedPlaceholder = NSAttributedString(string:placeholder!, attributes: [NSAttributedString.Key.foregroundColor: placeholder_color])
            }
        }
    }
}

@objc public class PayloadFormLabel: UILabel {
    
}

@objc public class PayloadTitle: UILabel {
    
    @objc dynamic public var titleText: String {
        get { return text ?? "" }
        set {
            text = newValue;
        }
    }
}

@objc public class PayloadCardContainer: UIView {
    @objc override dynamic public var isHidden: Bool {
        get { return layer.isHidden }
        set {
            layer.isHidden = newValue;
        }
    }
}

@objc public class PayloadCard: UIView {
    var drop_shadow = true
    @objc dynamic public var cornerRadius: CGFloat {
        get { return layer.cornerRadius }
        set { layer.cornerRadius = newValue }
    }
    
    @objc dynamic public var dropShadow: Bool {
        get { return layer.shadowOpacity != 0 }
        set {
            self.drop_shadow = newValue
            if newValue {
                layer.shadowOpacity = 0.5
            } else {
                layer.shadowOpacity = 0
            }
        }
    }
    
    
}

@objc public class PayloadCardLabel: UILabel {

}


@objc public class PayloadTotalLabel: UILabel {
    
}

@objc public class PayloadCardTextField: UILabel {

}

@objc public class PayloadBtn: UIButton {
    @objc dynamic public var cornerRadius: CGFloat {
        get { return layer.cornerRadius }
        set { layer.cornerRadius = newValue }
    }
    
    @objc dynamic public var titleLabelFont: UIFont? {
        get { return titleLabel?.font }
        set { titleLabel?.font = newValue }
    }
    
    @objc dynamic public var borderColor: UIColor? {
        get {
            if let cgColor = layer.borderColor {
                return UIColor(cgColor: cgColor)
            }
            return nil
        }
        set { layer.borderColor = newValue?.cgColor }
    }
    
    @objc dynamic public var borderWidth: CGFloat {
        get { return layer.borderWidth }
        set { layer.borderWidth = newValue }
    }
    
    @objc public override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state )
    }
}

@objc public class PayloadPayBtn: PayloadBtn {
}

@objc public class PayloadCancelBtn: PayloadBtn {
}

extension MaskedTextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1

        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}

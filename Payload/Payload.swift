//
//  Payload.swift
//  Payload
//
//  Copyright © 2020 Payload. All rights reserved.
//

import Foundation
import Network

@objc public protocol PayloadTransactionDelegate: AnyObject {
    @objc optional func card_present(_ payment:Payload.Payment)
    @objc optional func card_removed(_ payment:Payload.Payment)
    @objc optional func processing(_ payment:Payload.Payment)
    @objc optional func processed(_ payment:Payload.Payment)
    @objc optional func authorized(_ payment:Payload.Payment)
    @objc optional func declined(_ payment:Payload.Payment)
    @objc optional func canceled(_ payment:Payload.Payment)
    @objc optional func timeout(_ payment:Payload.Payment)
    @objc optional func error(_ payment:Payload.Payment,_ error:Payload.PayloadError)
    @objc optional func processing(trans:Payload.Transaction)
    @objc optional func processed(trans:Payload.Transaction)
    @objc optional func authorized(trans:Payload.Transaction)
    @objc optional func declined(trans:Payload.Transaction)
    @objc optional func canceled(trans:Payload.Transaction)
    @objc optional func timeout(trans:Payload.Transaction)
    @objc optional func error(trans:Payload.Transaction, error:Payload.PayloadError)
    @objc optional func card_present(trans:Payload.Transaction)
    @objc optional func card_removed(trans:Payload.Transaction)
    #if PL_DEBUG_EVT
    @objc optional func evt(_ evt:String)
    #endif
}

public enum TxDelegateEvt {
    case processing
    case processed
    case authorized
    case declined
    case canceled
    case timeout
    case error
    case card_present
    case card_removed
}

public protocol Object: AnyObject {
    var obj:Dictionary<String,Any> { get };
}

@objc public protocol PayloadCardReaderProto: AnyObject {
    @objc func beginTransaction(_ checkout:Payload.Checkout) throws
    @objc func clearPayment()
    @objc func transactionFinished(payment:Payload.Transaction)
}

@objc public class Payload: NSObject {
    static var _api_key:String = "";
    static var checkout:Checkout?;
    @objc public static var connected_reader:PayloadCardReaderProto?;

    @objc public static var api_key:String{
        get { return _api_key }
        set(value) {
            _api_key = value
        }
    }
    
    @objc public static var api_url:String = "https://api.payload.co";
    
    var cls:Object.Type;
    var filters:Dictionary<String,Any>;
    
    public init(_ cls:Object.Type) {
        self.cls = cls;
        self.filters = [:]
    }
    
    @objc public class PayloadError: NSObject, Error {
        @objc public let message: String
        
        @objc public init(_ message: String) {
            self.message = message
        }
    }
    
    @objc public class Errors: NSObject {
        @objc public class TransactionAlreadyStarted: PayloadError {
        }
        @objc public class CardReaderAlreadyConnected: PayloadError {
        }
        @objc public class ErrorReadingCard: PayloadError {
        }
        @objc public class TransactionCurrentlyProcessing: PayloadError {
        }
        @objc public class UseChipReader: PayloadError {
        }
        @objc public class BatteryTooLow: PayloadError {
        }
        @objc public class UnknownRequestError: PayloadError {}
        @objc public class CardReaderNotConnected: PayloadError {
        }
        @objc public class LostConnectivity: PayloadError {}
        @objc public class RequestError: PayloadError {
            @objc var details:Dictionary<String, Any>?;
            @objc var error_description:String;
            @objc var error_type:String;
            @objc var req:Payload
            init(_ error: Dictionary<String, Any>, req: Payload) {
                self.error_type = error["error_type"] as! String
                self.error_description = error["error_description"] as! String
                self.req = req
                if error["details"] != nil {
                    self.details = error["details"] as? Dictionary<String, Any>
                }
                super.init(self.error_description)
            }
        }
    }
    
    /******* OPTIONS ******/
    @objc public static var manual_keyed_view_dismissal = false;
    @objc public static var keyed_view_modal_style = UIModalPresentationStyle.pageSheet;
    /**********************/
    
    @objc public class Config: NSObject {
        @objc public var manual_keyed_view_dismissal = false;
        @objc public var keyed_view_modal_style:UIModalPresentationStyle = .pageSheet;
        
        @objc public init(
            manual_keyed_view_dismissal:Bool = false,
            keyed_view_modal_style:UIModalPresentationStyle = .pageSheet
        ){
            self.manual_keyed_view_dismissal = manual_keyed_view_dismissal
            self.keyed_view_modal_style = keyed_view_modal_style
        }
    }

    static var _config:Config?
    @objc public static var config: Config? {
        get { return _config }
        set(val) {
            if val != nil {
                Payload.manual_keyed_view_dismissal = val!.manual_keyed_view_dismissal
                Payload.keyed_view_modal_style = val!.keyed_view_modal_style
            }
            _config = val
        }
        
    }
    
    public func request(method:String, id:String?=nil, url:String?=nil, obj:Dictionary<String,Any>? = nil, completion: @escaping (_ obj: Any) -> Void, error_cb: ((_ error: Payload.PayloadError) -> Void)?=nil) {
        let auth = String(format: "%@:", Payload.api_key)
        let loginData = auth.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        
        // create the request
        var url_str = Payload.api_url
        if url != nil {
            url_str += url!
        } else if self.cls.endpoint == nil {
            url_str += "/\(self.cls.object_name)s"
        } else {
            url_str += self.cls.endpoint!
        }

        if let id = id {
            url_str = "\(url_str)/\(id)"
        }
        
        if self.filters.count > 0 {
            url_str += "\(self.filters.queryString)"
        }
        
        let url = URL(string: url_str)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        if ( obj != nil ) {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: obj as Any, options: .prettyPrinted)
                
                request.httpBody = jsonData
            } catch {
                print(error)
            }
            
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            guard let data = data else {
                error_cb?(Payload.Errors.UnknownRequestError("Unknown request error"))
                return
            }
            do {
                let status_code:Int? = (response as? HTTPURLResponse)?.statusCode
                
                //print(String(data: data, encoding: .utf8)!)
                
                let obj = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String,Any>
                if status_code == 200 {
                    if obj!["object"] as? String == "list" {
                        completion((obj!["values"] as! [Dictionary<String, Any>]).map{ self.cls.init($0) });
                    } else {
                        completion(self.cls.init(obj!));
                    }
                } else if error_cb != nil {
                    error_cb!(Payload.Errors.RequestError(obj!, req:self))
                }
                
            } catch {
                error_cb?(Payload.Errors.UnknownRequestError("Unknown request error"))
            }
        })
        
        task.resume()
    }
    
    @objc public func filter_by(_ filters:Dictionary<String,Any>) -> Payload {
        self.filters = self.filters.merging(filters) { (_, new) in new }
        return self
    }
    
    @objc public func update(_ id:String, updates:Dictionary<String,Any>, _ completion: @escaping (_ obj: Any) -> Void,_ error_cb: ((_ error: Payload.PayloadError) -> Void)?=nil) {
        self.request(method: "PUT", id: id, obj: updates, completion: completion, error_cb: error_cb)
    }
    
    @objc public class func create(_ obj:Object,_ completion: @escaping (_ obj: Any) -> Void,_ error_cb: ((_ error: Payload.PayloadError) -> Void)?=nil) {
        let req = Payload(type(of: obj))
        req.request(method: "POST", obj: obj.obj, completion: completion, error_cb: error_cb)
    }
    
    @objc public func create(_ obj:Object,_ completion: @escaping (_ obj: Any) -> Void,_ error_cb: ((_ error: Payload.PayloadError) -> Void)?=nil) {
        //let req = Payload(type(of: obj))
        self.request(method: "POST", obj: obj.obj, completion: completion, error_cb: error_cb)
    }
    
    @objc public func select(_ fields:[String]) -> Payload {
        self.filters["fields"] = fields.joined(separator: ",")
        return self
    }
    
    @objc public class func all(_ req:Payload,_ completion: @escaping (_ obj: Any) -> Void, error_cb: ((_ error: Payload.PayloadError) -> Void)?=nil) {
        if req.cls.object_type != nil {
            req.filters["type"] = req.cls.object_type
        }
        req.request(method: "GET", completion: completion, error_cb: error_cb)
    }
    
    @objc public class func get(_ obj:Object,_ completion: @escaping (_ obj: Any) -> Void, error_cb: ((_ error: Payload.PayloadError) -> Void)?=nil) {
        let req = Payload(type(of: obj))
        req.request(method: "GET", id: obj.id, completion: completion, error_cb: error_cb)
    }
    
    @objc public static func beginTransaction(_ payment:Transaction, delegate: PayloadTransactionDelegate) throws {
        let checkout = Checkout(payment, delegate: delegate)
    }
    
    @objc public static func cancelTransaction() throws {
        try Payload.checkout?.cancelTransaction()
    }
    #if PL_DEBUG_EVT
    @objc public static func throwErrorEvent() {
        Payload.checkout?.reader?.manager.evt("[Throw Test Error] throwing error in 2 seconds...")
        DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: {
            Payload.checkout?.reader?.manager.evt("[Throw Test Error] throwing error now")
        
            do {
                try? Payload.checkout?.transactionFinished(payment: Payload.checkout!.payment, error: Payload.PayloadError("Test error event"))
            } catch {
                
            }
        })
    }
    #endif
    @objc public class Object:NSObject {
        class var object_name:String { return "" }
        class var object_type:String? { return nil }
        class var endpoint:String? { return nil }
        var obj:Dictionary<String,Any>;
        
        @objc public var id: String? {
            get { return self.obj["id"] as? String }
            set(val) { self.obj["id"] = val } }
        
        @objc public subscript(member: String) -> Any? {
            get { return obj[member] as? NSObject }
            set(value) { obj[member] = value }
        }
        
        @objc public required init(_ obj : Dictionary<String,Any>){
            self.obj = obj;
            if type(of:self).object_type != nil {
                self.obj["type"] =  type(of:self).object_type
            }
        }
        
        @objc public class func filter_by(_ filters : Dictionary<String,Any>) -> Payload {
            let req = Payload(self)
            return req.filter_by(filters)
        }
        
        @objc public class func select() -> Payload {
            return Payload(self)
        }
        
        @objc public func update(_ updates:Dictionary<String,Any>, _ completion: @escaping (_ obj: Any) -> Void, error_cb: ((_ error: Payload.PayloadError) -> Void)?=nil) {
            let req = Payload(type(of: self))
            req.update(self.id!, updates: updates, completion, error_cb)
        }
        
        @objc public func delete(_ completion: @escaping (_ obj: Any) -> Void, error_cb: ((_ error: Payload.PayloadError) -> Void)?=nil) {
            let req = Payload(type(of: self))
            req.request(method: "DELETE", id: self.id!, completion: completion, error_cb: error_cb)
        }
    }
    
    @objc public class Transaction: Object {
        override class var object_name:String { return "transaction" }
        public var amount: Float? {
            get {
                if let amt = self.obj["amount"] as? Float { return amt }
                if let amt = self.obj["amount"] as? Double { return Float(amt) }
                if let amt = self.obj["amount"] as? Int { return Float(amt) }
                if let amt = self.obj["amount"] as? String { return Float(amt) }
                return nil
            } set(val) {
                self.obj["amount"] = val
            }
        }
        @objc public var status: String? {
            get { return self.obj["status"] as? String }
            set(val) { self.obj["status"] = val } }
        @objc public var source: String? {
            get { return self.obj["source"] as? String }
            set(val) { self.obj["source"] = val } }
        @objc public var payment_method: Dictionary<String,Any>? {
            get { return self.obj["payment_method"] as? Dictionary<String,Any> }
            set(val) { self.obj["payment_method"] = val } }
        @objc public var auth_code: String? {
            get { return self.obj["auth_code"] as? String }
            set(val) { self.obj["auth_code"] = val } }
    }
    
    @objc public class Payment: Transaction {
        override class var object_type:String { return "payment" }
        
        @objc public func refund() -> Refund {
            return Refund([
                "amount": self.amount,
                "ledger": [["assoc_transaction_id": self.id]]
            ])
        }
        
        @objc public func void(_ completion: @escaping (_ obj: Any) -> Void, error_cb: ((_ error: Payload.PayloadError) -> Void)?=nil) {
            if self.status == "stored" {
                self.status = "voided"
                completion(self)
            } else {
                self.update(["status": "voided"], completion, error_cb: error_cb)
            }
        }
    }
    
    @objc public class Refund: Transaction {
        override class var object_type:String { return "refund" }
    }
    
    @objc public class PaymentMethod: Object {
        override class var object_name:String { return "payment_method" }
    }
    
    @objc public class Reader:Object {
        override class var object_name:String { return "reader" }
    }
    
    @objc public class Ledger:Object {
        override class var object_name:String { return "transaction_ledger" }
    }
    
    @objc public class ProcessingAccount:Object {
        override class var object_name:String { return "account" }
        override class var object_type:String { return "processing" }
    }
    
    @objc public class Customer:Object {
        override class var object_name:String { return "account" }
        override class var object_type:String { return "customer" }
    }
    
    public class EncryptionKey:Object {
        override class var object_name:String { return "encryption_key" }
        override class var endpoint:String { return "/encryption_key" }
    }
    
    @objc public class func dismissKeyedView() {
        Payload.checkout?.keyed_view?.closeKeyedUI()
    }
    
    @objc public class Checkout:NSObject {
        var tx_delegate:PayloadTransactionDelegate;
        var reader:PayloadCardReaderProto?;
        @objc public var payment:Transaction;
        var is_processing:Bool = false;
        var payment_started:Bool = false;
        var keyed_view:CheckoutViewController?;
        
        @objc public init(_ payment:Transaction, reader:PayloadCardReaderProto?=nil, delegate:PayloadTransactionDelegate) {
            
            self.payment = payment
            self.reader = reader
            if self.reader == nil {
                self.reader = Payload.connected_reader
            }
            
            self.tx_delegate = delegate
            super.init()
            Payload.checkout = self
            
            do {
                try self.beginTransaction()
            } catch let error as Payload.Errors.TransactionAlreadyStarted {
                //
            } catch{}
        }
        
        @objc public func isTransactionStarted() -> Bool {
            return self.payment_started
        }
        
        @objc public func isTransactionProcessing() -> Bool {
            return self.is_processing
        }
        
        @objc public func beginTransaction() throws {
            if self.payment_started {
                throw Payload.Errors.TransactionAlreadyStarted("Payment already started, cancel first")
            }
            
            self.payment_started = true
            
            if payment["type"] as! String == "refund" {
                if payment["ledger"] != nil {
                    self.transactionReady()
                    return
                }
            }
            
            if payment.source == nil && self.reader == nil {
                payment.source = "keyed"
            }
            
            if ( payment.source != "keyed" ) {
                if self.reader == nil {
                    throw Payload.Errors.CardReaderNotConnected("Card reader not connected")
                }
                try self.reader?.beginTransaction(self)
            } else {
                self.startKeyed()
            }
        }
        
        @objc public func transactionReady(_ completion:((_ payment:Payload.Transaction)->Void)? = nil, _ error_cb:((_ error:PayloadError)->Void)? = nil) {
            self.is_processing = true
            
            self.delegateEvt(TxDelegateEvt.processing, self.payment)
            
            let orig_payment = self.payment
            
            Payload(type(of:self.payment))
                .select(["*", "aid", "auth_code"])
                .create(self.payment, {(obj: Any) in
                    self.is_processing = false
                    let payment = (obj as? Payload.Transaction)!
                    
                    self.handleTransactionResult(payment: payment, orig_payment: orig_payment, completion: completion)

                }, {(error: Payload.PayloadError) in
                    self.is_processing = false
                    
                    if ( self.payment !== orig_payment) {
                        return
                    }
                    
                    if (error is Payload.Errors.RequestError) {
                        let req_error = error as! Payload.Errors.RequestError;
                        if req_error.error_type == "TransactionDeclined" {
                            let payment = req_error.req.cls.init(req_error.details!) as! Payload.Transaction
                            self.handleTransactionResult(payment: payment, orig_payment: orig_payment, completion: completion)
                            return
                            
                        }
                    }
                    
                    if error_cb != nil {
                        error_cb!(error)
                    } else {
                        self.transactionFinished(payment: self.payment, error: error)
                    }
                })

        }
        
        func handleTransactionResult(payment:Payload.Transaction, orig_payment:Payload.Transaction, completion:((_ payment:Payload.Transaction)->Void)?) {
            if ( self.payment !== orig_payment) {
                return
            }
            
            if payment.source != "keyed" || payment.status != "declined" {
                self.payment = payment
            }
            
            if completion != nil {
                completion!(payment)
            } else {
                if self.reader != nil {
                    self.reader?.transactionFinished(payment: payment)
                } else {
                    self.transactionFinished(payment: payment)
                }
            }
        }
        
        @objc public func transactionFinished(payment:Transaction, error: PayloadError?=nil) {
            self.debug("[transactionFinished] id:\(payment.id ?? "no id") status:\(payment.status ?? "no status") error: \(error != nil)")
            if error == nil {
                if payment.status == "processed" {
                    self.delegateEvt(TxDelegateEvt.processed, payment)
                }
                
                if payment.status == "authorized" {
                    self.delegateEvt(TxDelegateEvt.authorized, payment)
                }
                
                if payment.status == "declined" {
                    self.delegateEvt(TxDelegateEvt.declined, payment)
                }
            } else {
                self.delegateEvt(TxDelegateEvt.error, payment, error!)
            }

            self.clearPayment()
        }
        
        @objc public func transactionTimeout() {
            if self.payment.id == nil {
                self.delegateEvt(TxDelegateEvt.timeout, self.payment)
            }
            
            self.clearPayment()
        }
        
        func clearPayment() {
            if ( self.keyed_view == nil || !Payload.manual_keyed_view_dismissal ) {
                Payload.checkout = nil;
            }
            self.reader?.clearPayment()
        }
        
        func startKeyed() {
            self.keyed_view = CheckoutViewController(self)
            
            var view:UIViewController?=nil;
            
            if var top_view = UIApplication.shared.keyWindow?.rootViewController {
                while let presented_view = top_view.presentedViewController {
                    top_view = presented_view
                }
                view = top_view
            } else {
                view = self.tx_delegate as? UIViewController
            }
            
            if view != nil {
                let nav = UINavigationController()
                nav.setValue(PayloadNavigationBar(), forKeyPath: "navigationBar")
                nav.viewControllers = [self.keyed_view!]
                self.keyed_view!.set_modal_style(Payload.keyed_view_modal_style)
                view!.present(nav, animated: true, completion: nil)
            }
        }
        
        func cancelKeyed() {
            self.delegateEvt(TxDelegateEvt.canceled, self.payment)
            
            self.clearPayment()
        }
        
        func cancelTransaction(force:Bool=false) throws {
            if ( !force && self.isTransactionProcessing() ) {
                throw Errors.TransactionCurrentlyProcessing("A transaction is processing, to override use force:true")
            }
            
            self.delegateEvt(TxDelegateEvt.canceled, self.payment)
            Payload.dismissKeyedView()
            self.clearPayment()
        }
        
        func debug(_ str:String) {
            #if PL_DEBUG_EVT
            NSLog(str)
            DispatchQueue.main.async {
                self.tx_delegate.evt?(str)
            }
            #endif
        }

        public func delegateEvt(_ evt:TxDelegateEvt,_ args:Any...) {
            self.debug("[TxDelegateEvt] \(evt)")

            let trans = args[0] as! Payload.Transaction
            DispatchQueue.main.async {
                switch(evt){
                case .processing:
                    self.debug("[TxDelegateEvt] fire:processing exists:\(self.tx_delegate.processing != nil)")

                    self.tx_delegate.processing?(trans: trans)
                    if trans["type"] as? String == "payment" {
                        self.tx_delegate.processing?(trans as! Payload.Payment)
                    }
                    break
                case .processed:
                    self.debug("[TxDelegateEvt] fire:processed exists:\(self.tx_delegate.processed != nil)")
                    
                    self.tx_delegate.processed?(trans: trans)
                    if trans["type"] as? String == "payment" {
                        self.tx_delegate.processed?(trans as! Payload.Payment)
                    }
                    break
                case .authorized:
                    self.debug("[TxDelegateEvt] fire:authorized exists:\(self.tx_delegate.authorized != nil)")
                    
                    self.tx_delegate.authorized?(trans: trans)
                    if trans["type"] as? String == "payment" {
                        self.tx_delegate.authorized?(trans as! Payload.Payment)
                    }
                    break
                case .declined:
                    self.debug("[TxDelegateEvt] fire:declined exists:\(self.tx_delegate.declined != nil)")
                    
                    self.tx_delegate.declined?(trans: trans)
                    if trans["type"] as? String == "payment" {
                        self.tx_delegate.declined?(trans as! Payload.Payment)
                    }
                    break
                case .canceled:
                    self.debug("[TxDelegateEvt] fire:canceled exists:\(self.tx_delegate.canceled != nil)")
                    
                    self.tx_delegate.canceled?(trans: trans)
                    if trans["type"] as? String == "payment" {
                        self.tx_delegate.canceled?(trans as! Payload.Payment)
                    }
                    break
                case .timeout:
                    self.debug("[TxDelegateEvt] fire:timeout exists:\(self.tx_delegate.timeout != nil)")
                    
                    self.tx_delegate.timeout?(trans: trans)
                    if trans["type"] as? String == "payment" {
                        self.tx_delegate.timeout?(trans as! Payload.Payment)
                    }
                    break
                case .error:
                    self.debug("[TxDelegateEvt] fire:error exists:\(self.tx_delegate.error != nil)")
                    
                    self.tx_delegate.error?(trans: trans, error: args[1] as! Payload.PayloadError)
                    if trans["type"] as? String == "payment" {
                        self.tx_delegate.error?(trans as! Payload.Payment, args[1] as! Payload.PayloadError)
                    }
                    break
                case .card_present:
                    self.debug("[TxDelegateEvt] fire:card_present exists:\(self.tx_delegate.card_present != nil)")
                    
                    self.tx_delegate.card_present?(trans: trans)
                    if trans["type"] as? String == "payment" {
                        self.tx_delegate.card_present?(trans as! Payload.Payment)
                    }
                    break
                case .card_removed:
                    self.debug("[TxDelegateEvt] fire:card_removed exists:\(self.tx_delegate.card_removed != nil)")
                    
                    self.tx_delegate.card_removed?(trans: trans)
                    if trans["type"] as? String == "payment" {
                        self.tx_delegate.card_removed?(trans as! Payload.Payment)
                    }
                    break
                default:
                    self.debug("[TxDelegateEvt] UNKNOWN \(evt)")
                }
            }
        }
    }
}

@objc public class PayloadNavigationBar: UINavigationBar {
}

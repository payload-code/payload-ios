
extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

extension String {
    func dataFromHexString() -> Data? {
        guard let chars = cString(using: String.Encoding.utf8) else { return nil}
        let length = self.count
        
        var data = Data(capacity: length/2)
        var byteChars: [CChar] = [0, 0, 0]
        var wholeByte: UInt8 = 0
        
        for i in stride(from:0, to: length, by: 2) {
            byteChars[0] = chars[i]
            byteChars[1] = chars[i + 1]
            wholeByte = UInt8(strtoul(byteChars, nil, 16))
            data.append(&wholeByte, count: 1)
        }
        
        return data
    }
    
    public var stringFromHexString:String{
        
        let pattern = "(0x)?([0-9a-f]{2})"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let nsString = self as NSString
        let matches = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        let characters = matches.map {
            Character(UnicodeScalar(UInt32(nsString.substring(with: $0.range(at: 2)), radix: 16)!)!)
        }
        return String(characters)
        
    }
}

extension Data {
    
    init<T>(fromArray values: [T]) {
        var values = values
        self.init(buffer: UnsafeBufferPointer(start: &values, count: values.count))
    }
    
    func toArray<T>(type: T.Type) -> [T] {
        return self.withUnsafeBytes {
            [T](UnsafeBufferPointer(start: $0, count: self.count/MemoryLayout<T>.stride))
        }
    }
    
    /// Return hexadecimal string representation of NSData bytes
    
    var hexadecimalString: String {
        return self.reduce("") { $0 + String(format: "%02x", $1) }
    }
    
    func toInterger<T>(withData data: NSData, withStartRange startRange: Int, withSizeRange endRange: Int) -> T {
        var d : T = 0 as! T
        (self as NSData).getBytes(&d, range: NSRange(location: startRange, length: endRange))
        return d
    }
    
}

extension Dictionary {
    var queryString: String {
        var components = URLComponents()
        components.queryItems = self.map { item in
            URLQueryItem(name: item.key as! String, value: item.value as? String)
        }
        return components.url!.absoluteString
    }
}

extension CGRect{
    init(_ x:CGFloat,_ y:CGFloat,_ width:CGFloat,_ height:CGFloat) {
        self.init(x:x,y:y,width:width,height:height)
    }
    
}

extension UIView {
    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = 5
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
}

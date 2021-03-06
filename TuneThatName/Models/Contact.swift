import Foundation

public class Contact: NSObject, NSCoding {
    
    public let id: Int32
    public let firstName: String?
    public let lastName: String?
    public let fullName: String!
    public override var description: String {
        return "Contact:[id:\(id), fullName:\(fullName), searchString:\(searchString)]"
    }
    public var searchString: String {
        let empty = ""
        var result = empty
        let first = firstName?.trim() ?? empty
        if !first.isEmpty {
            result = first
        } else {
            let last = lastName?.trim() ?? empty
            if !last.isEmpty {
                result = last
            } else {
                let full = fullName?.trim() ?? empty
                if !full.isEmpty {
                    result = full
                }
            }
        }
        
        return result
    }
    
    public override var hashValue: Int {
        return "\(id),\(firstName),\(lastName),\(fullName)".hashValue
    }
    
    public init(id: Int32, firstName: String?, lastName: String?, fullName: String! = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.fullName = fullName != nil ? fullName : ((firstName ?? "") + " " + (lastName ?? "")).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    public required convenience init(coder decoder: NSCoder) {
        let id = decoder.decodeInt32ForKey("id")
        let firstName = decoder.decodeObjectForKey("firstName") as? String?
        let lastName = decoder.decodeObjectForKey("lastName") as? String?
        let fullName = decoder.decodeObjectForKey("fullName") as? String
        self.init(id: id, firstName: firstName!, lastName: lastName!, fullName: fullName)
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeInt32(self.id, forKey: "id")
        coder.encodeObject(self.firstName, forKey: "firstName")
        coder.encodeObject(self.lastName, forKey: "lastName")
        coder.encodeObject(self.fullName, forKey: "fullName")
    }
    
    override public func isEqual(object: AnyObject?) -> Bool {
        let equal: Bool
        if let contact = object as? Contact {
            equal = self == contact
        } else {
            equal = false
        }
        
        return equal
    }
}

public func ==(x: Contact, y: Contact) -> Bool {
    return x.id == y.id && x.firstName == y.firstName && x.lastName == y.lastName && x.fullName == y.fullName
}
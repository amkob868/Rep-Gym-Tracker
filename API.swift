//  This file was automatically generated and should not be edited.

#if canImport(AWSAPIPlugin)
import Foundation

public protocol GraphQLInputValue {
}

public struct GraphQLVariable {
  let name: String
  
  public init(_ name: String) {
    self.name = name
  }
}

extension GraphQLVariable: GraphQLInputValue {
}

extension JSONEncodable {
  public func evaluate(with variables: [String: JSONEncodable]?) throws -> Any {
    return jsonValue
  }
}

public typealias GraphQLMap = [String: JSONEncodable?]

extension Dictionary where Key == String, Value == JSONEncodable? {
  public var withNilValuesRemoved: Dictionary<String, JSONEncodable> {
    var filtered = Dictionary<String, JSONEncodable>(minimumCapacity: count)
    for (key, value) in self {
      if value != nil {
        filtered[key] = value
      }
    }
    return filtered
  }
}

public protocol GraphQLMapConvertible: JSONEncodable {
  var graphQLMap: GraphQLMap { get }
}

public extension GraphQLMapConvertible {
  var jsonValue: Any {
    return graphQLMap.withNilValuesRemoved.jsonValue
  }
}

public typealias GraphQLID = String

public protocol APISwiftGraphQLOperation: AnyObject {
  
  static var operationString: String { get }
  static var requestString: String { get }
  static var operationIdentifier: String? { get }
  
  var variables: GraphQLMap? { get }
  
  associatedtype Data: GraphQLSelectionSet
}

public extension APISwiftGraphQLOperation {
  static var requestString: String {
    return operationString
  }

  static var operationIdentifier: String? {
    return nil
  }

  var variables: GraphQLMap? {
    return nil
  }
}

public protocol GraphQLQuery: APISwiftGraphQLOperation {}

public protocol GraphQLMutation: APISwiftGraphQLOperation {}

public protocol GraphQLSubscription: APISwiftGraphQLOperation {}

public protocol GraphQLFragment: GraphQLSelectionSet {
  static var possibleTypes: [String] { get }
}

public typealias Snapshot = [String: Any?]

public protocol GraphQLSelectionSet: Decodable {
  static var selections: [GraphQLSelection] { get }
  
  var snapshot: Snapshot { get }
  init(snapshot: Snapshot)
}

extension GraphQLSelectionSet {
    public init(from decoder: Decoder) throws {
        if let jsonObject = try? APISwiftJSONValue(from: decoder) {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(jsonObject)
            let decodedDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
            let optionalDictionary = decodedDictionary.mapValues { $0 as Any? }

            self.init(snapshot: optionalDictionary)
        } else {
            self.init(snapshot: [:])
        }
    }
}

enum APISwiftJSONValue: Codable {
    case array([APISwiftJSONValue])
    case boolean(Bool)
    case number(Double)
    case object([String: APISwiftJSONValue])
    case string(String)
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode([String: APISwiftJSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([APISwiftJSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            self = .null
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .array(let value):
            try container.encode(value)
        case .boolean(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

public protocol GraphQLSelection {
}

public struct GraphQLField: GraphQLSelection {
  let name: String
  let alias: String?
  let arguments: [String: GraphQLInputValue]?
  
  var responseKey: String {
    return alias ?? name
  }
  
  let type: GraphQLOutputType
  
  public init(_ name: String, alias: String? = nil, arguments: [String: GraphQLInputValue]? = nil, type: GraphQLOutputType) {
    self.name = name
    self.alias = alias
    
    self.arguments = arguments
    
    self.type = type
  }
}

public indirect enum GraphQLOutputType {
  case scalar(JSONDecodable.Type)
  case object([GraphQLSelection])
  case nonNull(GraphQLOutputType)
  case list(GraphQLOutputType)
  
  var namedType: GraphQLOutputType {
    switch self {
    case .nonNull(let innerType), .list(let innerType):
      return innerType.namedType
    case .scalar, .object:
      return self
    }
  }
}

public struct GraphQLBooleanCondition: GraphQLSelection {
  let variableName: String
  let inverted: Bool
  let selections: [GraphQLSelection]
  
  public init(variableName: String, inverted: Bool, selections: [GraphQLSelection]) {
    self.variableName = variableName
    self.inverted = inverted;
    self.selections = selections;
  }
}

public struct GraphQLTypeCondition: GraphQLSelection {
  let possibleTypes: [String]
  let selections: [GraphQLSelection]
  
  public init(possibleTypes: [String], selections: [GraphQLSelection]) {
    self.possibleTypes = possibleTypes
    self.selections = selections;
  }
}

public struct GraphQLFragmentSpread: GraphQLSelection {
  let fragment: GraphQLFragment.Type
  
  public init(_ fragment: GraphQLFragment.Type) {
    self.fragment = fragment
  }
}

public struct GraphQLTypeCase: GraphQLSelection {
  let variants: [String: [GraphQLSelection]]
  let `default`: [GraphQLSelection]
  
  public init(variants: [String: [GraphQLSelection]], default: [GraphQLSelection]) {
    self.variants = variants
    self.default = `default`;
  }
}

public typealias JSONObject = [String: Any]

public protocol JSONDecodable {
  init(jsonValue value: Any) throws
}

public protocol JSONEncodable: GraphQLInputValue {
  var jsonValue: Any { get }
}

public enum JSONDecodingError: Error, LocalizedError {
  case missingValue
  case nullValue
  case wrongType
  case couldNotConvert(value: Any, to: Any.Type)
  
  public var errorDescription: String? {
    switch self {
    case .missingValue:
      return "Missing value"
    case .nullValue:
      return "Unexpected null value"
    case .wrongType:
      return "Wrong type"
    case .couldNotConvert(let value, let expectedType):
      return "Could not convert \"\(value)\" to \(expectedType)"
    }
  }
}

extension String: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let string = value as? String else {
      throw JSONDecodingError.couldNotConvert(value: value, to: String.self)
    }
    self = string
  }

  public var jsonValue: Any {
    return self
  }
}

extension Int: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let number = value as? NSNumber else {
      throw JSONDecodingError.couldNotConvert(value: value, to: Int.self)
    }
    self = number.intValue
  }

  public var jsonValue: Any {
    return self
  }
}

extension Float: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let number = value as? NSNumber else {
      throw JSONDecodingError.couldNotConvert(value: value, to: Float.self)
    }
    self = number.floatValue
  }

  public var jsonValue: Any {
    return self
  }
}

extension Double: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let number = value as? NSNumber else {
      throw JSONDecodingError.couldNotConvert(value: value, to: Double.self)
    }
    self = number.doubleValue
  }

  public var jsonValue: Any {
    return self
  }
}

extension Bool: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let bool = value as? Bool else {
        throw JSONDecodingError.couldNotConvert(value: value, to: Bool.self)
    }
    self = bool
  }

  public var jsonValue: Any {
    return self
  }
}

extension RawRepresentable where RawValue: JSONDecodable {
  public init(jsonValue value: Any) throws {
    let rawValue = try RawValue(jsonValue: value)
    if let tempSelf = Self(rawValue: rawValue) {
      self = tempSelf
    } else {
      throw JSONDecodingError.couldNotConvert(value: value, to: Self.self)
    }
  }
}

extension RawRepresentable where RawValue: JSONEncodable {
  public var jsonValue: Any {
    return rawValue.jsonValue
  }
}

extension Optional where Wrapped: JSONDecodable {
  public init(jsonValue value: Any) throws {
    if value is NSNull {
      self = .none
    } else {
      self = .some(try Wrapped(jsonValue: value))
    }
  }
}

extension Optional: JSONEncodable {
  public var jsonValue: Any {
    switch self {
    case .none:
      return NSNull()
    case .some(let wrapped as JSONEncodable):
      return wrapped.jsonValue
    default:
      fatalError("Optional is only JSONEncodable if Wrapped is")
    }
  }
}

extension Dictionary: JSONEncodable {
  public var jsonValue: Any {
    return jsonObject
  }
  
  public var jsonObject: JSONObject {
    var jsonObject = JSONObject(minimumCapacity: count)
    for (key, value) in self {
      if case let (key as String, value as JSONEncodable) = (key, value) {
        jsonObject[key] = value.jsonValue
      } else {
        fatalError("Dictionary is only JSONEncodable if Value is (and if Key is String)")
      }
    }
    return jsonObject
  }
}

extension Array: JSONEncodable {
  public var jsonValue: Any {
    return map() { element -> (Any) in
      if case let element as JSONEncodable = element {
        return element.jsonValue
      } else {
        fatalError("Array is only JSONEncodable if Element is")
      }
    }
  }
}

extension URL: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let string = value as? String else {
      throw JSONDecodingError.couldNotConvert(value: value, to: URL.self)
    }
    self.init(string: string)!
  }

  public var jsonValue: Any {
    return self.absoluteString
  }
}

extension Dictionary {
  static func += (lhs: inout Dictionary, rhs: Dictionary) {
    lhs.merge(rhs) { (_, new) in new }
  }
}

#elseif canImport(AWSAppSync)
import AWSAppSync
#endif

public struct CreateUserProfileInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID? = nil, userName: String, goal: String, height: Int, weight: Int, desiredWeight: Int, streak: Int) {
    graphQLMap = ["id": id, "userName": userName, "goal": goal, "height": height, "weight": weight, "desiredWeight": desiredWeight, "streak": streak]
  }

  public var id: GraphQLID? {
    get {
      return graphQLMap["id"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var userName: String {
    get {
      return graphQLMap["userName"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userName")
    }
  }

  public var goal: String {
    get {
      return graphQLMap["goal"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "goal")
    }
  }

  public var height: Int {
    get {
      return graphQLMap["height"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "height")
    }
  }

  public var weight: Int {
    get {
      return graphQLMap["weight"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "weight")
    }
  }

  public var desiredWeight: Int {
    get {
      return graphQLMap["desiredWeight"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "desiredWeight")
    }
  }

  public var streak: Int {
    get {
      return graphQLMap["streak"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "streak")
    }
  }
}

public struct ModelUserProfileConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(userName: ModelStringInput? = nil, goal: ModelStringInput? = nil, height: ModelIntInput? = nil, weight: ModelIntInput? = nil, desiredWeight: ModelIntInput? = nil, streak: ModelIntInput? = nil, and: [ModelUserProfileConditionInput?]? = nil, or: [ModelUserProfileConditionInput?]? = nil, not: ModelUserProfileConditionInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["userName": userName, "goal": goal, "height": height, "weight": weight, "desiredWeight": desiredWeight, "streak": streak, "and": and, "or": or, "not": not, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner]
  }

  public var userName: ModelStringInput? {
    get {
      return graphQLMap["userName"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userName")
    }
  }

  public var goal: ModelStringInput? {
    get {
      return graphQLMap["goal"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "goal")
    }
  }

  public var height: ModelIntInput? {
    get {
      return graphQLMap["height"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "height")
    }
  }

  public var weight: ModelIntInput? {
    get {
      return graphQLMap["weight"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "weight")
    }
  }

  public var desiredWeight: ModelIntInput? {
    get {
      return graphQLMap["desiredWeight"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "desiredWeight")
    }
  }

  public var streak: ModelIntInput? {
    get {
      return graphQLMap["streak"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "streak")
    }
  }

  public var and: [ModelUserProfileConditionInput?]? {
    get {
      return graphQLMap["and"] as! [ModelUserProfileConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelUserProfileConditionInput?]? {
    get {
      return graphQLMap["or"] as! [ModelUserProfileConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelUserProfileConditionInput? {
    get {
      return graphQLMap["not"] as! ModelUserProfileConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct ModelStringInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: String? = nil, eq: String? = nil, le: String? = nil, lt: String? = nil, ge: String? = nil, gt: String? = nil, contains: String? = nil, notContains: String? = nil, between: [String?]? = nil, beginsWith: String? = nil, attributeExists: Bool? = nil, attributeType: ModelAttributeTypes? = nil, size: ModelSizeInput? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith, "attributeExists": attributeExists, "attributeType": attributeType, "size": size]
  }

  public var ne: String? {
    get {
      return graphQLMap["ne"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: String? {
    get {
      return graphQLMap["eq"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: String? {
    get {
      return graphQLMap["le"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: String? {
    get {
      return graphQLMap["lt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: String? {
    get {
      return graphQLMap["ge"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: String? {
    get {
      return graphQLMap["gt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: String? {
    get {
      return graphQLMap["contains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: String? {
    get {
      return graphQLMap["notContains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: [String?]? {
    get {
      return graphQLMap["between"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: String? {
    get {
      return graphQLMap["beginsWith"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }

  public var attributeExists: Bool? {
    get {
      return graphQLMap["attributeExists"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeExists")
    }
  }

  public var attributeType: ModelAttributeTypes? {
    get {
      return graphQLMap["attributeType"] as! ModelAttributeTypes?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeType")
    }
  }

  public var size: ModelSizeInput? {
    get {
      return graphQLMap["size"] as! ModelSizeInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "size")
    }
  }
}

public enum ModelAttributeTypes: RawRepresentable, Equatable, JSONDecodable, JSONEncodable {
  public typealias RawValue = String
  case binary
  case binarySet
  case bool
  case list
  case map
  case number
  case numberSet
  case string
  case stringSet
  case null
  /// Auto generated constant for unknown enum values
  case unknown(RawValue)

  public init?(rawValue: RawValue) {
    switch rawValue {
      case "binary": self = .binary
      case "binarySet": self = .binarySet
      case "bool": self = .bool
      case "list": self = .list
      case "map": self = .map
      case "number": self = .number
      case "numberSet": self = .numberSet
      case "string": self = .string
      case "stringSet": self = .stringSet
      case "_null": self = .null
      default: self = .unknown(rawValue)
    }
  }

  public var rawValue: RawValue {
    switch self {
      case .binary: return "binary"
      case .binarySet: return "binarySet"
      case .bool: return "bool"
      case .list: return "list"
      case .map: return "map"
      case .number: return "number"
      case .numberSet: return "numberSet"
      case .string: return "string"
      case .stringSet: return "stringSet"
      case .null: return "_null"
      case .unknown(let value): return value
    }
  }

  public static func == (lhs: ModelAttributeTypes, rhs: ModelAttributeTypes) -> Bool {
    switch (lhs, rhs) {
      case (.binary, .binary): return true
      case (.binarySet, .binarySet): return true
      case (.bool, .bool): return true
      case (.list, .list): return true
      case (.map, .map): return true
      case (.number, .number): return true
      case (.numberSet, .numberSet): return true
      case (.string, .string): return true
      case (.stringSet, .stringSet): return true
      case (.null, .null): return true
      case (.unknown(let lhsValue), .unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

public struct ModelSizeInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Int? = nil, eq: Int? = nil, le: Int? = nil, lt: Int? = nil, ge: Int? = nil, gt: Int? = nil, between: [Int?]? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "between": between]
  }

  public var ne: Int? {
    get {
      return graphQLMap["ne"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Int? {
    get {
      return graphQLMap["eq"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: Int? {
    get {
      return graphQLMap["le"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: Int? {
    get {
      return graphQLMap["lt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: Int? {
    get {
      return graphQLMap["ge"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: Int? {
    get {
      return graphQLMap["gt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var between: [Int?]? {
    get {
      return graphQLMap["between"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }
}

public struct ModelIntInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Int? = nil, eq: Int? = nil, le: Int? = nil, lt: Int? = nil, ge: Int? = nil, gt: Int? = nil, between: [Int?]? = nil, attributeExists: Bool? = nil, attributeType: ModelAttributeTypes? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "between": between, "attributeExists": attributeExists, "attributeType": attributeType]
  }

  public var ne: Int? {
    get {
      return graphQLMap["ne"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Int? {
    get {
      return graphQLMap["eq"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: Int? {
    get {
      return graphQLMap["le"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: Int? {
    get {
      return graphQLMap["lt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: Int? {
    get {
      return graphQLMap["ge"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: Int? {
    get {
      return graphQLMap["gt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var between: [Int?]? {
    get {
      return graphQLMap["between"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var attributeExists: Bool? {
    get {
      return graphQLMap["attributeExists"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeExists")
    }
  }

  public var attributeType: ModelAttributeTypes? {
    get {
      return graphQLMap["attributeType"] as! ModelAttributeTypes?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeType")
    }
  }
}

public struct UpdateUserProfileInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, userName: String? = nil, goal: String? = nil, height: Int? = nil, weight: Int? = nil, desiredWeight: Int? = nil, streak: Int? = nil) {
    graphQLMap = ["id": id, "userName": userName, "goal": goal, "height": height, "weight": weight, "desiredWeight": desiredWeight, "streak": streak]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var userName: String? {
    get {
      return graphQLMap["userName"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userName")
    }
  }

  public var goal: String? {
    get {
      return graphQLMap["goal"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "goal")
    }
  }

  public var height: Int? {
    get {
      return graphQLMap["height"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "height")
    }
  }

  public var weight: Int? {
    get {
      return graphQLMap["weight"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "weight")
    }
  }

  public var desiredWeight: Int? {
    get {
      return graphQLMap["desiredWeight"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "desiredWeight")
    }
  }

  public var streak: Int? {
    get {
      return graphQLMap["streak"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "streak")
    }
  }
}

public struct DeleteUserProfileInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID) {
    graphQLMap = ["id": id]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }
}

public struct CreateWorkoutInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID? = nil, date: String, name: String, exercises: [CompletedExerciseInput?]? = nil) {
    graphQLMap = ["id": id, "date": date, "name": name, "exercises": exercises]
  }

  public var id: GraphQLID? {
    get {
      return graphQLMap["id"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var date: String {
    get {
      return graphQLMap["date"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "date")
    }
  }

  public var name: String {
    get {
      return graphQLMap["name"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var exercises: [CompletedExerciseInput?]? {
    get {
      return graphQLMap["exercises"] as! [CompletedExerciseInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "exercises")
    }
  }
}

public struct CompletedExerciseInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(name: String, emoji: String, sets: [CompletedSetInput?]? = nil) {
    graphQLMap = ["name": name, "emoji": emoji, "sets": sets]
  }

  public var name: String {
    get {
      return graphQLMap["name"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var emoji: String {
    get {
      return graphQLMap["emoji"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "emoji")
    }
  }

  public var sets: [CompletedSetInput?]? {
    get {
      return graphQLMap["sets"] as! [CompletedSetInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "sets")
    }
  }
}

public struct CompletedSetInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(setNumber: Int, weight: Double, reps: Int) {
    graphQLMap = ["setNumber": setNumber, "weight": weight, "reps": reps]
  }

  public var setNumber: Int {
    get {
      return graphQLMap["setNumber"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "setNumber")
    }
  }

  public var weight: Double {
    get {
      return graphQLMap["weight"] as! Double
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "weight")
    }
  }

  public var reps: Int {
    get {
      return graphQLMap["reps"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "reps")
    }
  }
}

public struct ModelWorkoutConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(date: ModelStringInput? = nil, name: ModelStringInput? = nil, and: [ModelWorkoutConditionInput?]? = nil, or: [ModelWorkoutConditionInput?]? = nil, not: ModelWorkoutConditionInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["date": date, "name": name, "and": and, "or": or, "not": not, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner]
  }

  public var date: ModelStringInput? {
    get {
      return graphQLMap["date"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "date")
    }
  }

  public var name: ModelStringInput? {
    get {
      return graphQLMap["name"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var and: [ModelWorkoutConditionInput?]? {
    get {
      return graphQLMap["and"] as! [ModelWorkoutConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelWorkoutConditionInput?]? {
    get {
      return graphQLMap["or"] as! [ModelWorkoutConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelWorkoutConditionInput? {
    get {
      return graphQLMap["not"] as! ModelWorkoutConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct UpdateWorkoutInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, date: String? = nil, name: String? = nil, exercises: [CompletedExerciseInput?]? = nil) {
    graphQLMap = ["id": id, "date": date, "name": name, "exercises": exercises]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var date: String? {
    get {
      return graphQLMap["date"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "date")
    }
  }

  public var name: String? {
    get {
      return graphQLMap["name"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var exercises: [CompletedExerciseInput?]? {
    get {
      return graphQLMap["exercises"] as! [CompletedExerciseInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "exercises")
    }
  }
}

public struct DeleteWorkoutInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID) {
    graphQLMap = ["id": id]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }
}

public struct ModelUserProfileFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelIDInput? = nil, userName: ModelStringInput? = nil, goal: ModelStringInput? = nil, height: ModelIntInput? = nil, weight: ModelIntInput? = nil, desiredWeight: ModelIntInput? = nil, streak: ModelIntInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, and: [ModelUserProfileFilterInput?]? = nil, or: [ModelUserProfileFilterInput?]? = nil, not: ModelUserProfileFilterInput? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["id": id, "userName": userName, "goal": goal, "height": height, "weight": weight, "desiredWeight": desiredWeight, "streak": streak, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "not": not, "owner": owner]
  }

  public var id: ModelIDInput? {
    get {
      return graphQLMap["id"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var userName: ModelStringInput? {
    get {
      return graphQLMap["userName"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userName")
    }
  }

  public var goal: ModelStringInput? {
    get {
      return graphQLMap["goal"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "goal")
    }
  }

  public var height: ModelIntInput? {
    get {
      return graphQLMap["height"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "height")
    }
  }

  public var weight: ModelIntInput? {
    get {
      return graphQLMap["weight"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "weight")
    }
  }

  public var desiredWeight: ModelIntInput? {
    get {
      return graphQLMap["desiredWeight"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "desiredWeight")
    }
  }

  public var streak: ModelIntInput? {
    get {
      return graphQLMap["streak"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "streak")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelUserProfileFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelUserProfileFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelUserProfileFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelUserProfileFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelUserProfileFilterInput? {
    get {
      return graphQLMap["not"] as! ModelUserProfileFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct ModelIDInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: GraphQLID? = nil, eq: GraphQLID? = nil, le: GraphQLID? = nil, lt: GraphQLID? = nil, ge: GraphQLID? = nil, gt: GraphQLID? = nil, contains: GraphQLID? = nil, notContains: GraphQLID? = nil, between: [GraphQLID?]? = nil, beginsWith: GraphQLID? = nil, attributeExists: Bool? = nil, attributeType: ModelAttributeTypes? = nil, size: ModelSizeInput? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith, "attributeExists": attributeExists, "attributeType": attributeType, "size": size]
  }

  public var ne: GraphQLID? {
    get {
      return graphQLMap["ne"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: GraphQLID? {
    get {
      return graphQLMap["eq"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: GraphQLID? {
    get {
      return graphQLMap["le"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: GraphQLID? {
    get {
      return graphQLMap["lt"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: GraphQLID? {
    get {
      return graphQLMap["ge"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: GraphQLID? {
    get {
      return graphQLMap["gt"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: GraphQLID? {
    get {
      return graphQLMap["contains"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: GraphQLID? {
    get {
      return graphQLMap["notContains"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: [GraphQLID?]? {
    get {
      return graphQLMap["between"] as! [GraphQLID?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: GraphQLID? {
    get {
      return graphQLMap["beginsWith"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }

  public var attributeExists: Bool? {
    get {
      return graphQLMap["attributeExists"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeExists")
    }
  }

  public var attributeType: ModelAttributeTypes? {
    get {
      return graphQLMap["attributeType"] as! ModelAttributeTypes?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeType")
    }
  }

  public var size: ModelSizeInput? {
    get {
      return graphQLMap["size"] as! ModelSizeInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "size")
    }
  }
}

public struct ModelWorkoutFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelIDInput? = nil, date: ModelStringInput? = nil, name: ModelStringInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, and: [ModelWorkoutFilterInput?]? = nil, or: [ModelWorkoutFilterInput?]? = nil, not: ModelWorkoutFilterInput? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["id": id, "date": date, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "not": not, "owner": owner]
  }

  public var id: ModelIDInput? {
    get {
      return graphQLMap["id"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var date: ModelStringInput? {
    get {
      return graphQLMap["date"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "date")
    }
  }

  public var name: ModelStringInput? {
    get {
      return graphQLMap["name"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelWorkoutFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelWorkoutFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelWorkoutFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelWorkoutFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelWorkoutFilterInput? {
    get {
      return graphQLMap["not"] as! ModelWorkoutFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct ModelSubscriptionUserProfileFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelSubscriptionIDInput? = nil, userName: ModelSubscriptionStringInput? = nil, goal: ModelSubscriptionStringInput? = nil, height: ModelSubscriptionIntInput? = nil, weight: ModelSubscriptionIntInput? = nil, desiredWeight: ModelSubscriptionIntInput? = nil, streak: ModelSubscriptionIntInput? = nil, createdAt: ModelSubscriptionStringInput? = nil, updatedAt: ModelSubscriptionStringInput? = nil, and: [ModelSubscriptionUserProfileFilterInput?]? = nil, or: [ModelSubscriptionUserProfileFilterInput?]? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["id": id, "userName": userName, "goal": goal, "height": height, "weight": weight, "desiredWeight": desiredWeight, "streak": streak, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "owner": owner]
  }

  public var id: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["id"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var userName: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["userName"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userName")
    }
  }

  public var goal: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["goal"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "goal")
    }
  }

  public var height: ModelSubscriptionIntInput? {
    get {
      return graphQLMap["height"] as! ModelSubscriptionIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "height")
    }
  }

  public var weight: ModelSubscriptionIntInput? {
    get {
      return graphQLMap["weight"] as! ModelSubscriptionIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "weight")
    }
  }

  public var desiredWeight: ModelSubscriptionIntInput? {
    get {
      return graphQLMap["desiredWeight"] as! ModelSubscriptionIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "desiredWeight")
    }
  }

  public var streak: ModelSubscriptionIntInput? {
    get {
      return graphQLMap["streak"] as! ModelSubscriptionIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "streak")
    }
  }

  public var createdAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelSubscriptionUserProfileFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelSubscriptionUserProfileFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelSubscriptionUserProfileFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelSubscriptionUserProfileFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct ModelSubscriptionIDInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: GraphQLID? = nil, eq: GraphQLID? = nil, le: GraphQLID? = nil, lt: GraphQLID? = nil, ge: GraphQLID? = nil, gt: GraphQLID? = nil, contains: GraphQLID? = nil, notContains: GraphQLID? = nil, between: [GraphQLID?]? = nil, beginsWith: GraphQLID? = nil, `in`: [GraphQLID?]? = nil, notIn: [GraphQLID?]? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith, "in": `in`, "notIn": notIn]
  }

  public var ne: GraphQLID? {
    get {
      return graphQLMap["ne"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: GraphQLID? {
    get {
      return graphQLMap["eq"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: GraphQLID? {
    get {
      return graphQLMap["le"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: GraphQLID? {
    get {
      return graphQLMap["lt"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: GraphQLID? {
    get {
      return graphQLMap["ge"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: GraphQLID? {
    get {
      return graphQLMap["gt"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: GraphQLID? {
    get {
      return graphQLMap["contains"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: GraphQLID? {
    get {
      return graphQLMap["notContains"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: [GraphQLID?]? {
    get {
      return graphQLMap["between"] as! [GraphQLID?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: GraphQLID? {
    get {
      return graphQLMap["beginsWith"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }

  public var `in`: [GraphQLID?]? {
    get {
      return graphQLMap["in"] as! [GraphQLID?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "in")
    }
  }

  public var notIn: [GraphQLID?]? {
    get {
      return graphQLMap["notIn"] as! [GraphQLID?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notIn")
    }
  }
}

public struct ModelSubscriptionStringInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: String? = nil, eq: String? = nil, le: String? = nil, lt: String? = nil, ge: String? = nil, gt: String? = nil, contains: String? = nil, notContains: String? = nil, between: [String?]? = nil, beginsWith: String? = nil, `in`: [String?]? = nil, notIn: [String?]? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith, "in": `in`, "notIn": notIn]
  }

  public var ne: String? {
    get {
      return graphQLMap["ne"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: String? {
    get {
      return graphQLMap["eq"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: String? {
    get {
      return graphQLMap["le"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: String? {
    get {
      return graphQLMap["lt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: String? {
    get {
      return graphQLMap["ge"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: String? {
    get {
      return graphQLMap["gt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: String? {
    get {
      return graphQLMap["contains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: String? {
    get {
      return graphQLMap["notContains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: [String?]? {
    get {
      return graphQLMap["between"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: String? {
    get {
      return graphQLMap["beginsWith"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }

  public var `in`: [String?]? {
    get {
      return graphQLMap["in"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "in")
    }
  }

  public var notIn: [String?]? {
    get {
      return graphQLMap["notIn"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notIn")
    }
  }
}

public struct ModelSubscriptionIntInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Int? = nil, eq: Int? = nil, le: Int? = nil, lt: Int? = nil, ge: Int? = nil, gt: Int? = nil, between: [Int?]? = nil, `in`: [Int?]? = nil, notIn: [Int?]? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "between": between, "in": `in`, "notIn": notIn]
  }

  public var ne: Int? {
    get {
      return graphQLMap["ne"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Int? {
    get {
      return graphQLMap["eq"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: Int? {
    get {
      return graphQLMap["le"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: Int? {
    get {
      return graphQLMap["lt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: Int? {
    get {
      return graphQLMap["ge"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: Int? {
    get {
      return graphQLMap["gt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var between: [Int?]? {
    get {
      return graphQLMap["between"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var `in`: [Int?]? {
    get {
      return graphQLMap["in"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "in")
    }
  }

  public var notIn: [Int?]? {
    get {
      return graphQLMap["notIn"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notIn")
    }
  }
}

public struct ModelSubscriptionWorkoutFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelSubscriptionIDInput? = nil, date: ModelSubscriptionStringInput? = nil, name: ModelSubscriptionStringInput? = nil, createdAt: ModelSubscriptionStringInput? = nil, updatedAt: ModelSubscriptionStringInput? = nil, and: [ModelSubscriptionWorkoutFilterInput?]? = nil, or: [ModelSubscriptionWorkoutFilterInput?]? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["id": id, "date": date, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "owner": owner]
  }

  public var id: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["id"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var date: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["date"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "date")
    }
  }

  public var name: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["name"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var createdAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelSubscriptionWorkoutFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelSubscriptionWorkoutFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelSubscriptionWorkoutFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelSubscriptionWorkoutFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public final class CreateUserProfileMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateUserProfile($input: CreateUserProfileInput!, $condition: ModelUserProfileConditionInput) {\n  createUserProfile(input: $input, condition: $condition) {\n    __typename\n    id\n    userName\n    goal\n    height\n    weight\n    desiredWeight\n    streak\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: CreateUserProfileInput
  public var condition: ModelUserProfileConditionInput?

  public init(input: CreateUserProfileInput, condition: ModelUserProfileConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createUserProfile", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(CreateUserProfile.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createUserProfile: CreateUserProfile? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createUserProfile": createUserProfile.flatMap { $0.snapshot }])
    }

    public var createUserProfile: CreateUserProfile? {
      get {
        return (snapshot["createUserProfile"] as? Snapshot).flatMap { CreateUserProfile(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createUserProfile")
      }
    }

    public struct CreateUserProfile: GraphQLSelectionSet {
      public static let possibleTypes = ["UserProfile"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userName", type: .nonNull(.scalar(String.self))),
        GraphQLField("goal", type: .nonNull(.scalar(String.self))),
        GraphQLField("height", type: .nonNull(.scalar(Int.self))),
        GraphQLField("weight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("desiredWeight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("streak", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userName: String, goal: String, height: Int, weight: Int, desiredWeight: Int, streak: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserProfile", "id": id, "userName": userName, "goal": goal, "height": height, "weight": weight, "desiredWeight": desiredWeight, "streak": streak, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userName: String {
        get {
          return snapshot["userName"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "userName")
        }
      }

      public var goal: String {
        get {
          return snapshot["goal"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "goal")
        }
      }

      public var height: Int {
        get {
          return snapshot["height"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "height")
        }
      }

      public var weight: Int {
        get {
          return snapshot["weight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "weight")
        }
      }

      public var desiredWeight: Int {
        get {
          return snapshot["desiredWeight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "desiredWeight")
        }
      }

      public var streak: Int {
        get {
          return snapshot["streak"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "streak")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class UpdateUserProfileMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateUserProfile($input: UpdateUserProfileInput!, $condition: ModelUserProfileConditionInput) {\n  updateUserProfile(input: $input, condition: $condition) {\n    __typename\n    id\n    userName\n    goal\n    height\n    weight\n    desiredWeight\n    streak\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: UpdateUserProfileInput
  public var condition: ModelUserProfileConditionInput?

  public init(input: UpdateUserProfileInput, condition: ModelUserProfileConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateUserProfile", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(UpdateUserProfile.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateUserProfile: UpdateUserProfile? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateUserProfile": updateUserProfile.flatMap { $0.snapshot }])
    }

    public var updateUserProfile: UpdateUserProfile? {
      get {
        return (snapshot["updateUserProfile"] as? Snapshot).flatMap { UpdateUserProfile(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateUserProfile")
      }
    }

    public struct UpdateUserProfile: GraphQLSelectionSet {
      public static let possibleTypes = ["UserProfile"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userName", type: .nonNull(.scalar(String.self))),
        GraphQLField("goal", type: .nonNull(.scalar(String.self))),
        GraphQLField("height", type: .nonNull(.scalar(Int.self))),
        GraphQLField("weight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("desiredWeight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("streak", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userName: String, goal: String, height: Int, weight: Int, desiredWeight: Int, streak: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserProfile", "id": id, "userName": userName, "goal": goal, "height": height, "weight": weight, "desiredWeight": desiredWeight, "streak": streak, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userName: String {
        get {
          return snapshot["userName"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "userName")
        }
      }

      public var goal: String {
        get {
          return snapshot["goal"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "goal")
        }
      }

      public var height: Int {
        get {
          return snapshot["height"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "height")
        }
      }

      public var weight: Int {
        get {
          return snapshot["weight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "weight")
        }
      }

      public var desiredWeight: Int {
        get {
          return snapshot["desiredWeight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "desiredWeight")
        }
      }

      public var streak: Int {
        get {
          return snapshot["streak"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "streak")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class DeleteUserProfileMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteUserProfile($input: DeleteUserProfileInput!, $condition: ModelUserProfileConditionInput) {\n  deleteUserProfile(input: $input, condition: $condition) {\n    __typename\n    id\n    userName\n    goal\n    height\n    weight\n    desiredWeight\n    streak\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: DeleteUserProfileInput
  public var condition: ModelUserProfileConditionInput?

  public init(input: DeleteUserProfileInput, condition: ModelUserProfileConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteUserProfile", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(DeleteUserProfile.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteUserProfile: DeleteUserProfile? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteUserProfile": deleteUserProfile.flatMap { $0.snapshot }])
    }

    public var deleteUserProfile: DeleteUserProfile? {
      get {
        return (snapshot["deleteUserProfile"] as? Snapshot).flatMap { DeleteUserProfile(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteUserProfile")
      }
    }

    public struct DeleteUserProfile: GraphQLSelectionSet {
      public static let possibleTypes = ["UserProfile"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userName", type: .nonNull(.scalar(String.self))),
        GraphQLField("goal", type: .nonNull(.scalar(String.self))),
        GraphQLField("height", type: .nonNull(.scalar(Int.self))),
        GraphQLField("weight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("desiredWeight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("streak", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userName: String, goal: String, height: Int, weight: Int, desiredWeight: Int, streak: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserProfile", "id": id, "userName": userName, "goal": goal, "height": height, "weight": weight, "desiredWeight": desiredWeight, "streak": streak, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userName: String {
        get {
          return snapshot["userName"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "userName")
        }
      }

      public var goal: String {
        get {
          return snapshot["goal"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "goal")
        }
      }

      public var height: Int {
        get {
          return snapshot["height"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "height")
        }
      }

      public var weight: Int {
        get {
          return snapshot["weight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "weight")
        }
      }

      public var desiredWeight: Int {
        get {
          return snapshot["desiredWeight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "desiredWeight")
        }
      }

      public var streak: Int {
        get {
          return snapshot["streak"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "streak")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class CreateWorkoutMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateWorkout($input: CreateWorkoutInput!, $condition: ModelWorkoutConditionInput) {\n  createWorkout(input: $input, condition: $condition) {\n    __typename\n    id\n    date\n    name\n    exercises {\n      __typename\n      name\n      emoji\n    }\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: CreateWorkoutInput
  public var condition: ModelWorkoutConditionInput?

  public init(input: CreateWorkoutInput, condition: ModelWorkoutConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createWorkout", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(CreateWorkout.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createWorkout: CreateWorkout? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createWorkout": createWorkout.flatMap { $0.snapshot }])
    }

    public var createWorkout: CreateWorkout? {
      get {
        return (snapshot["createWorkout"] as? Snapshot).flatMap { CreateWorkout(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createWorkout")
      }
    }

    public struct CreateWorkout: GraphQLSelectionSet {
      public static let possibleTypes = ["Workout"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("exercises", type: .list(.object(Exercise.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, date: String, name: String, exercises: [Exercise?]? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Workout", "id": id, "date": date, "name": name, "exercises": exercises.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var exercises: [Exercise?]? {
        get {
          return (snapshot["exercises"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Exercise(snapshot: $0) } } }
        }
        set {
          snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "exercises")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Exercise: GraphQLSelectionSet {
        public static let possibleTypes = ["CompletedExercise"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("emoji", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, emoji: String) {
          self.init(snapshot: ["__typename": "CompletedExercise", "name": name, "emoji": emoji])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var emoji: String {
          get {
            return snapshot["emoji"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "emoji")
          }
        }
      }
    }
  }
}

public final class UpdateWorkoutMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateWorkout($input: UpdateWorkoutInput!, $condition: ModelWorkoutConditionInput) {\n  updateWorkout(input: $input, condition: $condition) {\n    __typename\n    id\n    date\n    name\n    exercises {\n      __typename\n      name\n      emoji\n    }\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: UpdateWorkoutInput
  public var condition: ModelWorkoutConditionInput?

  public init(input: UpdateWorkoutInput, condition: ModelWorkoutConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateWorkout", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(UpdateWorkout.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateWorkout: UpdateWorkout? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateWorkout": updateWorkout.flatMap { $0.snapshot }])
    }

    public var updateWorkout: UpdateWorkout? {
      get {
        return (snapshot["updateWorkout"] as? Snapshot).flatMap { UpdateWorkout(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateWorkout")
      }
    }

    public struct UpdateWorkout: GraphQLSelectionSet {
      public static let possibleTypes = ["Workout"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("exercises", type: .list(.object(Exercise.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, date: String, name: String, exercises: [Exercise?]? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Workout", "id": id, "date": date, "name": name, "exercises": exercises.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var exercises: [Exercise?]? {
        get {
          return (snapshot["exercises"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Exercise(snapshot: $0) } } }
        }
        set {
          snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "exercises")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Exercise: GraphQLSelectionSet {
        public static let possibleTypes = ["CompletedExercise"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("emoji", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, emoji: String) {
          self.init(snapshot: ["__typename": "CompletedExercise", "name": name, "emoji": emoji])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var emoji: String {
          get {
            return snapshot["emoji"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "emoji")
          }
        }
      }
    }
  }
}

public final class DeleteWorkoutMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteWorkout($input: DeleteWorkoutInput!, $condition: ModelWorkoutConditionInput) {\n  deleteWorkout(input: $input, condition: $condition) {\n    __typename\n    id\n    date\n    name\n    exercises {\n      __typename\n      name\n      emoji\n    }\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: DeleteWorkoutInput
  public var condition: ModelWorkoutConditionInput?

  public init(input: DeleteWorkoutInput, condition: ModelWorkoutConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteWorkout", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(DeleteWorkout.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteWorkout: DeleteWorkout? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteWorkout": deleteWorkout.flatMap { $0.snapshot }])
    }

    public var deleteWorkout: DeleteWorkout? {
      get {
        return (snapshot["deleteWorkout"] as? Snapshot).flatMap { DeleteWorkout(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteWorkout")
      }
    }

    public struct DeleteWorkout: GraphQLSelectionSet {
      public static let possibleTypes = ["Workout"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("exercises", type: .list(.object(Exercise.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, date: String, name: String, exercises: [Exercise?]? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Workout", "id": id, "date": date, "name": name, "exercises": exercises.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var exercises: [Exercise?]? {
        get {
          return (snapshot["exercises"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Exercise(snapshot: $0) } } }
        }
        set {
          snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "exercises")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Exercise: GraphQLSelectionSet {
        public static let possibleTypes = ["CompletedExercise"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("emoji", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, emoji: String) {
          self.init(snapshot: ["__typename": "CompletedExercise", "name": name, "emoji": emoji])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var emoji: String {
          get {
            return snapshot["emoji"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "emoji")
          }
        }
      }
    }
  }
}

public final class GetUserProfileQuery: GraphQLQuery {
  public static let operationString =
    "query GetUserProfile($id: ID!) {\n  getUserProfile(id: $id) {\n    __typename\n    id\n    userName\n    goal\n    height\n    weight\n    desiredWeight\n    streak\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getUserProfile", arguments: ["id": GraphQLVariable("id")], type: .object(GetUserProfile.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getUserProfile: GetUserProfile? = nil) {
      self.init(snapshot: ["__typename": "Query", "getUserProfile": getUserProfile.flatMap { $0.snapshot }])
    }

    public var getUserProfile: GetUserProfile? {
      get {
        return (snapshot["getUserProfile"] as? Snapshot).flatMap { GetUserProfile(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getUserProfile")
      }
    }

    public struct GetUserProfile: GraphQLSelectionSet {
      public static let possibleTypes = ["UserProfile"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userName", type: .nonNull(.scalar(String.self))),
        GraphQLField("goal", type: .nonNull(.scalar(String.self))),
        GraphQLField("height", type: .nonNull(.scalar(Int.self))),
        GraphQLField("weight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("desiredWeight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("streak", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userName: String, goal: String, height: Int, weight: Int, desiredWeight: Int, streak: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserProfile", "id": id, "userName": userName, "goal": goal, "height": height, "weight": weight, "desiredWeight": desiredWeight, "streak": streak, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userName: String {
        get {
          return snapshot["userName"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "userName")
        }
      }

      public var goal: String {
        get {
          return snapshot["goal"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "goal")
        }
      }

      public var height: Int {
        get {
          return snapshot["height"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "height")
        }
      }

      public var weight: Int {
        get {
          return snapshot["weight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "weight")
        }
      }

      public var desiredWeight: Int {
        get {
          return snapshot["desiredWeight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "desiredWeight")
        }
      }

      public var streak: Int {
        get {
          return snapshot["streak"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "streak")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class ListUserProfilesQuery: GraphQLQuery {
  public static let operationString =
    "query ListUserProfiles($filter: ModelUserProfileFilterInput, $limit: Int, $nextToken: String) {\n  listUserProfiles(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      userName\n      goal\n      height\n      weight\n      desiredWeight\n      streak\n      createdAt\n      updatedAt\n      owner\n    }\n    nextToken\n  }\n}"

  public var filter: ModelUserProfileFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: ModelUserProfileFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listUserProfiles", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListUserProfile.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listUserProfiles: ListUserProfile? = nil) {
      self.init(snapshot: ["__typename": "Query", "listUserProfiles": listUserProfiles.flatMap { $0.snapshot }])
    }

    public var listUserProfiles: ListUserProfile? {
      get {
        return (snapshot["listUserProfiles"] as? Snapshot).flatMap { ListUserProfile(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listUserProfiles")
      }
    }

    public struct ListUserProfile: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelUserProfileConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil) {
        self.init(snapshot: ["__typename": "ModelUserProfileConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["UserProfile"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("userName", type: .nonNull(.scalar(String.self))),
          GraphQLField("goal", type: .nonNull(.scalar(String.self))),
          GraphQLField("height", type: .nonNull(.scalar(Int.self))),
          GraphQLField("weight", type: .nonNull(.scalar(Int.self))),
          GraphQLField("desiredWeight", type: .nonNull(.scalar(Int.self))),
          GraphQLField("streak", type: .nonNull(.scalar(Int.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, userName: String, goal: String, height: Int, weight: Int, desiredWeight: Int, streak: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
          self.init(snapshot: ["__typename": "UserProfile", "id": id, "userName": userName, "goal": goal, "height": height, "weight": weight, "desiredWeight": desiredWeight, "streak": streak, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var userName: String {
          get {
            return snapshot["userName"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "userName")
          }
        }

        public var goal: String {
          get {
            return snapshot["goal"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "goal")
          }
        }

        public var height: Int {
          get {
            return snapshot["height"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "height")
          }
        }

        public var weight: Int {
          get {
            return snapshot["weight"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "weight")
          }
        }

        public var desiredWeight: Int {
          get {
            return snapshot["desiredWeight"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "desiredWeight")
          }
        }

        public var streak: Int {
          get {
            return snapshot["streak"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "streak")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class GetWorkoutQuery: GraphQLQuery {
  public static let operationString =
    "query GetWorkout($id: ID!) {\n  getWorkout(id: $id) {\n    __typename\n    id\n    date\n    name\n    exercises {\n      __typename\n      name\n      emoji\n    }\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getWorkout", arguments: ["id": GraphQLVariable("id")], type: .object(GetWorkout.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getWorkout: GetWorkout? = nil) {
      self.init(snapshot: ["__typename": "Query", "getWorkout": getWorkout.flatMap { $0.snapshot }])
    }

    public var getWorkout: GetWorkout? {
      get {
        return (snapshot["getWorkout"] as? Snapshot).flatMap { GetWorkout(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getWorkout")
      }
    }

    public struct GetWorkout: GraphQLSelectionSet {
      public static let possibleTypes = ["Workout"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("exercises", type: .list(.object(Exercise.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, date: String, name: String, exercises: [Exercise?]? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Workout", "id": id, "date": date, "name": name, "exercises": exercises.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var exercises: [Exercise?]? {
        get {
          return (snapshot["exercises"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Exercise(snapshot: $0) } } }
        }
        set {
          snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "exercises")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Exercise: GraphQLSelectionSet {
        public static let possibleTypes = ["CompletedExercise"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("emoji", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, emoji: String) {
          self.init(snapshot: ["__typename": "CompletedExercise", "name": name, "emoji": emoji])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var emoji: String {
          get {
            return snapshot["emoji"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "emoji")
          }
        }
      }
    }
  }
}

public final class ListWorkoutsQuery: GraphQLQuery {
  public static let operationString =
    "query ListWorkouts($filter: ModelWorkoutFilterInput, $limit: Int, $nextToken: String) {\n  listWorkouts(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      date\n      name\n      createdAt\n      updatedAt\n      owner\n    }\n    nextToken\n  }\n}"

  public var filter: ModelWorkoutFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: ModelWorkoutFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listWorkouts", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListWorkout.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listWorkouts: ListWorkout? = nil) {
      self.init(snapshot: ["__typename": "Query", "listWorkouts": listWorkouts.flatMap { $0.snapshot }])
    }

    public var listWorkouts: ListWorkout? {
      get {
        return (snapshot["listWorkouts"] as? Snapshot).flatMap { ListWorkout(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listWorkouts")
      }
    }

    public struct ListWorkout: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelWorkoutConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil) {
        self.init(snapshot: ["__typename": "ModelWorkoutConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["Workout"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("date", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, date: String, name: String, createdAt: String, updatedAt: String, owner: String? = nil) {
          self.init(snapshot: ["__typename": "Workout", "id": id, "date": date, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var date: String {
          get {
            return snapshot["date"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "date")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class OnCreateUserProfileSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateUserProfile($filter: ModelSubscriptionUserProfileFilterInput, $owner: String) {\n  onCreateUserProfile(filter: $filter, owner: $owner) {\n    __typename\n    id\n    userName\n    goal\n    height\n    weight\n    desiredWeight\n    streak\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionUserProfileFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionUserProfileFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateUserProfile", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnCreateUserProfile.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateUserProfile: OnCreateUserProfile? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateUserProfile": onCreateUserProfile.flatMap { $0.snapshot }])
    }

    public var onCreateUserProfile: OnCreateUserProfile? {
      get {
        return (snapshot["onCreateUserProfile"] as? Snapshot).flatMap { OnCreateUserProfile(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateUserProfile")
      }
    }

    public struct OnCreateUserProfile: GraphQLSelectionSet {
      public static let possibleTypes = ["UserProfile"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userName", type: .nonNull(.scalar(String.self))),
        GraphQLField("goal", type: .nonNull(.scalar(String.self))),
        GraphQLField("height", type: .nonNull(.scalar(Int.self))),
        GraphQLField("weight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("desiredWeight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("streak", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userName: String, goal: String, height: Int, weight: Int, desiredWeight: Int, streak: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserProfile", "id": id, "userName": userName, "goal": goal, "height": height, "weight": weight, "desiredWeight": desiredWeight, "streak": streak, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userName: String {
        get {
          return snapshot["userName"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "userName")
        }
      }

      public var goal: String {
        get {
          return snapshot["goal"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "goal")
        }
      }

      public var height: Int {
        get {
          return snapshot["height"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "height")
        }
      }

      public var weight: Int {
        get {
          return snapshot["weight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "weight")
        }
      }

      public var desiredWeight: Int {
        get {
          return snapshot["desiredWeight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "desiredWeight")
        }
      }

      public var streak: Int {
        get {
          return snapshot["streak"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "streak")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class OnUpdateUserProfileSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateUserProfile($filter: ModelSubscriptionUserProfileFilterInput, $owner: String) {\n  onUpdateUserProfile(filter: $filter, owner: $owner) {\n    __typename\n    id\n    userName\n    goal\n    height\n    weight\n    desiredWeight\n    streak\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionUserProfileFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionUserProfileFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateUserProfile", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnUpdateUserProfile.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateUserProfile: OnUpdateUserProfile? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateUserProfile": onUpdateUserProfile.flatMap { $0.snapshot }])
    }

    public var onUpdateUserProfile: OnUpdateUserProfile? {
      get {
        return (snapshot["onUpdateUserProfile"] as? Snapshot).flatMap { OnUpdateUserProfile(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateUserProfile")
      }
    }

    public struct OnUpdateUserProfile: GraphQLSelectionSet {
      public static let possibleTypes = ["UserProfile"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userName", type: .nonNull(.scalar(String.self))),
        GraphQLField("goal", type: .nonNull(.scalar(String.self))),
        GraphQLField("height", type: .nonNull(.scalar(Int.self))),
        GraphQLField("weight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("desiredWeight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("streak", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userName: String, goal: String, height: Int, weight: Int, desiredWeight: Int, streak: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserProfile", "id": id, "userName": userName, "goal": goal, "height": height, "weight": weight, "desiredWeight": desiredWeight, "streak": streak, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userName: String {
        get {
          return snapshot["userName"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "userName")
        }
      }

      public var goal: String {
        get {
          return snapshot["goal"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "goal")
        }
      }

      public var height: Int {
        get {
          return snapshot["height"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "height")
        }
      }

      public var weight: Int {
        get {
          return snapshot["weight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "weight")
        }
      }

      public var desiredWeight: Int {
        get {
          return snapshot["desiredWeight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "desiredWeight")
        }
      }

      public var streak: Int {
        get {
          return snapshot["streak"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "streak")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class OnDeleteUserProfileSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteUserProfile($filter: ModelSubscriptionUserProfileFilterInput, $owner: String) {\n  onDeleteUserProfile(filter: $filter, owner: $owner) {\n    __typename\n    id\n    userName\n    goal\n    height\n    weight\n    desiredWeight\n    streak\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionUserProfileFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionUserProfileFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteUserProfile", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnDeleteUserProfile.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteUserProfile: OnDeleteUserProfile? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteUserProfile": onDeleteUserProfile.flatMap { $0.snapshot }])
    }

    public var onDeleteUserProfile: OnDeleteUserProfile? {
      get {
        return (snapshot["onDeleteUserProfile"] as? Snapshot).flatMap { OnDeleteUserProfile(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteUserProfile")
      }
    }

    public struct OnDeleteUserProfile: GraphQLSelectionSet {
      public static let possibleTypes = ["UserProfile"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userName", type: .nonNull(.scalar(String.self))),
        GraphQLField("goal", type: .nonNull(.scalar(String.self))),
        GraphQLField("height", type: .nonNull(.scalar(Int.self))),
        GraphQLField("weight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("desiredWeight", type: .nonNull(.scalar(Int.self))),
        GraphQLField("streak", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userName: String, goal: String, height: Int, weight: Int, desiredWeight: Int, streak: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserProfile", "id": id, "userName": userName, "goal": goal, "height": height, "weight": weight, "desiredWeight": desiredWeight, "streak": streak, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userName: String {
        get {
          return snapshot["userName"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "userName")
        }
      }

      public var goal: String {
        get {
          return snapshot["goal"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "goal")
        }
      }

      public var height: Int {
        get {
          return snapshot["height"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "height")
        }
      }

      public var weight: Int {
        get {
          return snapshot["weight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "weight")
        }
      }

      public var desiredWeight: Int {
        get {
          return snapshot["desiredWeight"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "desiredWeight")
        }
      }

      public var streak: Int {
        get {
          return snapshot["streak"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "streak")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class OnCreateWorkoutSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateWorkout($filter: ModelSubscriptionWorkoutFilterInput, $owner: String) {\n  onCreateWorkout(filter: $filter, owner: $owner) {\n    __typename\n    id\n    date\n    name\n    exercises {\n      __typename\n      name\n      emoji\n    }\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionWorkoutFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionWorkoutFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateWorkout", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnCreateWorkout.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateWorkout: OnCreateWorkout? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateWorkout": onCreateWorkout.flatMap { $0.snapshot }])
    }

    public var onCreateWorkout: OnCreateWorkout? {
      get {
        return (snapshot["onCreateWorkout"] as? Snapshot).flatMap { OnCreateWorkout(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateWorkout")
      }
    }

    public struct OnCreateWorkout: GraphQLSelectionSet {
      public static let possibleTypes = ["Workout"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("exercises", type: .list(.object(Exercise.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, date: String, name: String, exercises: [Exercise?]? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Workout", "id": id, "date": date, "name": name, "exercises": exercises.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var exercises: [Exercise?]? {
        get {
          return (snapshot["exercises"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Exercise(snapshot: $0) } } }
        }
        set {
          snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "exercises")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Exercise: GraphQLSelectionSet {
        public static let possibleTypes = ["CompletedExercise"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("emoji", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, emoji: String) {
          self.init(snapshot: ["__typename": "CompletedExercise", "name": name, "emoji": emoji])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var emoji: String {
          get {
            return snapshot["emoji"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "emoji")
          }
        }
      }
    }
  }
}

public final class OnUpdateWorkoutSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateWorkout($filter: ModelSubscriptionWorkoutFilterInput, $owner: String) {\n  onUpdateWorkout(filter: $filter, owner: $owner) {\n    __typename\n    id\n    date\n    name\n    exercises {\n      __typename\n      name\n      emoji\n    }\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionWorkoutFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionWorkoutFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateWorkout", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnUpdateWorkout.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateWorkout: OnUpdateWorkout? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateWorkout": onUpdateWorkout.flatMap { $0.snapshot }])
    }

    public var onUpdateWorkout: OnUpdateWorkout? {
      get {
        return (snapshot["onUpdateWorkout"] as? Snapshot).flatMap { OnUpdateWorkout(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateWorkout")
      }
    }

    public struct OnUpdateWorkout: GraphQLSelectionSet {
      public static let possibleTypes = ["Workout"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("exercises", type: .list(.object(Exercise.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, date: String, name: String, exercises: [Exercise?]? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Workout", "id": id, "date": date, "name": name, "exercises": exercises.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var exercises: [Exercise?]? {
        get {
          return (snapshot["exercises"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Exercise(snapshot: $0) } } }
        }
        set {
          snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "exercises")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Exercise: GraphQLSelectionSet {
        public static let possibleTypes = ["CompletedExercise"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("emoji", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, emoji: String) {
          self.init(snapshot: ["__typename": "CompletedExercise", "name": name, "emoji": emoji])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var emoji: String {
          get {
            return snapshot["emoji"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "emoji")
          }
        }
      }
    }
  }
}

public final class OnDeleteWorkoutSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteWorkout($filter: ModelSubscriptionWorkoutFilterInput, $owner: String) {\n  onDeleteWorkout(filter: $filter, owner: $owner) {\n    __typename\n    id\n    date\n    name\n    exercises {\n      __typename\n      name\n      emoji\n    }\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionWorkoutFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionWorkoutFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteWorkout", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnDeleteWorkout.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteWorkout: OnDeleteWorkout? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteWorkout": onDeleteWorkout.flatMap { $0.snapshot }])
    }

    public var onDeleteWorkout: OnDeleteWorkout? {
      get {
        return (snapshot["onDeleteWorkout"] as? Snapshot).flatMap { OnDeleteWorkout(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteWorkout")
      }
    }

    public struct OnDeleteWorkout: GraphQLSelectionSet {
      public static let possibleTypes = ["Workout"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("exercises", type: .list(.object(Exercise.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, date: String, name: String, exercises: [Exercise?]? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Workout", "id": id, "date": date, "name": name, "exercises": exercises.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var exercises: [Exercise?]? {
        get {
          return (snapshot["exercises"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Exercise(snapshot: $0) } } }
        }
        set {
          snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "exercises")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Exercise: GraphQLSelectionSet {
        public static let possibleTypes = ["CompletedExercise"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("emoji", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, emoji: String) {
          self.init(snapshot: ["__typename": "CompletedExercise", "name": name, "emoji": emoji])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var emoji: String {
          get {
            return snapshot["emoji"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "emoji")
          }
        }
      }
    }
  }
}
// swiftlint:disable all
import Amplify
import Foundation

extension UserProfile {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case userName
    case goal
    case height
    case weight
    case desiredWeight
    case streak
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let userProfile = UserProfile.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "UserProfiles"
    model.syncPluralName = "UserProfiles"
    
    model.attributes(
      .primaryKey(fields: [userProfile.id])
    )
    
    model.fields(
      .field(userProfile.id, is: .required, ofType: .string),
      .field(userProfile.userName, is: .required, ofType: .string),
      .field(userProfile.goal, is: .required, ofType: .string),
      .field(userProfile.height, is: .required, ofType: .int),
      .field(userProfile.weight, is: .required, ofType: .int),
      .field(userProfile.desiredWeight, is: .required, ofType: .int),
      .field(userProfile.streak, is: .required, ofType: .int),
      .field(userProfile.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(userProfile.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension UserProfile: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
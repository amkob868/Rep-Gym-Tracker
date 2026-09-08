// swiftlint:disable all
import Amplify
import Foundation

extension Workout {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case date
    case name
    case exercises
    case owner
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let workout = Workout.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Workouts"
    model.syncPluralName = "Workouts"
    
    model.attributes(
      .primaryKey(fields: [workout.id])
    )
    
    model.fields(
      .field(workout.id, is: .required, ofType: .string),
      .field(workout.date, is: .required, ofType: .date),
      .field(workout.name, is: .required, ofType: .string),
      .field(workout.exercises, is: .optional, ofType: .embeddedCollection(of: CompletedExercise.self)),
      .field(workout.owner, is: .optional, ofType: .string),
      .field(workout.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(workout.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Workout: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}

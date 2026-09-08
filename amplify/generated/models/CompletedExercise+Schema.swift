// swiftlint:disable all
import Amplify
import Foundation

extension CompletedExercise {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case name
    case emoji
    case sets
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let completedExercise = CompletedExercise.keys
    
    model.listPluralName = "CompletedExercises"
    model.syncPluralName = "CompletedExercises"
    
    model.fields(
      .field(completedExercise.name, is: .required, ofType: .string),
      .field(completedExercise.emoji, is: .required, ofType: .string),
      .field(completedExercise.sets, is: .optional, ofType: .embeddedCollection(of: CompletedSet.self))
    )
    }
}
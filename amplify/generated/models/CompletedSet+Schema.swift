// swiftlint:disable all
import Amplify
import Foundation

extension CompletedSet {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case setNumber
    case weight
    case reps
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let completedSet = CompletedSet.keys
    
    model.listPluralName = "CompletedSets"
    model.syncPluralName = "CompletedSets"
    
    model.fields(
      .field(completedSet.setNumber, is: .required, ofType: .int),
      .field(completedSet.weight, is: .required, ofType: .double),
      .field(completedSet.reps, is: .required, ofType: .int)
    )
    }
}
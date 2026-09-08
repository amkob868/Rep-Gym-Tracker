// swiftlint:disable all
import Amplify
import Foundation

public struct Workout: Model, @unchecked Sendable {
  public let id: String
  public var date: Temporal.Date
  public var name: String
  public var exercises: [CompletedExercise?]?
  public var owner: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      date: Temporal.Date,
      name: String,
      exercises: [CompletedExercise?]? = nil) {
    self.init(id: id,
      date: date,
      name: name,
      exercises: exercises,
      owner: nil,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      date: Temporal.Date,
      name: String,
      exercises: [CompletedExercise?]? = nil,
      owner: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.date = date
      self.name = name
      self.exercises = exercises
      self.owner = owner
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}

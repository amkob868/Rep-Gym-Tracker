// swiftlint:disable all
import Amplify
import Foundation

public struct UserProfile: Model {
  public let id: String
  public var userName: String
  public var goal: String
  public var height: Int
  public var weight: Int
  public var desiredWeight: Int
  public var streak: Int
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      userName: String,
      goal: String,
      height: Int,
      weight: Int,
      desiredWeight: Int,
      streak: Int) {
    self.init(id: id,
      userName: userName,
      goal: goal,
      height: height,
      weight: weight,
      desiredWeight: desiredWeight,
      streak: streak,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      userName: String,
      goal: String,
      height: Int,
      weight: Int,
      desiredWeight: Int,
      streak: Int,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.userName = userName
      self.goal = goal
      self.height = height
      self.weight = weight
      self.desiredWeight = desiredWeight
      self.streak = streak
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
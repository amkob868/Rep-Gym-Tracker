// swiftlint:disable all
import Amplify
import Foundation

public struct CompletedExercise: Embeddable, @unchecked Sendable {
  var name: String
  var emoji: String
  var sets: [CompletedSet]?
}

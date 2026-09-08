// swiftlint:disable all
import Amplify
import Foundation

public class Workout: Model {
    public let id: String
    public var date: Temporal.Date
    public var name: String
    public var exercises: [CompletedExercise?]?
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?
    
    public init(id: String = UUID().uuidString,
                date: Temporal.Date,
                name: String,
                exercises: [CompletedExercise?]? = nil) {
        self.id = id
        self.date = date
        self.name = name
        self.exercises = exercises
    }
}

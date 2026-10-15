import CoreData

/// A conversation row in Core Data.
@objc(ConversationRecord)
final class ConversationRecord: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var contactID: UUID
    @NSManaged var contactName: String
    @NSManaged var colorIndex: Int16
    @NSManaged var messages: Set<MessageRecord>
}

/// A message row in Core Data. Photos are stored as JPEG data, outside the database when large.
@objc(MessageRecord)
final class MessageRecord: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var sender: String
    @NSManaged var text: String?
    @NSManaged var imageData: Data?
    @NSManaged var sentAt: Date
    /// Keeps the send order even when two messages share a timestamp.
    @NSManaged var position: Int64
    @NSManaged var replyID: UUID?
    @NSManaged var replySender: String?
    @NSManaged var replySummary: String?
    @NSManaged var conversation: ConversationRecord?
}

enum CoreDataModel {
    /// Built in code, so the schema is reviewable in a pull request and needs no `.xcdatamodeld`.
    /// One shared instance: every container must use the same model object.
    static let shared: NSManagedObjectModel = {
        let conversation = entity(ConversationRecord.self, attributes: [
            attribute("id", .UUIDAttributeType),
            attribute("contactID", .UUIDAttributeType),
            attribute("contactName", .stringAttributeType),
            attribute("colorIndex", .integer16AttributeType),
        ])

        let imageData = attribute("imageData", .binaryDataAttributeType, optional: true)
        imageData.allowsExternalBinaryDataStorage = true
        let message = entity(MessageRecord.self, attributes: [
            attribute("id", .UUIDAttributeType),
            attribute("sender", .stringAttributeType),
            attribute("text", .stringAttributeType, optional: true),
            imageData,
            attribute("sentAt", .dateAttributeType),
            attribute("position", .integer64AttributeType),
            attribute("replyID", .UUIDAttributeType, optional: true),
            attribute("replySender", .stringAttributeType, optional: true),
            attribute("replySummary", .stringAttributeType, optional: true),
        ])

        let messages = NSRelationshipDescription()
        messages.name = "messages"
        messages.destinationEntity = message
        messages.minCount = 0
        messages.maxCount = 0   // to-many
        messages.isOptional = true
        messages.deleteRule = .cascadeDeleteRule

        let owner = NSRelationshipDescription()
        owner.name = "conversation"
        owner.destinationEntity = conversation
        owner.minCount = 0
        owner.maxCount = 1
        owner.isOptional = true
        owner.deleteRule = .nullifyDeleteRule

        messages.inverseRelationship = owner
        owner.inverseRelationship = messages
        conversation.properties.append(messages)
        message.properties.append(owner)

        let model = NSManagedObjectModel()
        model.entities = [conversation, message]
        return model
    }()

    private static func entity(_ type: NSManagedObject.Type, attributes: [NSAttributeDescription]) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = String(describing: type)
        entity.managedObjectClassName = String(describing: type)
        entity.properties = attributes
        return entity
    }

    private static func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
}

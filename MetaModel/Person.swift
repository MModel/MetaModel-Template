//
//  Person.swift
//  MetaModel
//
//  Created by Draveness on 8/22/16.
//  Copyright © 2016 metamodel. All rights reserved.
//

import Foundation
import SQLite

public struct MModel {
    
}

public struct Person {
    public let id: Int
    public var name: String?
    public var email: String

    static let tableName = "people"

    public enum Represent: String, Unwrapped {
        case id = "id"
        case name = "name"
        case email = "email"

        var unwrapped: String { get { return self.rawValue.unwrapped } }
    }
}

extension Person: Recordable {
    public init(values: Array<Optional<Binding>>) {
        let id: Int64 = values[0] as! Int64
        let name: String? = values[1] as? String
        let email: String = values[2] as! String
        self.init(id: Int(id), name: name, email: email)
    }
}

extension Person {
    static let table = Table("people")

    public static let id = Expression<Int>("id")
    public static let name = Expression<String?>("name")
    public static let email = Expression<String>("email")

    static func createTable() {
        
        let _ = try? db.run(table.create { t in
            t.column(id, primaryKey: true)
            t.column(name)
            t.column(email)
        })
    }
}

public extension Person {
    static func deleteAll() {
        let deleteAllSQL = "DELETE FROM \(tableName.unwrapped)"
        executeSQL(deleteAllSQL)
    }
    static func count() -> Int {
        let countSQL = "SELECT count(*) FROM \(tableName.unwrapped)"
        guard let count = executeSQL(countSQL)?.next()?.first as? Int64 else { return 0 }
        return Int(count)
    }

    static func new(name: String?, email: String) -> Person {
        return Person(id: -1, name: name, email: email)
    }

    static func create(id: Int, name: String?, email: String) -> Person? {
        var columnsSQL: [Person.Represent] = []
        var valuesSQL: [Unwrapped] = []

        columnsSQL.append(.id)
        valuesSQL.append(id)


        if let name = name {
            columnsSQL.append(.name)
            valuesSQL.append(name)
        }

        columnsSQL.append(.email)
        valuesSQL.append(email)

        let insertSQL = "INSERT INTO \(tableName.unwrapped) (\(columnsSQL.map { $0.rawValue }.joinWithSeparator(", "))) VALUES (\(valuesSQL.map { $0.unwrapped }.joinWithSeparator(", ")))"
        guard let result = executeSQL(insertSQL) else { return nil }
        return Person(id: id, name: name, email: email)
    }
    
}

public extension Person {
    var itself: String { get { return "WHERE \(Person.tableName.unwrapped).\("id".unwrapped) = \(id)" } }

    func delete() {
        let deleteSQL = "DELETE FROM \(Person.tableName.unwrapped) \(itself)"
        executeSQL(deleteSQL)
    }
    mutating func update(name name: String?) -> Person {
        self.name = name
        return self
    }

    mutating func update(email email: String) -> Person {
        self.email = email
        return self
    }
    mutating func update(attributes: [Person.Represent: Any]) {
        var setSQL: [String] = []
        for (key, value) in attributes {
            switch key {
            case .name:
                self.name = value as? String
                setSQL.append("\(key.unwrapped) = \(self.name?.unwrapped)")
            case .email:
                self.email = value as! String
                setSQL.append("\(key.unwrapped) = \(self.email.unwrapped)")
            default: break
            }
        }
        let updateSQL = "UPDATE \(Person.tableName.unwrapped) SET \(setSQL.joinWithSeparator(", ")) \(itself)"
        executeSQL(updateSQL)
    }
}

public extension Person {
    static var all: PersonRelation {
        get { return PersonRelation() }
    }

    static func first(length: UInt) -> PersonRelation {
        return PersonRelation().orderBy(.id, asc: true).limit(length)
    }

    static func last(length: UInt) -> PersonRelation {
        return PersonRelation().orderBy(.id, asc: false).limit(length)
    }

    static func find(id: Int) -> Person? {
        return PersonRelation().find(id).first
    }

    static func findBy(id id: Int) -> Person? {
        return PersonRelation().findBy(id: id).first
    }

    static func findBy(name name: String) -> Person? {
        return PersonRelation().findBy(name: name).first
    }
    
    static func findBy(email email: String) -> Person? {
        return PersonRelation().findBy(email: email).first
    }

    static func filter(column: Person.Represent, value: Any) -> PersonRelation {
        return PersonRelation().filter([column: value])
    }

    static func filter(conditions: [Person.Represent: Any]) -> PersonRelation {
        return PersonRelation().filter(conditions)
    }

    static func limit(length: UInt, offset: UInt = 0) -> PersonRelation {
        return PersonRelation().limit(length, offset: offset)
    }

    static func offset(offset: UInt) -> PersonRelation {
        return PersonRelation().offset(offset)
    }

    static func groupBy(columns: Person.Represent...) -> PersonRelation {
        return PersonRelation().groupBy(columns)
    }

    static func groupBy(columns: [Person.Represent]) -> PersonRelation {
        return PersonRelation().groupBy(columns)
    }

    static func orderBy(column: Person.Represent) -> PersonRelation {
        return PersonRelation().orderBy(column)
    }

    static func orderBy(column: Person.Represent, asc: Bool) -> PersonRelation {
        return PersonRelation().orderBy(column, asc: asc)
    }
}

public class PersonRelation: Relation<Person> {
    override init() {
        super.init()
        self.select = "SELECT \(Person.tableName.unwrapped).* FROM \(Person.tableName.unwrapped)"
    }

    func expandColumn(column: Person.Represent) -> String {
        return "\(Person.tableName.unwrapped).\(column.unwrapped)"
    }

    // MARK: Query

    public func find(id: Int) -> Self {
        return self.findBy(id: id)
    }

    public func findBy(id id: Int) -> Self {
        return self.filter([.id: id]).limit(1)
    }

    public func findBy(name name: String) -> Self {
        return self.filter([.name: name]).limit(1)
    }

    public func findBy(email email: String) -> Self {
        return self.filter([.email: email]).limit(1)
    }

    public func filter(conditions: [Person.Represent: Any]) -> Self {
        for (column, value) in conditions {
            let columnSQL = "\(expandColumn(column))"

            func filterByEqual(value: Any) {
                self.filter.append("\(columnSQL) = \(value)")
            }

            func filterByIn(value: [String]) {
                self.filter.append("\(columnSQL) IN (\(value.joinWithSeparator(", ")))")
            }

            if let value = value as? String {
                filterByEqual(value.unwrapped)
            } else if let value = value as? Int {
                filterByEqual(value)
            } else if let value = value as? Double {
                filterByEqual(value)
            } else if let value = value as? [String] {
                filterByIn(value.map { $0.unwrapped })
            } else if let value = value as? [Int] {
                filterByIn(value.map { $0.description })
            } else if let value = value as? [Double] {
                filterByIn(value.map { $0.description })
            } else {
                let valueMirror = Mirror(reflecting: value)
                print("!!!: UNSUPPORTED TYPE \(valueMirror.subjectType)")
            }

        }
        return self
    }

    public func groupBy(columns: Person.Represent...) -> Self {
        return self.groupBy(columns)
    }

    public func groupBy(columns: [Person.Represent]) -> Self {
        func groupBy(column: Person.Represent) {
            self.group.append("\(expandColumn(column))")
        }
        columns.flatMap(groupBy)
        return self
    }

    public func orderBy(column: Person.Represent) -> Self {
        self.order.append("\(expandColumn(column))")
        return self
    }

    public func orderBy(column: Person.Represent, asc: Bool) -> Self {
        self.order.append("\(expandColumn(column)) \(asc ? "ASC".unwrapped : "DESC".unwrapped)")
        return self
    }

}



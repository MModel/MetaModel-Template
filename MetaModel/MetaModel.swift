//
//  MetaModel.swift
//  MetaModel
//
//  Created by 左书祺 on 8/22/16.
//  Copyright © 2016 metamodel. All rights reserved.
//

import Foundation
import SQLite

let path = NSSearchPathForDirectoriesInDomains(
    .DocumentDirectory, .UserDomainMask, true
).first! as String

let db =  try! Connection("\(path)/db.sqlite3")

public class MetaModel {
    public static func initialize() {
        Person.meta.createTable()
    }
}


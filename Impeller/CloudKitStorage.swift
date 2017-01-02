//
//  CloudKitStorage.swift
//  Impeller
//
//  Created by Drew McCormack on 29/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

import Foundation
import CloudKit


struct CloudKitCursor: Cursor {
    var serverToken: CKServerChangeToken
    
    var data: Data {
        get {
            return NSKeyedArchiver.archivedData(withRootObject: serverToken)
        }
        set {
            serverToken = NSKeyedUnarchiver.unarchiveObject(with: newValue) as! CKServerChangeToken
        }
    }
}


class CloudKitStorage: Exchangable {
    
    public let uniqueIdentifier: UniqueIdentifier
    private let database: CKDatabase
    private let zone: CKRecordZone
    
    init(withUniqueIdentifier identifier: UniqueIdentifier, cloudDatabase: CKDatabase) {
        self.uniqueIdentifier = identifier
        self.database = cloudDatabase
        self.zone = CKRecordZone(zoneName: uniqueIdentifier)
        self.prepareZone()
    }
    
    private func prepareZone() {
        database.save(zone) { zone, error in }
    }

    func fetchValueTrees(forChangesSince cursor: Cursor?, completionHandler completion: @escaping (Error?, [ValueTree], Cursor?)->Void) {
        let token = (cursor as? CloudKitCursor)?.serverToken
        var valueTrees = [ValueTree]()
        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = token
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zone.zoneID], optionsByRecordZoneID: [zone.zoneID : options])
        operation.fetchAllChanges = true
        operation.recordChangedBlock = { record in
            if let valueTree = record.asValueTree {
                valueTrees.append(valueTree)
            }
        }
        operation.recordZoneFetchCompletionBlock = { zoneID, token, clientData, moreComing, error in
            if let error = error as? CKError {
                if error.code == .changeTokenExpired {
                    completion(nil, [], nil)
                }
                else {
                    completion(error, [], nil)
                }
            }
            else {
                let newCursor = token != nil ? CloudKitCursor(serverToken: token!) : nil
                completion(nil, valueTrees, newCursor)
            }
        }
        database.add(operation)
    }
    
    func assimilate(_ ValueTrees: [ValueTree], completionHandler completion: @escaping CompletionHandler) {
        
    }
}


extension ValueTree {
    
    func makeRecord(in zone:CKRecordZone) -> CKRecord {
        let recordName = "\(storageType)__\(metadata.uniqueIdentifier)"
        let recordID = CKRecordID(recordName: recordName, zoneID: zone.zoneID)
        let newRecord = CKRecord(recordType: storageType, recordID: recordID)
        updateRecord(newRecord)
        return newRecord
    }
    
    func updateRecord(_ record: CKRecord) {
    }
    
}


extension CKRecord {
    
    var asValueTree: ValueTree? {
        guard let timestamp = self["metadata.timestamp"] as? TimeInterval,
              let version = self["metadata.version"] as? StorageVersion else {
            return nil
        }
        
        // Record name is storageType + "__" + unique id. This is because in Impeller,
        // the uniqueId only has to be unique for a single storage type
        let recordName = recordID.recordName
        let index = recordName.index(recordName.startIndex, offsetBy: recordType.characters.count+2)
        let uniqueIdentifier = recordName.substring(from:index)
        
        var metadata = Metadata(uniqueIdentifier: uniqueIdentifier)
        metadata.version = version
        metadata.timestamp = timestamp
        
        let valueTree = ValueTree(storageType: recordType, metadata: metadata)
        for key in allKeys() {
            if key.contains(".metadata.") { continue }
            
            let propertyTypeKey = key + ".metadata.propertyType"
            guard
                let value = self[key],
                let propertyTypeInt = self[propertyTypeKey] as? Int,
                let propertyType = PropertyType(rawValue: propertyTypeInt) else {
                continue
            }
            
            let primitiveTypeKey = key + ".metadata.primitiveType"
            let typeInt = self[primitiveTypeKey] as? Int
            let primitiveType = typeInt != nil ? PrimitiveType(rawValue: typeInt!) : nil
            guard !propertyType.isPrimitive || primitiveType != nil else {
                continue
            }
            
            var property: Property?
            switch propertyType {
            case .primitive:
                switch primitiveType! {
                case .string:
                    guard let v = value as? String else { continue }
                    property = .primitive(.string(v))
                case .int:
                    guard let v = value as? Int else { continue }
                    property = .primitive(.int(v))
                case .float:
                    guard let v = value as? Float else { continue }
                    property = .primitive(.float(v))
                case .bool:
                    guard let s = value as? Bool else { continue }
                    property = .primitive(.bool(s))
                case .data:
                    guard let s = value as? Data else { continue }
                    property = .primitive(.data(s))
                }
            case .optionalPrimitive:
                let isNull = (value as? String) == "<<<NULL>>>"
                if isNull {
                    property = .optionalPrimitive(nil)
                }
                else {
                    switch primitiveType! {
                    case .string:
                        guard let v = value as? String else { continue }
                        property = .optionalPrimitive(.string(v))
                    case .int:
                        guard let v = value as? Int else { continue }
                        property = .optionalPrimitive(.int(v))
                    case .float:
                        guard let v = value as? Float else { continue }
                        property = .optionalPrimitive(.float(v))
                    case .bool:
                        guard let v = value as? Bool else { continue }
                        property = .optionalPrimitive(.bool(v))
                    case .data:
                        guard let v = value as? Data else { continue }
                        property = .optionalPrimitive(.data(v))
                    }
                }
            case .primitives:
                switch primitiveType! {
                case .string:
                    guard let v = value as? [String] else { continue }
                    property = .primitives(v.map { .string($0) })
                case .int:
                    guard let v = value as? [Int] else { continue }
                    property = .primitives(v.map { .int($0) })
                case .float:
                    guard let v = value as? [Float] else { continue }
                    property = .primitives(v.map { .float($0) })
                case .bool:
                    guard let v = value as? [Bool] else { continue }
                    property = .primitives(v.map { .bool($0) })
                case .data:
                    guard let v = value as? [Data] else { continue }
                    property = .primitives(v.map { .data($0) })
                }
            case .valueTreeReference:
                guard let v = value as? [String], v.count == 2 else { continue }
                let ref = ValueTreeReference(uniqueIdentifier: v[1], storageType: v[0])
                property = .valueTreeReference(ref)
            case .optionalValueTreeReference:
                let isNull = (value as? String) == "<<<NULL>>>"
                if isNull {
                    property = .optionalValueTreeReference(nil)
                }
                else {
                    guard let v = value as? [String], v.count == 2 else { continue }
                    let ref = ValueTreeReference(uniqueIdentifier: v[1], storageType: v[0])
                    property = .optionalValueTreeReference(ref)
                }
            case .valueTreeReferences:
                guard let v = value as? [[String]] else { continue }
                let refs = v.map { r in r.count == 2 ? ValueTreeReference(uniqueIdentifier: r[1], storageType: r[0]) : nil }.flatMap { $0 }
                property = .valueTreeReferences(refs)
            }
            
            guard let p = property else {
                continue
            }
            
            valueTree.set(key, to: p)
        }
        
        return valueTree
    }
    
}


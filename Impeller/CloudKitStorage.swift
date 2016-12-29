//
//  CloudKitStorage.swift
//  Impeller
//
//  Created by Drew McCormack on 29/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

import Foundation
import CloudKit


struct CloudKitCursor : Cursor {
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


class CloudKitStorage : Exchangable {
    
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


extension CKRecord {
    
    var asValueTree: ValueTree? {
        if  let metadata = self["metadata"] as? [String:Any],
            let uniqueIdentifier = metadata["uniqueIdentifier"] as? UniqueIdentifier,
            let timestamp = metadata["timestamp"] as? TimeInterval,
            let version = metadata["version"] as? StorageVersion,
            let properties = self["properties"] as? [String:Any] {
            
            var metadata = Metadata(uniqueIdentifier: uniqueIdentifier)
            metadata.version = version
            metadata.timestamp = timestamp
            
            var valueTree = ValueTree(storageType: self.recordType, metadata: metadata)
            
            return valueTree
        }
        else {
            return nil
        }
    }
    
}


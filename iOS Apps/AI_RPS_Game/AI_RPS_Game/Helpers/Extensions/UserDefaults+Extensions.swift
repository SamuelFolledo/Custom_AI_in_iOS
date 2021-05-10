//
//  UserDefaults+Extensions.swift
//  StrepScan
//
//  Created by Samuel Folledo on 8/19/20.
//  Copyright © 2020 SamuelFolledo. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    open func setStruct<T: Codable>(_ value: T?, forKey defaultName: String){
        let data = try? JSONEncoder().encode(value)
        set(data, forKey: defaultName)
    }
    
    open func getStruct<T>(_ type: T.Type, forKey defaultName: String) -> T? where T : Decodable {
        guard let encodedData = data(forKey: defaultName) else {
            return nil
        }
        return try! JSONDecoder().decode(type, from: encodedData)
    }
    
    open func setStructArray<T: Codable>(_ value: [T], forKey defaultName: String){
        let data = value.map { try? JSONEncoder().encode($0) }
        set(data, forKey: defaultName)
    }
    
    open func getStructArray<T>(_ type: T.Type, forKey defaultName: String) -> [T] where T : Decodable {
        guard let encodedData = array(forKey: defaultName) as? [Data] else {
            return []
        }
        return encodedData.map { try! JSONDecoder().decode(type, from: $0) }
    }
    
    //delete everything in UserDefaults except for exemptedKeys
    open func deleteAllKeys(exemptedKeys: [String] = []) {
        if exemptedKeys.count == 0 {
            let domain = Bundle.main.bundleIdentifier!
            self.removePersistentDomain(forName: domain)
        } else {
            self.dictionaryRepresentation().keys.forEach { key in
                if !exemptedKeys.contains(key) { //if key is not exempted, delete it
                    self.removeObject(forKey: key)
                }
            }
        }
        self.synchronize()
    }
}

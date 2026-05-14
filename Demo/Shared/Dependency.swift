//
//  Dependency.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import Foundation

final class Dependency {
    static let shared = Dependency()

    private let lock = NSLock()
    private var registerMap: [ObjectIdentifier: (Dependency) -> Any] = [:]
    private var resolveMap: [ObjectIdentifier: Any] = [:]

    private init() {}

    func register<T>(_ type: T.Type, block: @escaping (Dependency) -> T) {
        lock.lock()
        defer { lock.unlock() }
        registerMap[ObjectIdentifier(type)] = block
    }

    func resolve<T>(_ type: T.Type) -> T? {
        lock.lock()
        let key = ObjectIdentifier(type)
        if let resolved = resolveMap[key] as? T {
            lock.unlock()
            return resolved
        }

        guard let factory = registerMap[key] else {
            lock.unlock()
            return nil
        }

        lock.unlock()

        guard let service = factory(self) as? T else {
            return nil
        }

        lock.lock()
        defer { lock.unlock() }

        if let resolved = resolveMap[key] as? T {
            return resolved
        }

        resolveMap[key] = service
        return service
    }
}

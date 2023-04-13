//
//  Optimizer.swift
//  
//
//  Created by Francis Chong on 13/04/2023.
//

import CNGT
import Foundation

class Optimizer {
    private let error: NGTError!
    private let optimizer: NGTOptimizer!

    public enum Error: Swift.Error, LocalizedError {
        case notFound
        case unexpected(String)
    }

    init(outgoing: Int32 = 10, incoming: Int32 = 120, queries: Int32 = 100, lowAccuracyFrom: Float = 0.3, lowAccuracyTo: Float = 0.5, highAccuracyFrom: Float = 0.8, highAccuracyTo: Float = 0.9, gtEpsilon: Double = 0.1, merge: Double = 0.2) {
        error = ngt_create_error_object()
        optimizer = ngt_create_optimizer(true, error)
        ngt_optimizer_set(optimizer, outgoing, incoming, queries, lowAccuracyFrom, lowAccuracyTo, highAccuracyFrom, highAccuracyTo, gtEpsilon, merge, error)
    }

    @discardableResult
    func execute(inIndexPath: String, outIndexPath: String) throws -> Bool {
        let result = inIndexPath.withCString { inIndexPath in
            outIndexPath.withCString { outIndexPath in
                ngt_optimizer_execute(optimizer, inIndexPath, outIndexPath, error)
            }
        }
        try checkAndThrowIfNeeded()
        return result
    }

    @discardableResult
    func execute(inIndex: Index, outIndexPath: String) throws -> Bool {
        guard let inIndexPath = inIndex.path else {
            throw Error.notFound
        }
        let result = try execute(inIndexPath: inIndexPath, outIndexPath: outIndexPath)
        try checkAndThrowIfNeeded()
        return result
    }

    @discardableResult
    func adjustSearchCoefficients(indexPath: String) throws -> Bool {
        let result = indexPath.withCString { indexPath in
            ngt_optimizer_adjust_search_coefficients(optimizer, indexPath, error)
        }
        try checkAndThrowIfNeeded()
        return result
    }

    @discardableResult
    func adjustSearchCoefficients(index: Index) throws -> Bool {
        guard let path = index.path else {
            throw Error.notFound
        }

        let result = try adjustSearchCoefficients(indexPath: path)
        try checkAndThrowIfNeeded()

        return result
    }

    deinit {
        ngt_destroy_error_object(error)
        ngt_destroy_optimizer(optimizer)
    }

    public var errorString: String? {
        guard let errorCStr = ngt_get_error_string(error) else { return nil }
        return String(cString: errorCStr)
    }
    
    private func checkAndThrowIfNeeded() throws {
        if let errorString = errorString, !errorString.isEmpty {
            ngt_clear_error_string(error)
            throw Error.unexpected(errorString)
        }
    }
}

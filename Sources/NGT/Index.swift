import CNGT
import Foundation

public class Index {
    public enum ObjectType: Int {
        case none = 0
        case float = 1
        case float16 = 2
        case integer = 3
    }

    public enum DistanceType: Int {
        case none = -1
        case l1 = 0
        case l2 = 1
        case hamming = 2
        case angle = 3
        case cosine = 4
        case normalizedAngle = 5
        case normalizedCosine = 6
        case jaccard = 7
        case sparseJaccard = 8
        case normalizedL2 = 9
        case poincare = 100
        case lorentz = 101
    }

    public typealias ObjectId = UInt32

    public struct ObjectDistance {
        public let id: ObjectId
        public let distant: Float
    }

    public enum Error: Swift.Error, LocalizedError {
        case invalidDimension
        case unexpected(String)
    }

    private var index: NGTIndex!
    private var property: NGTProperty!
    private var error: NGTError!
    public var path: String?

    public init(dimensions: Int32?, path: String? = nil, edgeSizeForCreation: Int = 10, edgeSizeForSearch: Int = 40, objectType: ObjectType = .float, distanceType: DistanceType = .l2) {
        let error = ngt_create_error_object()

        if let path = path, dimensions == nil {
            index = path.withCString { cString in
                ngt_open_index(cString, error)
            }
            property = ngt_create_property(error)
        } else if let dimensions = dimensions {
            let property = ngt_create_property(error)
            ngt_set_property_dimension(property, dimensions, error)
            ngt_set_property_edge_size_for_creation(property, Int16(edgeSizeForCreation), error)
            ngt_set_property_edge_size_for_search(property, Int16(edgeSizeForSearch), error)

            switch objectType {
            case .float:
                ngt_set_property_object_type_float(property, error)
            case .float16:
                ngt_set_property_object_type_float16(property, error)
            case .integer:
                ngt_set_property_object_type_integer(property, error)
            case .none:
                fatalError()
            }

            switch distanceType {
            case .l1:
                ngt_set_property_distance_type_l1(property, error)
            case .l2:
                ngt_set_property_distance_type_l2(property, error)
            case .angle:
                ngt_set_property_distance_type_angle(property, error)
            case .hamming:
                ngt_set_property_distance_type_hamming(property, error)
            case .jaccard:
                ngt_set_property_distance_type_jaccard(property, error)
            case .cosine:
                ngt_set_property_distance_type_cosine(property, error)
            case .sparseJaccard:
                ngt_set_property_distance_type_sparse_jaccard(property, error)
            case .lorentz:
                ngt_set_property_distance_type_lorentz(property, error)
            case .normalizedL2:
                ngt_set_property_distance_type_normalized_l2(property, error)
            case .normalizedAngle:
                ngt_set_property_distance_type_normalized_angle(property, error)
            case .normalizedCosine:
                ngt_set_property_distance_type_normalized_cosine(property, error)
            case .poincare:
                ngt_set_property_distance_type_poincare(property, error)
            case .none:
                fatalError()
            }

            if let path = path {
                index = path.withCString { pathCString in
                    ngt_create_graph_and_tree(pathCString, property, error)
                }
            } else {
                index = ngt_create_graph_and_tree_in_memory(property, error)
            }
            self.property = property
        }
        self.path = path
        self.error = error
    }

    public var dimension: Int {
        Int(ngt_get_property_dimension(property, error))
    }

    public var distanceType: DistanceType {
        guard let distanceType = DistanceType(rawValue: Int(ngt_get_property_distance_type(property, error))) else {
            fatalError()
        }
        return distanceType
    }

    public var edgeSizeForCreation: Int {
        Int(ngt_get_property_edge_size_for_creation(property, error))
    }

    public var edgeSizeForSearch: Int {
        Int(ngt_get_property_edge_size_for_search(property, error))
    }

    public var objectType: ObjectType {
        let type = ngt_get_property_object_type(property, error)
        if ngt_is_property_object_type_float(type) {
            return .float
        } else if ngt_is_property_object_type_float16(type) {
            return .float16
        } else {
            return .integer
        }
    }

    public func insert(_ values: [Double]) throws -> UInt32 {
        if values.count != dimension {
            throw Error.invalidDimension
        }

        var values = values
        let result = values.withUnsafeMutableBufferPointer { bufferPointer in
            ngt_insert_index(index, bufferPointer.baseAddress, UInt32(bufferPointer.count), nil)
        }

        try checkAndThrowIfNeeded()

        return result
    }

    public func batchInsert(_ values: [[Double]], numOfThreads: UInt32 = 1) throws -> [ObjectId] {
        // validate inputs
        for value in values {
            if value.count != dimension {
                throw Error.invalidDimension
            }
        }

        let count = values.count
        var ids: [UInt32] = Array(repeating: 0, count: values.count)

        var values: [Float] = values.flatMap { $0 }.map { Float($0) } // flatten array
        _ = ids.withUnsafeMutableBufferPointer { idsPointer in
            return values.withUnsafeMutableBufferPointer { valuesPointer in
                ngt_batch_insert_index(index, valuesPointer.baseAddress, UInt32(count), idsPointer.baseAddress, error)
            }
        }
        if let error = errorString, !error.isEmpty {
            throw Error.unexpected(error)
        }

        try createIndex(numOfThreads)
        try checkAndThrowIfNeeded()

        return ids
    }

    public func remove(id: UInt32) throws {
        ngt_remove_index(index, id, error)

        try checkAndThrowIfNeeded()
    }

    public func search(query: [Double], size: Int = 3, epsilon: Float = 0.1, radius: Float = -1.0) throws -> [ObjectDistance] {
        if query.count != dimension {
            throw Error.invalidDimension
        }

        let results = ngt_create_empty_results(error)
        var query = query
        _ = query.withUnsafeMutableBufferPointer { bufferPointer in
            ngt_search_index(index, bufferPointer.baseAddress, Int32(bufferPointer.count), size, epsilon, radius, results, error)
        }
        let resultSize = ngt_get_result_size(results, error)
        var distances: [ObjectDistance] = []
        for index in 0..<resultSize {
            let res = ngt_get_result(results, index, error)
            distances.append(ObjectDistance(id: res.id, distant: res.distance))
        }

        try checkAndThrowIfNeeded()

        return distances
    }

    @discardableResult
    public func save(path: String) throws -> Bool {
        let result = path.withCString { cString in
            ngt_save_index(index, cString, error)
        }
        try checkAndThrowIfNeeded()
        self.path = path
        return result
    }

    public func close() {
        ngt_close_index(index)
    }

    public func createIndex(_ numOfThreads: UInt32 = 4) throws {
        ngt_create_index(index, numOfThreads, error)

        try checkAndThrowIfNeeded()
    }

    public func objectAsInt(_ id: ObjectID) -> UInt8? {
        guard let val = ngt_get_object_as_integer(objectSpace, id, error) else {
            return nil
        }
        return val.pointee
    }

    public func objectAsFloat(_ id: ObjectID) -> Float? {
        guard let val = ngt_get_object_as_float(objectSpace, id, error) else {
            return nil
        }
        return val.pointee
    }

    public var errorString: String? {
        guard let errorCStr = ngt_get_error_string(error) else { return nil }
        return String(cString: errorCStr)
    }

    private var objectSpace: NGTObjectSpace {
        ngt_get_object_space(index, error)
    }

    deinit {
        ngt_destroy_error_object(error)
        ngt_close_index(index)
        ngt_destroy_property(property)
    }

    private func checkAndThrowIfNeeded() throws {
        if let errorString = errorString, !errorString.isEmpty {
            ngt_clear_error_string(error)
            throw Error.unexpected(errorString)
        }
    }
}

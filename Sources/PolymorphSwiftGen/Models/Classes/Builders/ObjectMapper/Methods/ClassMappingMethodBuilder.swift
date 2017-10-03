//
//  ClassMappingMethodBuilder.swift
//  PolymorphSwiftGen
//
//  Created by Benoit BRIATTE on 29/08/2017.
//
//

import Foundation
import PolymorphCore
import CodeWriter
import SwiftCodeWriter

struct ClassMappingMethodBuilder: ClassMethodDescriptionBuilder {

    public static let `default` = ClassMappingMethodBuilder()

    private init() { }

    func build(element: Class) throws -> MethodDescription? {
        guard let project = element.project else {
            return nil
        }
        let impl = CodeBuilder()
        var modules = Set<String>()
        modules.insert("ObjectMapper")

        if element.extends != nil {
            impl.add(line: "super.mapping(map: map)")
        }

        for property in element.properties {
            if property.isNonnull {
                impl.add(line: "self.\(property.name) >>> \(try self.mapProperty(property, project: project))")
            } else {
                impl.add(line: "self.\(property.name) <- \(try self.mapProperty(property, project: project))")
            }
            modules.formUnion(try Mapping.shared.modules(with: property))
        }
        return MethodDescription(name: "mapping", code: impl, options: .init(visibility: .public), modules: Array(modules), arguments: ["map: Map"])
    }

    private func mapProperty(_ property: Property, project: Project) throws -> String {
        let type = try Mapping.model(with: property)
        if let c = type as? Class {
            if c.injectable || c.serializable {
                return self.mapProperty(property, injectedClass: c)
            }
        } else if type.name == Native.DataType.array.rawValue, let gts = property.genericTypes, gts.count > 0 {
            let genericType = try Mapping.model(with: gts[0], project: project)
            if let c = genericType as? Class {
                if c.injectable || c.serializable {
                    return self.mapProperty(property, injectedClass: c)
                }
            }
        }
        return self.mapProperty(property)
    }

    private func mapProperty(_ property: Property, injectedClass: Class) -> String {
        return "map.inject(\"\(property.mapping?.key ?? property.name)\", type: \(injectedClass.name).self)"
    }

    private func mapProperty(_ property: Property) -> String {
        return "map[\"\(property.mapping?.key ?? property.name)\"]"
    }
    
}
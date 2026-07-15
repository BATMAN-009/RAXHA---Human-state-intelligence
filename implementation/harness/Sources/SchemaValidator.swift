import Foundation

// Minimal JSON-Schema-subset validator for VV-110. Supports exactly what
// shared/contracts/if-int-objects.schema.json uses: type, required, properties, enum,
// minimum/maximum, minLength, $ref into definitions. Deliberately small — the point is
// contract drift detection between the Swift types and the 08B transcription, not
// general-purpose schema tooling.

struct SchemaViolation: Codable {
    var path: String
    var message: String
}

struct ContractSchemas {
    let definitions: [String: Any]

    init(schemaFileURL: URL) throws {
        let data = try Data(contentsOf: schemaFileURL)
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let defs = root["definitions"] as? [String: Any]
        else {
            throw NSError(domain: "raxha-harness", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "schema file missing definitions"])
        }
        definitions = defs
    }

    /// Validate an Encodable value against a named definition; returns violations (empty = conforms).
    func validate<T: Encodable>(_ value: T, against definitionName: String) throws -> [SchemaViolation] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(value)
        let json = try JSONSerialization.jsonObject(with: data)
        guard let schema = definitions[definitionName] as? [String: Any] else {
            return [SchemaViolation(path: "$", message: "no definition named \(definitionName)")]
        }
        var violations: [SchemaViolation] = []
        check(json, schema: schema, path: "$", violations: &violations)
        return violations
    }

    /// Portable numeric extraction: JSONSerialization yields NSNumber on Darwin but may
    /// yield native Int/Double under swift-corelibs-foundation (Windows/Linux).
    /// CAUTION: `json is Bool` is NOT a safe boolean test — NSNumber values of exactly
    /// 0 or 1 pass it, which misclassified quality 0.0 / risk 1.0 / seq 1 as booleans
    /// (caught by VV-110's very first run). objCType "c" is the reliable discriminator.
    private func numericValue(_ json: Any) -> Double? {
        if let n = json as? NSNumber {
            if String(cString: n.objCType) == "c" { return nil } // genuine JSON boolean
            return n.doubleValue
        }
        if let i = json as? Int { return Double(i) }
        if let i = json as? Int64 { return Double(i) }
        if let d = json as? Double { return d }
        return nil
    }

    private func check(_ json: Any, schema: [String: Any], path: String,
                       violations: inout [SchemaViolation]) {
        if let ref = schema["$ref"] as? String {
            guard let resolved = definitions[ref] as? [String: Any] else {
                violations.append(SchemaViolation(path: path, message: "unresolvable $ref \(ref)"))
                return
            }
            check(json, schema: resolved, path: path, violations: &violations)
            return
        }

        if let type = schema["type"] as? String {
            let ok: Bool
            switch type {
            case "object": ok = json is [String: Any]
            case "array": ok = json is [Any]
            case "string": ok = json is String
            case "integer":
                if let d = numericValue(json) {
                    ok = d.truncatingRemainder(dividingBy: 1) == 0
                } else {
                    ok = false
                }
            case "number": ok = numericValue(json) != nil
            case "boolean": ok = json is Bool
            default: ok = true
            }
            if !ok {
                violations.append(SchemaViolation(path: path, message: "expected \(type)"))
                return
            }
        }

        if let s = json as? String {
            if let allowed = schema["enum"] as? [String], !allowed.contains(s) {
                violations.append(SchemaViolation(path: path, message: "'\(s)' not in enum \(allowed)"))
            }
            if let minLength = schema["minLength"] as? Int, s.count < minLength {
                violations.append(SchemaViolation(path: path, message: "shorter than minLength \(minLength)"))
            }
        }

        if let v = numericValue(json) {
            if let minimum = (schema["minimum"] as? NSNumber)?.doubleValue, v < minimum {
                violations.append(SchemaViolation(path: path, message: "\(v) below minimum \(minimum)"))
            }
            if let maximum = (schema["maximum"] as? NSNumber)?.doubleValue, v > maximum {
                violations.append(SchemaViolation(path: path, message: "\(v) above maximum \(maximum)"))
            }
        }

        if let object = json as? [String: Any] {
            if let required = schema["required"] as? [String] {
                for key in required {
                    // A present-but-null required field is still missing (AUDIT-002: JSONSerialization
                    // decodes JSON null as NSNull, not absence, so `== nil` alone let null slip through).
                    if object[key] == nil || object[key] is NSNull {
                        violations.append(SchemaViolation(path: "\(path).\(key)", message: "required property missing or null"))
                    }
                }
            }
            if let properties = schema["properties"] as? [String: Any] {
                for (key, sub) in properties {
                    if let value = object[key], !(value is NSNull), let subSchema = sub as? [String: Any] {
                        check(value, schema: subSchema, path: "\(path).\(key)", violations: &violations)
                    }
                }
                // Strict-by-default when a schema declares its properties: an object carrying a key
                // the schema does not name is drift (a Swift field added without updating 08B/the
                // transcription). This is the additive half of "contract drift detection" the
                // validator previously ignored (AUDIT-002). Bare `{"type":"object"}` sub-objects
                // (no declared properties) are exempt — they are intentionally opaque.
                for key in object.keys where properties[key] == nil {
                    violations.append(SchemaViolation(path: "\(path).\(key)", message: "unknown property not declared in schema (contract drift)"))
                }
            }
        }
    }
}

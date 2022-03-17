// This converts arrays of FixedWidthIntegers from their source type to a destination type.
// It's total spaghetti, but it works like a charm, and the symmetry is pretty to look at.

// Usually returns the same number wrapped in a larger type, but for cases where the source type is smaller,
// it splits the bitpattern into equal chunks, converts each chunk to its respective number, and removes
// the leading zeroes in the array.

public struct StreamTypeConverter {
    public static func convert<T: FixedWidthInteger, U: FixedWidthInteger>(_ stream: [T], toType destinationType: U) -> [U] {
        if stream.isEmpty { return [U]() }
        
        switch stream.first! {
        case is Int8:
            switch destinationType {
            case is Int8:   return stream.map { $0        as! U }
            case is Int16:  return stream.map { Int16($0) as! U }
            case is Int32:  return stream.map { Int32($0) as! U }
            case is Int64:  return stream.map { Int64($0) as! U }
            
            case is UInt8:  return stream.map { UInt8(bitPattern: $0 as! Int8) as! U }
            case is UInt16: return stream.map { UInt16(bitPattern: Int16($0))  as! U }
            case is UInt32: return stream.map { UInt32(bitPattern: Int32($0))  as! U }
            case is UInt64: return stream.map { UInt64(bitPattern: Int64($0))  as! U }
                
            default: return [U]() // 'Int' and 'UInt' are outside the scope of this function for now
            }
        case is Int16:
            switch destinationType {
            case is Int8:   return stream.map { _16to8($0 as! Int16) }.joined().map { $0 as! U }
            case is Int16:  return stream.map { $0        as! U }
            case is Int32:  return stream.map { Int32($0) as! U }
            case is Int64:  return stream.map { Int64($0) as! U }
            
            case is UInt8:  return stream.map { _16to8($0 as! Int16) }.joined().map { UInt8(bitPattern: $0) as! U }
            case is UInt16: return stream.map { UInt16(bitPattern: $0 as! Int16)  as! U }
            case is UInt32: return stream.map { UInt32(bitPattern: Int32($0))     as! U }
            case is UInt64: return stream.map { UInt64(bitPattern: Int64($0))     as! U }
                
            default: return [U]() // 'Int' and 'UInt' are outside the scope of this function for now
            }
        case is Int32:
            switch destinationType {
            case is Int8:   return stream.map { _32to8 ($0 as! Int32) }.joined().map { $0 as! U }
            case is Int16:  return stream.map { _32to16($0 as! Int32) }.joined().map { $0 as! U }
            case is Int32:  return stream.map { $0        as! U }
            case is Int64:  return stream.map { Int64($0) as! U }
            
            case is UInt8:  return stream.map { _32to8 ($0 as! Int32) }.joined().map { UInt8 (bitPattern: $0) as! U }
            case is UInt16: return stream.map { _32to16($0 as! Int32) }.joined().map { UInt16(bitPattern: $0) as! U }
            case is UInt32: return stream.map { UInt32(bitPattern: $0 as! Int32)  as! U }
            case is UInt64: return stream.map { UInt64(bitPattern: Int64($0))     as! U }
                
            default: return [U]() // 'Int' and 'UInt' are outside the scope of this function for now
            }
        case is Int64:
            switch destinationType {
            case is Int8:   return stream.map { _64to8 ($0 as! Int64) }.joined().map { $0 as! U }
            case is Int16:  return stream.map { _64to16($0 as! Int64) }.joined().map { $0 as! U }
            case is Int32:  return stream.map { _64to32($0 as! Int64) }.joined().map { $0 as! U }
            case is Int64:  return stream.map { $0 as! U }
            
            case is UInt8:  return stream.map { _64to8 ($0 as! Int64) }.joined().map { UInt8 (bitPattern: $0) as! U }
            case is UInt16: return stream.map { _64to16($0 as! Int64) }.joined().map { UInt16(bitPattern: $0) as! U }
            case is UInt32: return stream.map { _64to32($0 as! Int64) }.joined().map { UInt32(bitPattern: $0) as! U }
            case is UInt64: return stream.map { UInt64(bitPattern: $0 as! Int64) as! U }
                
            default: return [U]() // 'Int' and 'UInt' are outside the scope of this function for now
            }
            
        case is UInt8:
            switch destinationType {
            case is Int8:   return stream.map { Int8(bitPattern: $0 as! UInt8) as! U }
            case is Int16:  return stream.map { Int16(bitPattern: UInt16($0))  as! U }
            case is Int32:  return stream.map { Int32(bitPattern: UInt32($0))  as! U }
            case is Int64:  return stream.map { Int64(bitPattern: UInt64($0))  as! U }
            
            case is UInt8:  return stream.map { $0          as! U }
            case is UInt16: return stream.map { UInt16($0)  as! U }
            case is UInt32: return stream.map { UInt32($0)  as! U }
            case is UInt64: return stream.map { UInt64($0)  as! U }
                
            default: return [U]() // 'Int' and 'UInt' are outside the scope of this function for now
            }
        case is UInt16:
            switch destinationType {
            case is Int8:   return stream.map { _16to8(Int16(bitPattern: $0 as! UInt16)) }.joined().map { $0 as! U }
            case is Int16:  return stream.map { Int16(bitPattern: $0 as! UInt16) as! U }
            case is Int32:  return stream.map { Int32(bitPattern: UInt32($0))    as! U }
            case is Int64:  return stream.map { Int64(bitPattern: UInt64($0))    as! U }
            
            case is UInt8:  return stream.map { _16to8(Int16(bitPattern: $0 as! UInt16)) }.joined().map { UInt8(bitPattern: $0) as! U }
            case is UInt16: return stream.map { $0         as! U }
            case is UInt32: return stream.map { UInt32($0) as! U }
            case is UInt64: return stream.map { UInt64($0) as! U }
                
            default: return [U]() // 'Int' and 'UInt' are outside the scope of this function for now
            }
        case is UInt32:
            switch destinationType {
            case is Int8:   return stream.map { _32to8 (Int32(bitPattern: $0 as! UInt32)) }.joined().map { $0 as! U }
            case is Int16:  return stream.map { _32to16(Int32(bitPattern: $0 as! UInt32)) }.joined().map { $0 as! U }
            case is Int32:  return stream.map { Int32(bitPattern: $0 as! UInt32) as! U }
            case is Int64:  return stream.map { Int64(bitPattern: UInt64($0))    as! U }
            
            case is UInt8:  return stream.map { _32to8 (Int32(bitPattern: $0 as! UInt32)) }.joined().map { UInt8 (bitPattern: $0) as! U }
            case is UInt16: return stream.map { _32to16(Int32(bitPattern: $0 as! UInt32)) }.joined().map { UInt16(bitPattern: $0) as! U }
            case is UInt32: return stream.map { $0         as! U }
            case is UInt64: return stream.map { UInt64($0) as! U }
                
            default: return [U]() // 'Int' and 'UInt' are outside the scope of this function for now
            }
        case is UInt64:
            switch destinationType {
            case is Int8:   return stream.map { _64to8 (Int64(bitPattern: $0 as! UInt64)) }.joined().map { $0 as! U }
            case is Int16:  return stream.map { _64to16(Int64(bitPattern: $0 as! UInt64)) }.joined().map { $0 as! U }
            case is Int32:  return stream.map { _64to32(Int64(bitPattern: $0 as! UInt64)) }.joined().map { $0 as! U }
            case is Int64:  return stream.map { Int64(bitPattern: $0 as! UInt64) as! U }
            
            case is UInt8:  return stream.map { _64to8 (Int64(bitPattern: $0 as! UInt64)) }.joined().map { UInt8 (bitPattern: $0) as! U }
            case is UInt16: return stream.map { _64to16(Int64(bitPattern: $0 as! UInt64)) }.joined().map { UInt16(bitPattern: $0) as! U }
            case is UInt32: return stream.map { _64to32(Int64(bitPattern: $0 as! UInt64)) }.joined().map { UInt32(bitPattern: $0) as! U }
            case is UInt64: return stream.map { $0 as! U }
                
            default: return [U]() // 'Int' and 'UInt' are outside the scope of this function for now
            }
            
        default: return [U]() // 'Int' and 'UInt' are outside the scope of this function for now
        }
    }
    
    private static func _16to8(_ x: Int16) -> [Int8] {
        var words: [Int8] = []
        
        let a = Int8(truncatingIfNeeded: x >> 8)
        let b = Int8(truncatingIfNeeded: x)
        
        if a != 0 { words.append(a) }
        words.append(b)
        
        return words
    }
    
    private static func _32to8(_ x: Int32) -> [Int8] {
        var words: [Int8] = []
        
        let a = Int8(truncatingIfNeeded: x >> 24)
        let b = Int8(truncatingIfNeeded: x >> 16)
        let c = Int8(truncatingIfNeeded: x >> 8)
        let d = Int8(truncatingIfNeeded: x)
        
        if a != 0                     { words.append(a) }
        if b != 0 || a != 0           { words.append(b) }
        if c != 0 || b != 0 || a != 0 { words.append(c) }
        words.append(d)
        
        return words
    }
    
    private static func _64to8(_ x: Int64) -> [Int8] {
        var words: [Int8] = []
        
        let a = Int8(truncatingIfNeeded: x >> 56)
        let b = Int8(truncatingIfNeeded: x >> 48)
        let c = Int8(truncatingIfNeeded: x >> 40)
        let d = Int8(truncatingIfNeeded: x >> 32)
        let e = Int8(truncatingIfNeeded: x >> 24)
        let f = Int8(truncatingIfNeeded: x >> 16)
        let g = Int8(truncatingIfNeeded: x >> 8)
        let h = Int8(truncatingIfNeeded: x)
        
        if a != 0                                                             { words.append(a) }
        if b != 0 || a != 0                                                   { words.append(b) }
        if c != 0 || b != 0 || a != 0                                         { words.append(c) }
        if d != 0 || c != 0 || b != 0 || a != 0                               { words.append(d) }
        if e != 0 || d != 0 || c != 0 || b != 0 || a != 0                     { words.append(e) }
        if f != 0 || e != 0 || d != 0 || c != 0 || b != 0 || a != 0           { words.append(f) }
        if g != 0 || f != 0 || e != 0 || d != 0 || c != 0 || b != 0 || a != 0 { words.append(g) }
        words.append(h)
        
        return words
    }
    
    private static func _32to16(_ x: Int32) -> [Int16] {
        var words: [Int16] = []
        
        let a = Int16(truncatingIfNeeded: x >> 16)
        let b = Int16(truncatingIfNeeded: x)
        
        if a != 0 { words.append(a) }
        words.append(b)
        
        return words
    }
    
    private static func _64to16(_ x: Int64) -> [Int16] {
        var words: [Int16] = []
        
        let a = Int16(truncatingIfNeeded: x >> 48)
        let b = Int16(truncatingIfNeeded: x >> 32)
        let c = Int16(truncatingIfNeeded: x >> 16)
        let d = Int16(truncatingIfNeeded: x)
        
        if a != 0                     { words.append(a) }
        if b != 0 || a != 0           { words.append(b) }
        if c != 0 || b != 0 || a != 0 { words.append(c) }
        words.append(d)
        
        return words
    }
    
    private static func _64to32(_ x: Int64) -> [Int32] {
        var words: [Int32] = []
        
        let a = Int32(truncatingIfNeeded: x >> 32)
        let b = Int32(truncatingIfNeeded: x)
        
        if a != 0 { words.append(a) }
        words.append(b)
        
        return words
    }
}

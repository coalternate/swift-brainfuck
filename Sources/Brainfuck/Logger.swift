// temporarily permanent for now. will absolutely change in the future.
public struct BFILogger {
    public static var cycles = 0
    public static var scans  = 0

    static func nextCycle() { BFILogger.cycles += 1 }
    static func nextScan()  { BFILogger.scans  += 1 }
}

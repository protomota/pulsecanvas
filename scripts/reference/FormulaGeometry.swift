import Foundation

// Numerical fixtures only; excluded from both app targets.
enum FormulaReference {
    static var formulaIDs: Set<Int> { SurfaceGeometry.formulaIDs.union([7, 12, 52, 71, 88]) }
    static func height(formulaID: Int, x: Double, y: Double, xMax: Double = 240, yMax: Double = 240) -> Double {
        switch formulaID {
        case 7: // 0x100403d10
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 - value1)
            return value2
        case 12: // 0x100403d4c
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = -(x * x)
            let value4: Double = (value3 - value1)
            let value5: Double = (value4 * 0.01)
            let value6: Double = exp(value5)
            let value7: Double = (value2 * value6)
            return value7
        case 52: // 0x100403ec0
            let value0: Double = (xMax * yMax)
            let value1: Double = (x * x)
            let value2: Double = (value0 - value1)
            let value3: Double = (y * y)
            let value4: Double = abs(value2 - value3)
            let value5: Double = pow(value4, 0.8)
            return value5
        case 88: // 0x100403fa4
            let value0: Double = (y * 8.0)
            let value1: Double = (value0 + x)
            let value2: Double = (x + x)
            let value3: Double = (value0 - value2)
            let value4: Double = (value3 / xMax)
            let value5: Double = cos(value4)
            let value6: Double = (value1 * value5)
            return value6
        case 71: // 0x1004040c0
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (value2 * value2)
            let value4: Double = (value3 * 5e-07)
            let value5: Double = (value4 - value0)
            let value6: Double = (value1 + value5)
            return value6
        default: return SurfaceGeometry.height(formulaID: formulaID, x: x, y: y, xMax: xMax, yMax: yMax)
        }
    }
}

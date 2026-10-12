import Foundation
import simd

/// Scalar geometry translated from ARM64 reference instructions. Addresses are
/// unslid Mach-O virtual addresses. This is source reconstructed from compiled
/// code, preserving floating-point operations and native constants.
/// Math calls and floating-point registers were traced in the native assembly
/// because Ghidra's inferred Swift return conventions are sometimes incorrect.
enum SurfaceGeometry {
    struct GridSpec {
        var xMax: Double = 240
        var yMax: Double = 240
        var step: Double = 4
        var adjust: Double = 20
    }

    enum PointScene: Int, CaseIterable {
        case lumenVeil = 0, prismWake = 1, pulseWell = 2

        // Numeric profile IDs are stable for geometry fixtures and saved projects.
        var formulaPool: [Int] {
            switch self {
            case .lumenVeil: // Static Swift array at 0x100a96730
                return [2, 8, 19, 10, 13, 14, 15, 16, 27, 28, 29, 30, 31, 32, 23, 22, 35, 36, 37, 38, 77, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 50, 74, 1, 78, 53, 54, 11, 55, 56, 68, 21, 59, 69, 62, 79]
            case .prismWake: // Static Swift array at 0x100a968c8
                return [80, 81, 19, 83, 84, 85, 86, 87, 8, 89, 90, 91, 31, 93, 94, 95, 23, 13, 27, 28, 69, 40, 62]
            case .pulseWell: // Static Swift array at 0x100a969a8
                return [96, 97, 98, 99, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113]
            }
        }

        // Profile pools are filtered against the available formula library in
        // 0x100408f14. Some pool IDs have no catalog entry in this build.
        var availableFormulaPool: [Int] {
            formulaPool.filter { SurfaceGeometry.formulaIDs.contains($0) }
        }

        // Scene lookup tables at 0x1007b1064, 0x1007b1070, 0x1007b107c,
        // loaded by native 0x1004086d4.
        var haloSize: Float { [3, 2.3, 3][rawValue] }
        var cameraZoom: Float { [1, 1.3, 1.3][rawValue] }
        var morphLength: Int { 110 }
    }

    struct PointDefaults {
        var projectionFov: Float = 56
        var modelScale: Float = Float(bitPattern: 0x3c9374bc)
        var cameraDistance: Float = 120
        var coreSize: Float = 1.3
        var coreAlpha: Float = 0.95
        var haloAlpha: Float = 0.45
    }

    static let formulaIDs: Set<Int> = [78, 97, 105, 14, 42, 41, 53, 68, 37, 23, 93, 35, 40, 8, 1, 21, 77, 79, 19, 27, 28, 29, 32, 96, 98, 99, 101, 102, 106, 104, 107, 108, 110, 111, 103, 109, 112, 113, 15, 16, 39, 74, 2, 22, 43, 44, 45, 46, 47, 48, 50, 54, 55, 56, 62, 13, 80, 81, 83, 84, 85, 86, 87, 89, 90, 91, 94, 95, 10, 11, 30, 31, 36, 38]

    /// Native scalar-grid builder 0x100405944, GridSpec constructed in
    /// point-grid controller 0x10040bcb4. The native grid is 120 × 120 = 14,400 points.
    /// x and y use a 1.2 scale; z is the selected scalar formula times adjust.
    /// Native singularities (NaN/infinity) are retained for algorithm parity.
    static func pointGrid(formulaID: Int, grid: GridSpec = GridSpec()) -> [SIMD3<Float>] {
        guard formulaIDs.contains(formulaID), grid.step > 0,
              grid.xMax > 0, grid.yMax > 0,
              grid.step.isFinite, grid.xMax.isFinite, grid.yMax.isFinite else { return [] }
        var points: [SIMD3<Float>] = []
        let columns = (2 * grid.xMax / grid.step).rounded(.up)
        let rows = (2 * grid.yMax / grid.step).rounded(.up)
        guard columns.isFinite, rows.isFinite, columns <= 4096, rows <= 4096 else { return [] }
        let countX = Int(columns)
        let countY = Int(rows)
        points.reserveCapacity(countX * countY)
        var x = -grid.xMax
        while x < grid.xMax {
            var y = -grid.yMax
            while y < grid.yMax {
                let z = height(formulaID: formulaID, x: x, y: y, xMax: grid.xMax, yMax: grid.yMax)
                points.append(SIMD3(Float(grid.adjust * 1.2 * x), Float(grid.adjust * 1.2 * y), Float(z * grid.adjust)))
                y += grid.step
            }
            x += grid.step
        }
        return points
    }

    /// Native linear interpolation 0x100408248. No easing function is applied.
    static func morph(_ first: [SIMD3<Float>], _ second: [SIMD3<Float>], count: Int, length: Int) -> [SIMD3<Float>] {
        guard first.count == second.count, length > 0 else { return [] }
        let secondWeight = (1 / Float(length)) * Float(count)
        let firstWeight = (1 / Float(length)) * Float(length - count)
        return zip(first, second).map { $0 * firstWeight + $1 * secondWeight }
    }

    /// The 74 formulas reachable from the scene pools. Five unused catalog entries
    /// are retained only in scripts/reference for numerical verification.
    /// Each case below follows its native scalar/SIMD-double instruction order.
    static func height(formulaID: Int, x: Double, y: Double, xMax: Double = 240, yMax: Double = 240) -> Double {
        switch formulaID {
        case 78: // 0x100403d20
            let value0: Double = (y * y)
            let value1: Double = (x * -0.35)
            let value2: Double = (value1 * x)
            let value3: Double = (value0 + value2)
            let value4: Double = (value3 * 0.1)
            return value4
        case 97: // 0x100403d8c
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (value2 * 9.0)
            let value4: Double = -(x * x)
            let value5: Double = (value4 - value1)
            let value6: Double = (value5 * 0.003)
            let value7: Double = exp(value6)
            let value8: Double = (value3 * value7)
            return value8
        case 105: // 0x100403dd4
            let value0: Double = (y + -12.0)
            let value1: Double = (x * x)
            let value2: Double = (y * y)
            let value3: Double = (value1 + value2)
            let value4: Double = (value3 * 0.4)
            let value5: Double = -(x * x)
            let value6: Double = (value0 * value0)
            let value7: Double = (value5 - value6)
            let value8: Double = (value7 * 0.0016)
            let value9: Double = exp(value8)
            let value10: Double = (value4 * value9)
            return value10
        case 14: // 0x100403e2c
            let value0: Double = (x * x)
            let value1: Double = (value0 - y)
            let value2: Double = (value1 * 0.1)
            let value3: Double = (x * y)
            let value4: Double = (value3 * -0.01)
            let value5: Double = exp(value4)
            let value6: Double = (value2 * value5)
            return value6
        case 42: // 0x100403e70
            let value0: Double = (x + y)
            let value1: Double = (value0 * -0.01)
            let value2: Double = exp(value1)
            let value3: Double = (value0 * value2)
            return value3
        case 41: // 0x100403ea0
            let value0: Double = (xMax * yMax)
            let value1: Double = (x * x)
            let value2: Double = (value0 - value1)
            let value3: Double = (y * y)
            let value4: Double = abs(value2 - value3)
            let value5: Double = sqrt(value4)
            let value6: Double = abs(value5)
            return value6
        case 53: // 0x100403ee0
            let value0: Double = (xMax * yMax)
            let value1: Double = (x * x)
            let value2: Double = (value0 - value1)
            let value3: Double = (y * y)
            let value4: Double = (value3 + value2)
            let value5: Double = abs(value4)
            let value6: Double = sqrt(value5)
            let value7: Double = abs(value6)
            return value7
        case 68: // 0x100403f04
            let value0: Double = (xMax * yMax)
            let value1: Double = (x * x)
            let value2: Double = (value1 * x)
            let value3: Double = (value0 - value2)
            let value4: Double = (value1 + value3)
            let value5: Double = (y * y)
            let value6: Double = (value4 - value5)
            let value7: Double = (value2 + value0)
            let value8: Double = (value7 - value1)
            let value9: Double = (value5 + value8)
            let value10: Double = (value6 / value9)
            let value11: Double = abs(value10)
            let value12: Double = sqrt(value11)
            let value13: Double = abs(value12)
            let value14: Double = (value13 * 10.0)
            return value14
        case 37: // 0x100403f48
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 - value1)
            let value3: Double = (value2 * x)
            let value4: Double = (value3 * y)
            let value5: Double = (value0 + value1)
            let value6: Double = (value4 / value5)
            return value6
        case 23: // 0x100403f68
            let value0: Double = (y + y)
            let value1: Double = (value0 + x)
            let value2: Double = (x + x)
            let value3: Double = (y * 8.0)
            let value4: Double = (value2 + value3)
            let value5: Double = (value4 / xMax)
            let value6: Double = cos(value5)
            let value7: Double = (value1 * value6)
            return value7
        case 93: // 0x100403fdc
            let value0: Double = (x + y)
            let value1: Double = (x + x)
            let value2: Double = (y * 8.0)
            let value3: Double = (value1 + value2)
            let value4: Double = (value3 / xMax)
            let value5: Double = cos(value4)
            let value6: Double = (value0 * value5)
            let value7: Double = (x * 8.0)
            let value8: Double = (y + y)
            let value9: Double = (value7 + value8)
            let value10: Double = (value9 / xMax)
            let value11: Double = sin(value10)
            let value12: Double = (value11 * value6)
            return value12
        case 35: // 0x100404048
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = sqrt(value2)
            let value4: Double = cos(value3)
            let value5: Double = (value2 + 0.25)
            let value6: Double = sqrt(value5)
            let value7: Double = abs(value6)
            let value8: Double = (3.141592653589793 / value7)
            let value9: Double = abs(value8)
            let value10: Double = (value4 + value9)
            return value10
        case 40: // 0x100404098
            let value0: Double = (x + y)
            let value1: Double = sin(value0)
            return value1
        case 8: // 0x1004040a0
            let value0: Double = (y / x)
            let value1: Double = atan(value0)
            let value2: Double = (value1 * 10.0)
            return value2
        case 1: // 0x1004040e8
            let value0: Double = (x * 0.3)
            let value1: Double = (value0 * y)
            return value1
        case 21: // 0x100404100
            let value0: Double = (y * y)
            let value1: Double = (x * x)
            let value2: Double = (value0 - value1)
            let value3: Double = (value2 * 0.1)
            return value3
        case 77: // 0x10040411c
            let value0: Double = (y * 0.4)
            let value1: Double = (value0 * y)
            let value2: Double = (x * 0.4)
            let value3: Double = (value2 * x)
            let value4: Double = (value1 - value3)
            let value5: Double = (value4 * 0.1)
            return value5
        case 79: // 0x100404148
            let value0: Double = (y + y)
            let value1: Double = (value0 * y)
            let value2: Double = (x * -3.5)
            let value3: Double = (value2 * x)
            let value4: Double = (value1 + value3)
            let value5: Double = (value4 * 0.1)
            return value5
        case 19: // 0x100404170
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (x * -0.6)
            let value4: Double = (value3 * x)
            let value5: Double = (value4 - value1)
            let value6: Double = (value5 * 0.01)
            let value7: Double = exp(value6)
            let value8: Double = (value2 * value7)
            return value8
        case 27: // 0x1004041c0
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (x * -1.6)
            let value4: Double = (value3 * x)
            let value5: Double = (value4 - value1)
            let value6: Double = (value5 * 0.01)
            let value7: Double = exp(value6)
            let value8: Double = (value2 * value7)
            return value8
        case 28: // 0x10040420c
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (x * -1.5)
            let value4: Double = (value3 * x)
            let value5: Double = (value4 - value1)
            let value6: Double = (value5 * 0.01)
            let value7: Double = exp(value6)
            let value8: Double = (value2 * value7)
            return value8
        case 29: // 0x100404254
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (x * -1.4)
            let value4: Double = (value3 * x)
            let value5: Double = (value4 - value1)
            let value6: Double = (value5 * 0.01)
            let value7: Double = exp(value6)
            let value8: Double = (value2 * value7)
            return value8
        case 32: // 0x1004042a4
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (x * -1.1)
            let value4: Double = (value3 * x)
            let value5: Double = (value4 - value1)
            let value6: Double = (value5 * 0.01)
            let value7: Double = exp(value6)
            let value8: Double = (value2 * value7)
            return value8
        case 96: // 0x1004042f0
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = -(x * x)
            let value4: Double = (value3 - value1)
            let value5: Double = (value4 * 0.003)
            let value6: Double = exp(value5)
            let value7: Double = (value2 * value6)
            return value7
        case 98: // 0x100404330
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (value2 * -9.0)
            let value4: Double = -(x * x)
            let value5: Double = (value4 - value1)
            let value6: Double = (value5 * 0.003)
            let value7: Double = exp(value6)
            let value8: Double = (value3 * value7)
            return value8
        case 99: // 0x100404378
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (value2 * -9.0)
            let value4: Double = -(x * x)
            let value5: Double = (value4 - value1)
            let value6: Double = (value5 * 0.0013)
            let value7: Double = exp(value6)
            let value8: Double = (value3 * value7)
            return value8
        case 101: // 0x1004043c0
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = -(x * x)
            let value4: Double = (value3 - value1)
            let value5: Double = (value4 * 0.001)
            let value6: Double = exp(value5)
            let value7: Double = (value2 * value6)
            return value7
        case 102: // 0x100404400
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = -(x * x)
            let value4: Double = (value3 - value1)
            let value5: Double = (value4 * 0.001)
            let value6: Double = exp(value5)
            let value7: Double = -(value2 * value6)
            return value7
        case 106: // 0x100404440
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = -(x * x)
            let value4: Double = (value3 - value1)
            let value5: Double = (value4 * 0.002)
            let value6: Double = exp(value5)
            let value7: Double = (value2 * value6)
            return value7
        case 104: // 0x100404480
            let value0: Double = (y + -16.0)
            let value1: Double = (x * x)
            let value2: Double = (y * y)
            let value3: Double = (value1 + value2)
            let value4: Double = -(x * x)
            let value5: Double = (value0 * value0)
            let value6: Double = (value4 - value5)
            let value7: Double = (value6 * 0.003)
            let value8: Double = exp(value7)
            let value9: Double = (value3 * value8)
            return value9
        case 107: // 0x1004044cc
            let value0: Double = (y + 30.0)
            let value1: Double = (x * x)
            let value2: Double = (value0 * value0)
            let value3: Double = (value1 + value2)
            let value4: Double = -(x * x)
            let value5: Double = (y * y)
            let value6: Double = (value4 - value5)
            let value7: Double = (value6 * 0.002)
            let value8: Double = exp(value7)
            let value9: Double = (value3 * value8)
            return value9
        case 108: // 0x100404518
            let value0: Double = (x + -20.0)
            let value1: Double = (y + -27.0)
            let value2: Double = (x * x)
            let value3: Double = (y * y)
            let value4: Double = (value2 + value3)
            let value5: Double = (value4 * -9.0)
            let value6: Double = -(value0 * value0)
            let value7: Double = (value1 * value1)
            let value8: Double = (value6 - value7)
            let value9: Double = (value8 * 0.003)
            let value10: Double = exp(value9)
            let value11: Double = (value5 * value10)
            return value11
        case 110: // 0x100404574
            let value0: Double = (y + 60.0)
            let value1: Double = (x * x)
            let value2: Double = (y * y)
            let value3: Double = (value1 + value2)
            let value4: Double = (value3 * 0.04)
            let value5: Double = -(x * x)
            let value6: Double = (value0 * value0)
            let value7: Double = (value5 - value6)
            let value8: Double = (value7 * 0.003)
            let value9: Double = exp(value8)
            let value10: Double = (value4 * value9)
            return value10
        case 111: // 0x1004045d0
            let value0: Double = (y + -60.0)
            let value1: Double = (x * x)
            let value2: Double = (y * y)
            let value3: Double = (value1 + value2)
            let value4: Double = (value3 * 0.04)
            let value5: Double = -(x * x)
            let value6: Double = (value0 * value0)
            let value7: Double = (value5 - value6)
            let value8: Double = (value7 * 0.002)
            let value9: Double = exp(value8)
            let value10: Double = (value4 * value9)
            return value10
        case 103: // 0x10040462c
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (x * 0.03)
            let value4: Double = (y * 0.0015)
            let value5: Double = (value3 * -0.03)
            let value6: Double = (value4 * 0.0015)
            let value7: Double = (value5 * x)
            let value8: Double = (value6 * y)
            let value9: Double = (value7 - value8)
            let value11: Double = exp(value9)
            let value12: Double = -(value2 * value11)
            return value12
        case 109: // 0x100404680
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (x * 0.03)
            let value4: Double = (y * 0.0159)
            let value5: Double = (value3 * -0.03)
            let value6: Double = (value4 * 0.0159)
            let value7: Double = (value5 * x)
            let value8: Double = (value6 * y)
            let value9: Double = (value7 - value8)
            let value11: Double = exp(value9)
            let value12: Double = -(value2 * value11)
            return value12
        case 112: // 0x1004046d4
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (x * 0.01)
            let value4: Double = (y * 0.05)
            let value5: Double = (value3 * -0.01)
            let value6: Double = (value4 * 0.05)
            let value7: Double = (value5 * x)
            let value8: Double = (value6 * y)
            let value9: Double = (value7 - value8)
            let value11: Double = exp(value9)
            let value12: Double = -(value2 * value11)
            return value12
        case 113: // 0x100404728
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (x * 0.03)
            let value4: Double = (y * 0.009)
            let value5: Double = (value3 * -0.03)
            let value6: Double = (value4 * 0.009)
            let value7: Double = (value5 * x)
            let value8: Double = (value6 * y)
            let value9: Double = (value7 - value8)
            let value11: Double = exp(value9)
            let value12: Double = -(value2 * value11)
            return value12
        case 15: // 0x10040477c
            let value0: Double = (x * y)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = (value2 * 0.1)
            let value4: Double = -(x * y)
            let value5: Double = (value4 - value1)
            let value6: Double = (value5 * 0.01)
            let value7: Double = exp(value6)
            let value8: Double = (value3 * value7)
            return value8
        case 16: // 0x1004047c8
            let value0: Double = (x * y)
            let value1: Double = (value0 + y)
            let value2: Double = (value1 * 0.1)
            let value3: Double = -(x * x)
            let value4: Double = (value3 - y)
            let value5: Double = (value4 * 0.01)
            let value6: Double = exp(value5)
            let value7: Double = (value2 * value6)
            return value7
        case 39: // 0x100404810
            let value0: Double = (x * x)
            let value1: Double = (value0 - y)
            let value2: Double = (value1 * 0.03)
            let value3: Double = (x + y)
            let value4: Double = (value3 * -0.01)
            let value5: Double = exp(value4)
            let value6: Double = (value2 * value5)
            return value6
        case 74: // 0x100404854
            let value0: Double = (x - y)
            let value1: Double = (x + y)
            let value2: Double = (value1 * -0.01)
            let value3: Double = exp(value2)
            let value4: Double = (value0 * value3)
            return value4
        case 2: // 0x100404888
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = sqrt(value2)
            let value4: Double = abs(value3)
            return value4
        case 22: // 0x1004048a0
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value1 * y)
            let value3: Double = (value0 + value2)
            let value4: Double = (xMax * yMax)
            let value5: Double = abs(value3 - value4)
            let value6: Double = sqrt(value5)
            let value7: Double = abs(value6)
            return value7
        case 43: // 0x1004048c4
            let value0: Double = (x * x)
            let value1: Double = (value0 * x)
            let value2: Double = (y * y)
            let value3: Double = (value1 + value2)
            let value4: Double = (xMax * yMax)
            let value5: Double = abs(value3 - value4)
            let value6: Double = sqrt(value5)
            let value7: Double = abs(value6)
            return value7
        case 44: // 0x1004048e8
            let value0: Double = (xMax * yMax)
            let value1: Double = (x + x)
            let value2: Double = (value1 * x)
            let value3: Double = (value0 - value2)
            let value4: Double = (y * y)
            let value5: Double = abs(value3 - value4)
            let value6: Double = sqrt(value5)
            let value7: Double = abs(value6)
            return value7
        case 45: // 0x10040490c
            let value0: Double = (xMax * yMax)
            let value1: Double = (x * -0.2)
            let value2: Double = (value1 * x)
            let value3: Double = (value0 + value2)
            let value4: Double = (y * y)
            let value5: Double = abs(value3 - value4)
            let value6: Double = sqrt(value5)
            let value7: Double = abs(value6)
            return value7
        case 46: // 0x100404938
            let value0: Double = (xMax * yMax)
            let value1: Double = (x * -5.0)
            let value2: Double = (value1 * x)
            let value3: Double = (value0 + value2)
            let value4: Double = (y * y)
            let value5: Double = abs(value3 - value4)
            let value6: Double = sqrt(value5)
            let value7: Double = abs(value6)
            return value7
        case 47: // 0x100404960
            let value0: Double = (xMax * yMax)
            let value1: Double = (x * x)
            let value2: Double = (value1 * -25.0)
            let value3: Double = (value0 + value2)
            let value4: Double = (y * y)
            let value5: Double = abs(value3 - value4)
            let value6: Double = sqrt(value5)
            let value7: Double = abs(value6)
            return value7
        case 48: // 0x100404988
            let value0: Double = (xMax * yMax)
            let value1: Double = (x * x)
            let value2: Double = (value0 - value1)
            let value3: Double = (y * -5.0)
            let value4: Double = (value3 * y)
            let value5: Double = (value2 + value4)
            let value6: Double = abs(value5)
            let value7: Double = sqrt(value6)
            let value8: Double = abs(value7)
            return value8
        case 50: // 0x1004049b4
            let value0: Double = (xMax * yMax)
            let value1: Double = (x * x)
            let value2: Double = (value1 * -55.0)
            let value3: Double = (value0 + value2)
            let value4: Double = (y * y)
            let value5: Double = (value4 * -5.0)
            let value6: Double = (value3 + value5)
            let value7: Double = abs(value6)
            let value8: Double = sqrt(value7)
            let value9: Double = abs(value8)
            return value9
        case 54: // 0x1004049f0
            let value0: Double = (xMax * yMax)
            let value1: Double = (x * x)
            let value2: Double = (value1 * x)
            let value3: Double = (value0 - value2)
            let value4: Double = (y * y)
            let value5: Double = (value4 + value3)
            let value6: Double = abs(value5)
            let value7: Double = sqrt(value6)
            let value8: Double = abs(value7)
            let value9: Double = (value8 * 0.2)
            return value9
        case 55: // 0x100404a24
            let value0: Double = (xMax * yMax)
            let value1: Double = (x * x)
            let value2: Double = (value0 - value1)
            let value3: Double = (y * y)
            let value4: Double = (value3 * y)
            let value5: Double = (value4 + value2)
            let value6: Double = abs(value5)
            let value7: Double = sqrt(value6)
            let value8: Double = abs(value7)
            return value8
        case 56: // 0x100404a4c
            let value0: Double = (xMax * yMax)
            let value1: Double = (x * x)
            let value2: Double = (value0 - value1)
            let value3: Double = abs(value2 - y)
            let value4: Double = sqrt(value3)
            let value5: Double = abs(value4)
            return value5
        case 62: // 0x100404a68
            let value0: Double = (xMax * yMax)
            let value1: Double = (x * x)
            let value2: Double = (value0 - value1)
            let value3: Double = (y * y)
            let value4: Double = (value2 - value3)
            let value5: Double = (value2 + y)
            let value6: Double = (value4 / value5)
            let value7: Double = abs(value6)
            let value8: Double = pow(value7, 0.8)
            let value9: Double = (value8 * 5.0)
            return value9
        case 13: // 0x100404aac
            let value0: Double = (y + y)
            let value1: Double = (value0 + x)
            let value2: Double = (x + x)
            let value3: Double = (y * 3.0)
            let value4: Double = (value2 + value3)
            let value5: Double = (value4 / xMax)
            let value6: Double = cos(value5)
            let value7: Double = (value1 * value6)
            return value7
        case 80: // 0x100404ae8
            let value0: Double = (y + y)
            let value1: Double = (value0 + x)
            let value2: Double = (x + x)
            let value3: Double = (y * 3.0)
            let value4: Double = (value2 + value3)
            let value5: Double = (value4 / xMax)
            let value6: Double = sin(value5)
            let value7: Double = (value1 * value6)
            return value7
        case 81: // 0x100404b24
            let value0: Double = (y + y)
            let value1: Double = (value0 + x)
            let value2: Double = (x + x)
            let value3: Double = (y * 5.5)
            let value4: Double = (value2 + value3)
            let value5: Double = (value4 / xMax)
            let value6: Double = cos(value5)
            let value7: Double = (value1 * value6)
            return value7
        case 83: // 0x100404b60
            let value0: Double = (y + y)
            let value1: Double = (value0 + x)
            let value2: Double = (x + x)
            let value3: Double = (y * 8.0)
            let value4: Double = (value2 + value3)
            let value5: Double = (value4 / xMax)
            let value6: Double = sin(value5)
            let value7: Double = (value1 * value6)
            return value7
        case 84: // 0x100404b9c
            let value0: Double = (x + x)
            let value1: Double = (value0 + y)
            let value2: Double = (y * 8.0)
            let value3: Double = (value0 + value2)
            let value4: Double = (value3 / xMax)
            let value5: Double = cos(value4)
            let value6: Double = (value1 * value5)
            return value6
        case 85: // 0x100404bd4
            let value0: Double = (y * 8.0)
            let value1: Double = (value0 + x)
            let value2: Double = (x + x)
            let value3: Double = (value2 + value0)
            let value4: Double = (value3 / xMax)
            let value5: Double = cos(value4)
            let value6: Double = (value1 * value5)
            return value6
        case 86: // 0x100404c0c
            let value0: Double = (y * 8.0)
            let value1: Double = (value0 + x)
            let value2: Double = (x + x)
            let value3: Double = (value0 - value2)
            let value4: Double = (value3 / xMax)
            let value5: Double = sin(value4)
            let value6: Double = (value1 * value5)
            return value6
        case 87: // 0x100404c44
            let value0: Double = (y + y)
            let value1: Double = (value0 - x)
            let value2: Double = (x + x)
            let value3: Double = (y * 8.0)
            let value4: Double = (value2 + value3)
            let value5: Double = (value4 / xMax)
            let value6: Double = cos(value5)
            let value7: Double = (value1 * value6)
            return value7
        case 89: // 0x100404c80
            let value0: Double = (x + y)
            let value1: Double = (x + x)
            let value2: Double = (y * 8.0)
            let value3: Double = (value1 + value2)
            let value4: Double = (value3 / xMax)
            let value5: Double = cos(value4)
            let value6: Double = (value0 * value5)
            return value6
        case 90: // 0x100404cb8
            let value0: Double = (x * 4.0)
            let value1: Double = (value0 + y)
            let value2: Double = (x + x)
            let value3: Double = (y * 8.0)
            let value4: Double = (value2 + value3)
            let value5: Double = (value4 / xMax)
            let value6: Double = cos(value5)
            let value7: Double = (value1 * value6)
            return value7
        case 91: // 0x100404cf8
            let value0: Double = (y + y)
            let value1: Double = (x * -7.0)
            let value2: Double = (value0 + value1)
            let value3: Double = (value2 / xMax)
            let value4: Double = cos(value3)
            let value5: Double = (value2 * value4)
            return value5
        case 94: // 0x100404d2c
            let value0: Double = (x + y)
            let value1: Double = (x * 8.0)
            let value2: Double = (y * 3.0)
            let value3: Double = (value1 - value2)
            let value4: Double = (value3 / xMax)
            let value5: Double = cos(value4)
            let value6: Double = (value0 * value5)
            let value7: Double = (x * 4.0)
            let value8: Double = (value7 + value2)
            let value9: Double = (value8 / xMax)
            let value10: Double = sin(value9)
            let value11: Double = (value10 * value6)
            return value11
        case 95: // 0x100404d90
            let value0: Double = (x + y)
            let value1: Double = (x * 3.0)
            let value2: Double = (y + y)
            let value3: Double = (value1 + value2)
            let value4: Double = (value3 / xMax)
            let value5: Double = cos(value4)
            let value6: Double = (value0 * value5)
            let value7: Double = (x + x)
            let value8: Double = (y * 3.0)
            let value9: Double = (value7 + value8)
            let value10: Double = (value9 / xMax)
            let value11: Double = sin(value10)
            let value12: Double = (value11 * value6)
            return value12
        case 10: // 0x100404dfc
            let value0: Double = (x * y)
            let value1: Double = (value0 * y)
            let value2: Double = (xMax * xMax)
            let value3: Double = (value2 * xMax)
            let value4: Double = (value1 / value3)
            let value5: Double = cos(value4)
            let value6: Double = (value5 * 0.1)
            let value7: Double = (value6 * y)
            let value8: Double = (value7 * y)
            return value8
        case 11: // 0x100404e44
            let value0: Double = (x / xMax)
            let value1: Double = sin(value0)
            let value2: Double = (value1 * y)
            let value3: Double = (value1 * x)
            let value4: Double = (-1.0 / value3)
            let value5: Double = (value2 + value4)
            return value5
        case 30: // 0x100404e80
            let value0: Double = (x * y)
            let value1: Double = (value0 * y)
            let value2: Double = (xMax * xMax)
            let value3: Double = (value2 * xMax)
            let value4: Double = (value1 / value3)
            let value5: Double = sin(value4)
            let value6: Double = (value5 * 0.1)
            let value7: Double = (value6 * y)
            let value8: Double = (value7 * y)
            return value8
        case 31: // 0x100404ec8
            let value0: Double = (x * x)
            let value1: Double = (value0 * y)
            let value2: Double = (xMax * xMax)
            let value3: Double = (value2 * xMax)
            let value4: Double = (value1 / value3)
            let value5: Double = cos(value4)
            let value6: Double = (value5 * 0.1)
            let value7: Double = (value6 * y)
            let value8: Double = (value7 * y)
            return value8
        case 36: // 0x100404f10
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = ceil(value2)
            return value3
        case 38: // 0x100404f24
            let value0: Double = (x * x)
            let value1: Double = (y * y)
            let value2: Double = (value0 + value1)
            let value3: Double = ceil(value2)
            let value4: Double = (value3 * 0.1)
            return value4
        default: return .nan
        }
    }
}

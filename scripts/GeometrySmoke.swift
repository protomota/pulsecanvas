import Foundation
@main struct GeometrySmoke {
    static func main() {
        precondition(SurfaceGeometry.formulaIDs.count == 74)
        precondition(FormulaReference.height(formulaID: 7, x: 3, y: 4) == -7)
        precondition(SurfaceGeometry.height(formulaID: 36, x: 1.2, y: 1.1) == 3)
        precondition(abs(SurfaceGeometry.height(formulaID: 38, x: 1.2, y: 1.1) - 0.3) < 1e-12)
        precondition(abs(SurfaceGeometry.height(formulaID: 40, x: 0.2, y: 0.5) - sin(0.7)) < 1e-12)
        let grid = SurfaceGeometry.pointGrid(formulaID: 2)
        precondition(grid.count == 14400)
        precondition(grid[0].x == -5760 && grid[0].y == -5760)
        precondition(grid[119].x == -5760 && grid[119].y == 5664)
        precondition(grid[120].x == -5664 && grid[120].y == -5760)
        let blended = SurfaceGeometry.morph([SIMD3<Float>(0, 2, 4)], [SIMD3<Float>(4, 6, 8)], count: 25, length: 100)
        precondition(blended == [SIMD3<Float>(1, 3, 5)])
        for scene in SurfaceGeometry.PointScene.allCases {
            precondition(!scene.availableFormulaPool.isEmpty)
            for id in scene.availableFormulaPool { precondition(SurfaceGeometry.pointGrid(formulaID: id).count == 14400) }
        }
        precondition(SurfaceGeometry.PointScene.prismWake.morphLength == 110)
        precondition(SurfaceGeometry.pointGrid(formulaID: 2, grid: .init(xMax: .infinity)).isEmpty)
        precondition(SurfaceGeometry.pointGrid(formulaID: -1).isEmpty)
        print("PASS: 74 runtime formulas plus 5 reference fixtures, native grid order/count, scene pools, defaults and linear morph verified")
        if CommandLine.arguments.contains("--samples") {
            let samples: [(Double, Double)] = [(12.5, 18.75), (-33.25, 71.125), (1.2, 1.1), (0, 0), (239.5, -239.5)]
            for (index, sample) in samples.enumerated() {
                for id in FormulaReference.formulaIDs.sorted() {
                    let value = FormulaReference.height(formulaID: id, x: sample.0, y: sample.1)
                    print("\(index)\t\(id)\t\(value)")
                }
            }
        }
    }
}

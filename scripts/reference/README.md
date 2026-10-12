# Numerical and source-audit references

These files are excluded from the SwiftPM and Xcode application targets and are not bundled in the app.

`PointGeometry.swift` and `FormulaGeometry.swift` preserve the historical math inputs used by the numerical verification harnesses. `shaders/` preserves source modules that have no rendering pipeline in the app; `docs/shader-provenance.json` maps every module to its current path and identifies the 13 active application resources. The runtime shader build reads only `Sources/PulseCanvas/Resources/VisualShaders`.

# License provenance for the bundled PVRTC decoder

Destination: https://github.com/projectM-visualizer/projectm/issues/new

Posted with owner authorization: https://github.com/projectM-visualizer/projectm/issues/1046

## Body

We're preparing PulseCanvas Studio, a free Mac App Store application using ProjectM 4.2.0 as a dynamically loaded shared library, with a public matching source/rebuild package. Website: https://pulsecanvas.si/.

In engine commit `349b7cc2db312d47cef6be24c6856ced6643a385`, `vendor/stb_image/stbi_pvr_c.h` contains a section credited to Imagination Technologies' `PVRTDecompress.cpp` (around line 170). The exact file SHA-256 is `8ba543813dd70f01f8878830d747a2ab459d39197f812c6a0f6f91604a313e58`.

We retain the embedded copyright and the image-loader notices in the app's Legal resources and corresponding source. The current official PowerVR Native SDK has an MIT license, but we would like to establish the license/provenance applicable to this older decoder and its port rather than assume the current SDK license covers every historical copy.

Is there an upstream license or provenance record covering this exact code, and a permission notice we should include for binary and source redistribution? If the current Imagination MIT notice is the applicable grant, a reference linking it to the included implementation would resolve our notice question. We intend to retain ProjectM and all effects; this is a license-documentation question, not a request to remove functionality.

Thank you.

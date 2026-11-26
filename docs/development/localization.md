# PulseCanvas interface localization

The shared [Xcode string catalog](../../Localization/Localizable.xcstrings) uses
English as its source language. It includes Danish, Dutch, French, German,
Italian, Japanese, Korean, Norwegian Bokmål, Brazilian Portuguese, Spanish,
Swedish, Turkish, Vietnamese, and both Simplified and Traditional Chinese. This
matches [Apple's 16-language list](https://support.apple.com/en-gb/121115) for
Mac, iPhone, and iPad. PulseCanvas also bundles the full set on visionOS.

Use SwiftUI's localized label initializers and `String(localized:)` for
messages built in controllers. Use full sentences for interpolated messages.
Keep project fields, preset identifiers, visualizer and palette names,
filenames, and catalog data independent of the interface language. Let the
catalog handle plurals and use the platform locale for number formatting.

The three Xcode targets compile this catalog as an app resource. The standalone
Mac scripts use `xcstringstool` to compile the same catalog into the main bundle.
To audit additions, build with `SWIFT_EMIT_LOC_STRINGS=YES` and compare the app
target's `.stringsdata` files to the catalog. Some category and visualizer
control labels are looked up dynamically by their stable English keys.

To preview, select **App Language** under **Product → Scheme → Edit Scheme →
Run → Options** in Xcode. Check onboarding, Studio, Radio, export dialogs and
Settings at a small window size. Review long translations and count labels at
both one and several items.

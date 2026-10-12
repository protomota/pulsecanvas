# PulseCanvas Studio source and licenses

Draft for https://pulsecanvas.si/source/. Publish the source archive and checksum file at the linked paths before publishing this page.

Current PulseCanvas first-party code is covered by the PulseCanvas Source-Available Noncommercial License. Commercial source reuse, resale, and commercial forks require separate written permission from Protomota. The official application can still be used to make commercial videos. ProjectM is licensed under LGPL 2.1 or later. Other dependencies and visual assets retain their own notices and terms, including any commercial permissions; the application license does not relicense them. Earlier archives released under MIT retain their original terms. Read the LICENSE supplied with the particular release you download.

- [Source archive for version 1.0.0](https://pulsecanvas.si/source/PulseCanvas-1.0.0-source.tar.gz)
- [SHA-256 checksums](https://pulsecanvas.si/source/source-SHA256.txt)
- [Application repository](https://github.com/protomota/pulsecanvas)

The archive contains application source, the exact ProjectM and vendor source snapshot, shaders/resources, build scripts, Xcode configuration, and license notices. See `BUILD.txt` in the archive for rebuilding. Apple distribution credentials are not included; use your own signing configuration for a signed build. The portable development build supports rebuilding without an Apple distribution certificate.

You may modify and rebuild the LGPL library for your own use. The application source is available for rebuilding and relinking with your modified library; its license expressly preserves those required LGPL rights, including commercial own use. Apple's signature protections require rebuilding and signing a modified application instead of replacing a library within an existing signed App Store installation.

The included demo track was created by Brad Dunlap using Suno; commercial-use permission was confirmed by its creator. That song is separate from the application-code license.

Questions or source access problems: [support@pulsecanvas.si](mailto:support@pulsecanvas.si).

Publication check: verify the matching source rebuild, all download links and release checksums, and resolve the bundled preset/texture notices and LGPL App Store distribution terms documented in `docs/app-store/LICENSES.md`. This preparation draft does not establish rights for assets whose original notices contain no redistribution grant.

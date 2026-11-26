# TestFlight delivery — 1.0.1 (4)

Uploaded on 2026-10-11; Apple processing completed. App Store Connect shows version **1.0.1 (4)**, the existing **PulseCanvas Mac Beta** internal group with **1 tester**, and saved What to Test notes. No additional testers or access roles were created. This delivery does not establish installation/runtime validation of Apple's delivered copy on another Mac or public App Review approval.

Build page: https://appstoreconnect.apple.com/teams/69a6de6e-7488-47e3-e053-5b8c7c11a4d1/apps/6821642700/testflight/macos/787b6bb2-987b-47d4-8e62-f287e43108b2

Source revision: `4fe07028420b7f8150384194ae6e770eadd8c994`.

Changes: verified unused runtime code removal; 23 Swift app files, 13 active AIR shader modules, all 31 native visualizers and 7,838 ProjectM presets retained. Save video prompts for its destination before rendering and offers only Show in Finder afterward; no saved-video playback actions. Details and validation: `docs/unused-code-audit.md`.

Signed archive: `build/app-store/PulseCanvas-1.0.1-4.xcarchive`. Distribution package: `build/app-store/export-1.0.1-4/PulseCanvas Studio.pkg`. Package signature and expanded app passed bundle/version/build, arm64, sandbox, profile, signing, notices and resource checks. Source snapshot: `build/app-store/PulseCanvas-1.0.1-4-source.tar.gz`, SHA-256 `de8fd384e510e43de414e3b24da35efbc70c860ccd0d986a5370aeed9b25057b`; no signing credentials. The bundled soundtrack is unchanged: SHA-256 `8c863f65e8db705ab4003a2af6df15cf336bdbf92277ee981b5922b107dce8f7`.

Upload succeeded with the existing missing `libprojectM.dylib` dSYM warning. This limits engine crash symbolication and did not prevent processing or beta assignment. Logs, audit receipt and GPU hashes are in `work/unused-code-audit/` (local, ignored). Visual proof is in the task outputs as `PulseCanvas-TestFlight-1.0.1-Build-4.png`.

The existing soundtrack, projects, preset data and portable-app session were preserved; UI checks used the isolated sandbox-validation app. The unreleased App Store listing and rights/source-publication gates remain separate from this internal beta delivery.

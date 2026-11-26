# Privacy and permissions audit

Source audit on 2026-10-11: Swift app plus the actual bundled ProjectM sources. No URLSession, Network framework, remote services, telemetry, advertising SDK, account system, tracking identifiers, or upload functionality found. `AVAudioEngine.connect` is an audio graph operation; `shouldOptimizeForNetworkUse` is MP4 layout metadata, not network transmission. ProjectM playlist/UI components are disabled by CMake; renderer and image loaders operate on local files. Validate symbols and the final Apple distribution artifact before submitting answers.

Runtime sandbox entitlements are only app-sandbox, user-selected read/write files, and app-scoped bookmarks. No network client/server or microphone. Imported music is decoded/analyzed locally; bookmarks preserve access only to the chosen audio. Project open/save and final export use standard macOS panels. Temporary render/intermediate audio/video stay in the app's temporary container; output access lasts through completion/cancellation. Favorites, per-effect settings, timeline settings and export format are in own-app UserDefaults/application support. Saved projects can contain local audio paths and security-scoped bookmark data; users choose where to save/share them. Audio/preset files are not embedded. Legacy projects that lack valid bookmarks prompt the user to locate the audio.

Required-reason declarations:

| Category | Reason | Actual use |
|---|---|---|
| UserDefaults | CA92.1 | Own app preferences/favorites/styles |
| SystemBootTime | 35F9.1 | Elapsed frame/export timing intervals and progress estimates |

No direct disk-capacity/file-timestamp/device-keyboard enumeration API use was found in app sources. Recheck the final binary and vendor changes for required-reason APIs; ordinary file reads and directory enumeration are not themselves a claim of collected data. Manifest: `macOS/PrivacyInfo.xcprivacy`, copied to bundle resources.

App Privacy answer for the audited app: **Data Not Collected**, no tracking, published in Apple with owner authorization on 2026-10-11. User-selected content remains on-device and is not transmitted to the developer. Apple's own store/crash-report mechanisms and a separately hosted website are distinct. The public policy at https://pulsecanvas.si/privacy/ was verified in personal Chrome on 2026-10-11: it describes on-device app processing separately from the website's optional Google Analytics. Domain pulsecanvas.si and public contact support@pulsecanvas.si are confirmed. Apple's final Publish dialog requires agreement that responses are accurate, comply with guidelines/law and will be updated; owner authorization was received and Apple’s published status verified. Do not add a microphone purpose string: this app imports files and does not record.

Encryption: no app-implemented cryptography or third-party cryptographic library found. `ITSAppUsesNonExemptEncryption = false` is the proposed answer; OS security/signing/bookmark facilities are used. Reconfirm against final binary/Apple upload questions.

References: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api ; https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox ; https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/

The app Help sheet includes an on-device privacy explanation. Store builds also provide a prominent ProjectM LGPL notice and a button to open the bundled Legal folder. The policy/support pages are hosted publicly. The support page's private GitHub route has been replaced in production by the confirmed bug-report email, with owner authorization; verified in personal Chrome. Apple's Data Not Collected responses are published. See SUBMISSION-STATUS.md.

# PulseCanvas agent access on macOS

PulseCanvas Creators Edition for Mac connects to local Claude Code and Codex sessions through its bundled executable. Download it from https://pulsecanvas.ai/download/. The app must be running, with its Studio window open or minimized. A dropped client does not cancel an export. Closing the last Studio window quits PulseCanvas. On the next launch, unfinished jobs report `EXPORT_INTERRUPTED`. Start a new export with a new request key after reviewing its destination.

## Connect

1. Open PulseCanvas Studio → **Settings** → **Agent access**. Enable **Allow local agents to connect**. Read-only access is active first. Enable playback, edits, and rendering individually for the operations you want to allow.
2. Choose an **Input folder** for existing local tracks and a **Project and export folder**. Use existing directories. On Brad’s Mac use a designated folder on `/Volumes/Expand`; if Expand is unavailable, reconnect it before starting. PulseCanvas prompts for folder authorization during setup. **Test connection** checks the local host.
3. **Claude Code** is selected first. Choose **Save project connection…** and select the workspace you use in the Claude desktop app. Existing entries in `.mcp.json` are preserved. In Claude, open the **Code** tab and start a new **local** session on **This computer** in that folder. Approve the project connection and check **Connectors** for PulseCanvas. [Claude Code desktop documentation](https://code.claude.com/docs/en/desktop#connect-external-tools)
4. For **Codex**, select its tab in PulseCanvas to copy the command and argument separately. In Codex open **Settings → MCP servers → Add server → STDIO**, name it `pulsecanvas`, paste the executable path and add `--mcp` as one argument. Save and restart, then enter `/mcp` in a local chat. Grant the client’s own permission for the PulseCanvas tools you intend to use. [OpenAI MCP setup](https://learn.chatgpt.com/docs/extend/mcp?surface=desktop)
5. Ask the agent to call `get_app_status` and `get_capabilities`. Read back `running`, `enabled`, the enabled permissions and the resolved folders before loading audio. The Settings connection test verifies the app bridge. A successful tool call in the selected client verifies its separate connection.

The installed executable path is shown in Settings. For the usual install it is `/Applications/PulseCanvas Studio.app/Contents/MacOS/PulseCanvas`. There are no environment variables, ports or keys to configure. Keep the connection limited to trusted local clients. App approval applies to processes running as the current macOS user. Turning off access blocks subsequent agent operations.

## Tools

| Task | Tools |
| --- | --- |
| Discover the app | `get_app_status`, `get_capabilities` |
| Find a visualizer | `list_visualizers`, `get_visualizer` |
| Read or set favorites | `list_favorites`, `list_radio_songs`, `set_favorite` |
| Control Studio playback | `load_song`, `get_playback_state`, `set_playback_state`, `seek`, `set_volume` |
| Work with projects | `get_project`, `create_project`, `open_project`, `save_project`, `analyze_song`, `set_timeline` |
| Edit effects | `set_visualizer`, `set_visualizer_settings` |
| Render and retrieve | `render_preview`, `start_export`, `get_export_status`, `list_exports`, `cancel_export`, `create_music_video` |

`tools/list` includes input and output JSON Schemas. Times are seconds. The `resolution` value is the shorter edge. `wide` at 2160 is 3840 × 2160. Read the app’s capabilities and the controls returned by `get_visualizer`. Metal effects are offered in both Mac editions. ProjectM effects require the direct edition with its engine and catalog installed. Sharing a project across editions does not make its missing effects available. iPhone, iPad, Duo and Vision Pro continue to use their existing project and backup formats.

Pass `kind: "visualizer"` or `kind: "radioSong"` to favorites tools. Add with `favorite: true` and remove with `favorite: false`. These operations preserve the underlying catalog. Studio transport stays isolated from Radio. Loading an authorized song explicitly returns from Radio to Studio. Radio’s list tools can read its configured catalog without starting playback.

Project edits require the revision returned from the most recent read or write. `PROJECT_CONFLICT` means the editor or another client changed the project. Inspect the new revision before deciding whether to reapply an edit. Use `analyze_song` for the detected beat grid and `set_timeline` to provide a contiguous full-song timeline. `create_music_video` can build that timeline from explicit visualizer IDs or saved favorites. It requires an explicit fallback and strobe choice, saves the chosen seed and scene assignments, writes the editable project and queues the MP4. `render_preview` uses the same renderer for a short excerpt.

Files remain local. Playback and rendering require a downloaded track in the approved input folder. Outputs and scratch encodes use the approved output folder. An external project can only reference audio the agent is authorized to read. Normal app sync and backup settings continue to apply to saved favorites and editable projects.

## Export and recovery

The existing Mac exporter runs one GPU export at a time. Up to three agent jobs, including the active job, may be pending. Normal UI exports share the controller. An agent job takes a snapshot of its project, effect settings, timing and source identity before it begins. Exports have their own frame clock, separate from live playback.

Use a unique `requestKey` for each new save or render. Retry the exact original arguments with the same key if a reply was lost. Reusing a key with changed arguments returns `REQUEST_KEY_CONFLICT`. PulseCanvas keeps the latest 200 export and save receipts. Jobs can report `queued`, `preparing`, `rendering`, `muxing`, `validating`, `completed`, `failed` or `cancelled`. Poll `get_export_status` for frame counts, ETA when available, failure details and output metadata. On completion the result includes a validated H.264/AAC file and a neighboring `.render.json` manifest. Report the absolute file and project paths and job ID to the user.

| Error | Next step |
| --- | --- |
| `APP_UNAVAILABLE` | Open the installed app and keep its Studio window open or minimized. |
| `CONNECTION_DISABLED` or `PERMISSION_REQUIRED` | Review the enabled permissions and folder grants in Settings. |
| `AUDIO_UNAVAILABLE` or `AUDIO_CHANGED` | Choose a downloaded, readable file and keep it unchanged while rendering. |
| `INVALID_TIMELINE` or `UNSUPPORTED_EFFECT` | Read the beat grid and active catalog, then check the named sections and IDs. |
| `OUTPUT_EXISTS` | Choose a new filename. New jobs default to preserving an existing file. |
| `EXPORT_BUSY` | Check the active and queued jobs, then retry. |
| `DISK_FULL` | Free space on the authorized drive or authorize a folder with room. |
| `EXPORT_INTERRUPTED` | Inspect the destination and start another job with a new key. |

## Executable examples

Run the following from a checkout using an installed PulseCanvas executable and approved folders. These examples use Python’s standard library as a standalone MCP test client.

```sh
APP='/Applications/PulseCanvas Studio.app/Contents/MacOS/PulseCanvas'
python3 scripts/pulsecanvas-mcp-example.py "$APP" favorites 'native:10'
python3 scripts/pulsecanvas-mcp-example.py "$APP" playback '/absolute/input/song.wav'
python3 scripts/pulsecanvas-mcp-example.py "$APP" video '/absolute/input/song.wav' '/absolute/output/Edit.pulsecanvas' '/absolute/output/Video.mp4'
```

The favorites example preserves the starting state. The playback and video examples replace the working Studio soundtrack. Use a fresh Studio session and isolated data when using them for QA.

## Application ownership

- **ProjectMPresets** and **RadioController** persist both types of favorites and notify the existing cloud and backup observers.
- **AudioController** owns the active transport and the prepared local soundtrack. CPU preparation can run on a worker. The main actor installs the result after checking permissions and the project revision again.
- **StudioStore** owns visual presets, beat-aligned sections and the editable project. The editor and MCP use the same document snapshot, validation, timeline section construction and application.
- **SocialExportController** and **VisualizerRenderer** own the Metal pipeline, ProjectM integration, offline frame clock and encoding. The Mac MCP job layer handles admission, durable receipts, scoped paths, validation and publication around this pipeline.
- The app executable starts either the SwiftUI host or the STDIO bridge. The bridge communicates through a private same-user mailbox, with an exclusive host lock. The host rechecks every tool's schema and permissions. JSON-RPC is written to stdout and the defined MCP transports and tool schemas follow the [MCP specification](https://modelcontextprotocol.io/specification/2025-11-25).

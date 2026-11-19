# Nyanko Sensei

English | [简体中文](README-zh.md)

A transparent macOS desktop companion built with Swift and AppKit. Let the round little Nyanko Sensei follow your cursor, make silly faces, eat files, and remind you to take a break.

> An unofficial fan project with no affiliation with the creators or rights holders of *Natsume's Book of Friends*. Code and character artwork have different licensing terms; see [Artwork](docs/ARTWORK.md).

![Contentment with floating pink bubbles](docs/images/satisfied.gif)

## Features

- **16-direction cursor tracking** using the system mouse position.
- **Customizable mouse reactions** for clicks, long presses, modifier keys, the middle button, scrolling, and sudden approaches.
- **Expressive reactions**: anger, horror, a mischievous grin, drunkenness, comfort, burping, contentment, delight, eating, and a brief head transformation into Madara. Optional pink bubbles float around him when he is satisfied.
- **Eat files** by dragging them onto the pet to move them to macOS Trash, with batch-by-batch undo.
- **Local reminders** with one-time or repeating schedules, a five-minute snooze, and a 25-minute focus timer.
- **Eight sizes**: 96 / 120 / 144 / 160 / 200 / 260 / 340 / 420 pixels; the default is 120.
- 24 image groups and 108 frames. No network connection, account, Accessibility permission, or Screen Recording permission is needed.

## Requirements

- macOS 13 or later.
- An Apple Silicon (`arm64`) or Intel (`x86_64`) Mac. Use a package matching your Mac's architecture.
- Xcode Command Line Tools, including the Swift compiler, to build from source.

## Installation

### Option 1: Build from source — recommended

Install the developer tools if you do not already have them:

```sh
xcode-select --install
```

Then clone, build, and launch:

```sh
git clone https://github.com/Flipped23/nyanko-sensei.git
cd nyanko-sensei
bash scripts/build.sh
open build/猫咪老师.app
```

The app is created at `build/猫咪老师.app`. In Finder, drag the entire `.app` into **Applications**, then double-click it to launch. All runtime images are bundled inside the app; the source directory is not required afterward.

The scripts build for your current architecture by default. You can also specify one:

```sh
ARCH=arm64 bash scripts/package.sh
# Package for Intel Macs:
ARCH=x86_64 bash scripts/package.sh
```

Packages are written to `dist/`. Cross-compiling does not verify that the app runs on the other architecture's hardware.

### Option 2: Download a GitHub Actions build

Open [Actions](https://github.com/Flipped23/nyanko-sensei/actions), select the latest successful **Build macOS app** run, and download `nyanko-sensei-macos` under **Artifacts**. Extract the artifact, then extract the app package inside it and move the `.app` to **Applications**. Downloading Actions artifacts generally requires signing in to GitHub.

CI builds for the runner's native architecture; check the package filename. The app uses an ad hoc local signature and is **not Developer ID signed or notarized by Apple**. If macOS blocks it, verify the file's source before following the system's app-opening instructions.

## Usage

After launch, the pet appears on your desktop and **猫咪老师** appears in the menu bar. The app's menus currently use Chinese; corresponding labels are included below.

- **Right-click the pet** or select its menu-bar item to open actions, reminders, and settings.
- **Drag with the left mouse button** to move him. Choose `移动到屏幕右下角` to move him to the bottom-right corner if you lose track of him.
- **Resize** through `调整大小`. The 120-pixel option is close to the native Pets size. Below 180 pixels, the attached text bubble is hidden; reminder dialogs still appear.
- **Cursor tracking** selects a gaze direction within roughly 700 pixels of the head. A manually triggered reaction temporarily takes priority; tracking resumes when it finishes.
- **Quit** through the menu-bar item → `退出猫咪老师`. Hiding the pet keeps the app and reminders running.

### Default mouse reactions

| Input | Reaction |
| --- | --- |
| Single click | Wave |
| Double-click | Open-mouth eating animation; no files are moved |
| Triple-click | Briefly reveal Madara's true-form head |
| Long press without dragging | Comfort / head pats |
| Option + click | Mischievous grin |
| Shift + click | Anger |
| Middle click | Burp |
| Mouse wheel / two-finger scroll | Drunkenness |
| Quickly move the pointer toward him | Horror |

Change these bindings in **Mouse behavior settings** (`鼠标行为设置`). You can also play reactions directly from **Actions and expressions** (`动作与表情`).

### Eating files and undoing

Drag a file or folder from Finder onto the pet's body. Release it when his mouth opens to move it to **Trash**. The app never empties Trash.

Choose **Undo the last batch of eaten files** (`撤销上次吃掉的文件`) to restore the most recent batch. Repeat to undo earlier batches. Restoring never overwrites an existing file with the same name. If the original directory is missing or not writable, or the file is no longer in Trash, use Finder to handle it manually.

Uncheck `拖入文件后丢到废纸篓` to disable this feature. Protected paths include system directories, your home directory, and the app itself. To feed him without moving files, double-click or choose `喂一口`.

### Reminders

Choose **Add reminder** (`添加提醒`), enter a message and time, and select a one-time reminder or a repeat interval of 30 minutes, one hour, or one day. A dialog appears when it is due; acknowledge it or snooze for five minutes. Use **Manage reminders** (`管理提醒`) to view or delete entries.

**The app must remain running.** Reminders do not appear after quitting. Reminders missed during sleep are checked when the Mac wakes. The app does not read your system Calendar, Reminders app, or cloud accounts.

## Data and privacy

The pet's position, size, bindings, reminders, and file-undo history are stored locally at:

```text
~/Library/Application Support/NyankoCompanion/preferences.json
```

Undo records contain the original and Trash locations of files. They stay on your Mac, and the app has no network upload feature. Do not commit your own `preferences.json` to GitHub.

Quit the old process before opening an updated `.app`. Existing settings are preserved.

## Project structure

```text
Sources/NyankoCompanion/   Swift models, interactions, windows, and rendering
Resources/                App configuration, icon, animation manifest, and PNG frames
scripts/                  Build, packaging, resource checks, and runtime checks
.github/workflows/        macOS build and artifact packaging
docs/                     Development notes, artwork notes, and previews
```

See the [development guide](docs/DEVELOPMENT.md) for architecture and testing details. Issues and pull requests are welcome; read [CONTRIBUTING.md](CONTRIBUTING.md) before contributing. These supporting guides are currently in Chinese.

## License and credits

Project code is licensed under the [MIT License](LICENSE). Character designs, names, original anime artwork, and related third-party rights are outside that code license; see [ARTWORK.md](docs/ARTWORK.md). The public source tree excludes user-supplied anime screenshots, original official reference images, personal settings, generated test files, and compiled apps.

Nyanko Sensei / Madara is a character from *Natsume's Book of Friends*. New images were created using generative image tools with character references. Thanks to the original manga and anime creators.

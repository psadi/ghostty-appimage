[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/psadi/ghostty-appimage/blob/main/LICENSE)
[![Build Status](https://github.com/psadi/ghostty-appimage/actions/workflows/ci.yaml/badge.svg)](https://github.com/psadi/ghostty-appimage/actions/workflows/ci.yaml)

<h1><p align="center">
  <img src="./assets/ghostty.png" alt="Ghostty Logo" width="128">
  <img src="./assets/appimage.png" alt="AppImage Logo" width="128">
  <br>Ghostty AppImage
</p></h1>

This repository provides build scripts to create a Universal AppImage for [Ghostty](https://ghostty.org/). This unofficial build offers an executable AppImage compatible with any Linux distribution following the **x86_64 architecture**.


**Ghostty Source Code:** [Click Here](https://github.com/ghostty-org/ghostty)


## 🚀 Quick Start

1. Download the latest AppImage from the [releases](https://github.com/psadi/ghostty-appimage/releases) section.
2. Follow the installation instructions below to run the AppImage.

## ⚙️ Installation

### Command Line

Run the following commands in your terminal:

```bash
# Download the latest AppImage package
wget https://github.com/psadi/ghostty-appimage/releases/download/[TAG]/Ghostty-x86_64.AppImage
# Provide executable permissions
chmod +x Ghostty-x86_64.AppImage
# Execute the AppImage
./Ghostty-x86_64.AppImage
```

### Graphical

1. Download the latest AppImage package from the [releases](https://github.com/psadi/ghostty-appimage/releases) section.
2. Locate the downloaded file in your file explorer (e.g., Nautilus, Thunar, PCManFM).
3. Right-click the downloaded file and select **Properties**.
4. Navigate to the **Permissions** tab and check the box that says **Allow executing file as program/Executable as Program**.
5. Close the properties window and double-click the AppImage file to run it.

<p align="center">
  <img src="./assets/1.png" alt="Step 1" width="384" style="margin-right: 10px;">
  <img src="./assets/2.png" alt="Step 2" width="384">
</p>

## ⏫ Updating

Since AppImages are self-contained executables, there is no formal installation process beyond setting executable permissions.

**To update:**

1. Download the latest AppImage package from the [releases](https://github.com/psadi/ghostty-appimage/releases) section.
2. Follow the same steps as in the [Installation](#installation) section to make it executable and run it.

## ❓ What's Next?

1. Submit AppImage(s) to [AppImageHub](https://appimage.github.io/).
2. Provide AppImages for other supported architectures.

    | **Architecture** | **Support** |
    |------------------|-------------|
    | x86_64           | ✅          |
    | i386             | ❌          |
    | ARM              | ❌          |

### 🛠️ Troubleshooting

- If the AppImage does not run, ensure that you have provided executable permissions.
- If you encounter any errors, check the terminal for error messages that may indicate missing dependencies or other issues.

## 🤝 Contributing

Contributions & Bugfixes are welcome. If you like to contribute, please feel free to fork the repository and submit a pull request.

For any questions or discussions, please open an issue in the repository.

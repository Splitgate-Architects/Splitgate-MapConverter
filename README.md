# Splitgate-MapConverter

A streamlined, automated utility designed to compile and package raw Splitgate custom content (Maps, Prefabs, and Game Modes) into the game-ready `.bin` container format. 

> [!CAUTION]
> The underlying code for this project was built by AI.

> [!IMPORTANT] 
> Windows only. This tool relies on a .bat/PowerShell script, so it won't run on macOS or Linux as-is.

## Why is this script needed?
Adding custom maps to Splitgate manually requires specific file structures and a strict `CloudSaveManifest.json`. However, before a map, prefab, or custom gamemode can even be loaded into the game, the raw source files (like `World.cf1047` or `payload.json`) must be properly packaged into standard ZIP archives with a `.bin` extension. 

The **Splitgate-MapConverter** automates this packaging process for creators and archivers. It takes raw files, generates the necessary metadata (`info.json`), applies required hex-patched ZIP comments, and outputs a clean `.bin` file ready to be shared or installed using the Splitgate-MapLoader.

## Features
* **Universal Pipeline:** Processes Maps, Prefabs, and Custom Modes simultaneously by scanning dedicated input folders.
* **Smart Metadata Generation:** Automatically extracts the content name and author from an included `Info.json` or parses it dynamically from a `README.md`.
* **Clean Slugs & Collision Protection:** Generates strict, web-safe filenames (e.g., `code_author_mapname.bin`) and skips packaging if the output file already exists to speed up mass processing.
* **Engine-Accurate Packaging:** Compresses content using standard ZIP layout (DEFLATE method) while appending the required signature comments directly to the End of Central Directory record.
* **One-Click Execution:** A single `.bat` file runs the entire conversion process silently in PowerShell, bypassing strict execution policies.

## Repository Structure
* **`Input/`**: The staging area for your raw files.
  * **`Maps/`**: Drop folders containing your `World.cf1047` and `Screenshot.jpg` here.
  * **`Prefabs/`**: Drop folders containing your `Prefab.cf1047_prefab` and `Screenshot.jpg` here.
  * **`Modes/`**: Drop folders containing your `payload.json` here.
* **`Output/`**: Contains all ready-to-go, converted `.bin` files along with their matching `.jpg` previews.

## How to Install & Use

**1. Prepare your raw files**
* Create a folder for your creation (e.g., `MyCustomMap`).
* Place your raw game files inside it (e.g., `World.cf1047` and `Screenshot.jpg`).
* Include either an `Info.json` or a `README.md` (with `# Mapname` and `# Author: YourName` on the first two lines) so the script can extract the metadata.

**2. Place in Input Directory**
* Move your folder into the corresponding subfolder under `Input/` (e.g., `Input/Maps/MyCustomMap/`).

**3. Run the Converter**
* Double-click `MapConverter.bat` (or whatever you named the versioned batch file).
* The script will scan all input folders, parse the metadata, generate the temporary `info.json`, and package the `.bin` archive.

**4. Retrieve your files**
* Once the script finishes, check the `Output/` directory. Your ready-to-use `.bin` file is complete and ready to be shared or played.
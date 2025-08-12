## Overview

These scripts provide a streamlined workflow for converting Amiibo `.bin` files into a format usable by the Proxmark3 and for simulating them.

-   `gen_amiibo.sh`: Converts `.bin` files to `.eml` files and extracts their UID into a `.key` file.
-   `sim_amiibo.sh`: Simulates an Amiibo using the generated files, intelligently handling state saves.

## Prerequisites

1.  **Proxmark3 Client**: The `pm3` command-line tool must be installed and available in your system's `PATH`.
2.  **Perl**: Required for the conversion script used by `gen_amiibo.sh`.
3.  **Converter Script**: The `pm3_amii_bin2eml.pl` script (from the Proxmark3 repository) must be installed and available in your system's `PATH`.

Tips: 

How to install proxmark3 client -> https://github.com/RfidResearchGroup/proxmark3

---

## `gen_amiibo.sh`

This script converts Amiibo `.bin` dumps into `.eml` files for simulation and extracts the UID into a corresponding `.key` file.

### Usage

```bash
./gen_amiibo.sh -f <file.bin> | -d <directory> [-t]
```

### Modes

-   **Single File Mode**: Process a single `.bin` file.
    ```bash
    ./gen_amiibo.sh -f /path/to/your/amiibo.bin
    ```
    This will create an `eml` folder in the same directory (`/path/to/your/`) containing `amiibo.eml` and `amiibo.key`.

-   **Directory Mode (Localized Output)**: Recursively find and process all `.bin` files in a directory.
    ```bash
    ./gen_amiibo.sh -d /path/to/amiibo_collection/
    ```
    For each `.bin` file found, an `eml` subfolder will be created in its parent directory containing the output files.

-   **Directory Mode (Centralized Output)**: Process all `.bin` files but place all output into a single top-level `eml` folder.
    ```bash
    ./gen_amiibo.sh -d /path/to/amiibo_collection/ -t
    ```
    This will create one folder, `/path/to/amiibo_collection/eml`, and put all generated `.eml` and `.key` files there.

---

## `sim_amiibo.sh`

This script uses `pm3` to simulate an Amiibo. It handles loading the correct data (new or existing) and saves the Amiibo's state after simulation.

### Usage

```bash
./sim_amiibo.sh [-n] <path_to_amiibo_file>
```

-   `<path_to_amiibo_file>`: Path to the `.eml`, `.key`, or `.bin` file for the Amiibo you want to simulate. The script will find the related files automatically.

### Options

-   `-n`: Force simulation of a "new" Amiibo by loading data from the `.eml` file, even if a `.bin` file with saved data exists.

### Behavior

1.  **Loading**:
    -   If you run the script **without** the `-n` flag, it will look for a `.bin` file first. If found, it loads it to continue the simulation with its last saved state.
    -   If a `.bin` file is **not** found, or if you use the `-n` flag, it will load the base `.eml` file, simulating a brand-new Amiibo.

2.  **Saving**:
    -   After the simulation is stopped (by pressing the button on the Proxmark3), the script saves the Amiibo's memory to a `.bin` file in the same directory.
    -   This `.bin` file will be automatically loaded the next time you simulate the same Amiibo (unless you use `-n`).
    -   The save process is safe: it writes to a temporary file first and only replaces the original on success.

### Example Workflow

1.  **Convert an entire collection:**
    ```bash
    ./gen_amiibo.sh -d 'database/Amiibo/Amiibo Bin/'
    ```

2.  **Simulate a specific Amiibo (e.g., Inkling Boy from Splatoon):**
    ```bash
    ./sim_amiibo.sh 'database/Amiibo/Amiibo Bin/Splatoon Amiibo/eml/Inkling Boy.eml'
    ```

3.  **Simulate it again with its saved data:**
    *(The script automatically finds Inkling Boy.bin in the same directory)*
    ```bash
    ./sim_amiibo.sh 'database/Amiibo/Amiibo Bin/Splatoon Amiibo/eml/Inkling Boy.eml'
    ```

4.  **Reset the Amiibo to a new state:**
    ```bash
    ./sim_amiibo.sh -n 'database/Amiibo/Amiibo Bin/Splatoon Amiibo/eml/Inkling Boy.eml'
    ```

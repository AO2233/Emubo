# Emubo

A set of shell scripts to manage and simulate Amiibo using a Proxmark3.

## Device & File

These scripts were tested with the following hardware and firmware:
- **Device**: Proxmark3 Easy
- **Firmware**: [RfidResearchGroup/proxmark3 (iceman)](https://github.com/RfidResearchGroup/proxmark3)
- **Client System**: MacOS 15 in MacBook Air
- **Files**: [AmiiboDB](https://github.com/AmiiboDB/Amiibo), we need the bin files.

## Notes

Some games write data back to the Amiibo (e.g., saving level-up data or account information). 

The `sim_amiibo.sh` script automatically saves the state of the simulated Amiibo to a `.bin` file after use.
This ensures that the next time you simulate the same Amiibo, its progress is retained.

For detailed instructions on the scripts, see [doc.md](doc.md). Have fun and イカす.

<p align="center">
  <img src="https://github.com/user-attachments/assets/e2d87435-ad2a-490e-ac18-ba53cd0f47cd" width=600">
</p>

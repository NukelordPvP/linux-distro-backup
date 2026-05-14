# Linux Utility Scripts

A collection of general-purpose Linux scripts for backing up systems, cloning images, mounting filesystems, verifying data integrity, and working with extracted root filesystems.

---

## 📜 Script Overview

### 🔹 `backup-fedora.sh`
Creates a compressed `.tar.xz` backup of a Fedora-based system.

- Automatically selects backup location (mounted drive or fallback directory)
- Excludes virtual/system directories (`/proc`, `/sys`, `/dev`)
- Runs in the background with logging

---

### 🔹 `backup-manjaro.sh`
Creates a compressed `.tar.xz` backup of a Manjaro-based system.

- Timestamped backups
- Background execution
- Safe exclusions for system directories

📌 Can be easily modified for any distro.

---

### 🔹 `clone_img_to_drive.sh`
Clones a `.img` file directly onto a target drive.

- Performs block-level copy (e.g., using `dd`)
- Used for full system deployment or duplication

⚠️ **Warning:** This will overwrite the target drive completely.

---

### 🔹 `diff_source_vs_backup.sh`
Compares two extracted root filesystems (directories of loose files).

- Lists structural differences
- Compares `/etc/passwd` entries
- Identifies files present in one location but not the other

📌 Requires both source and target to be **mounted or extracted**, not compressed archives.

---

### 🔹 `extract_tarxz_to_drive.sh`
Extracts a `.tar.xz` archive to a target directory or mounted drive.

- Restores full filesystem backups
- Maintains directory structure (permissions depend on tar flags)

---

### 🔹 `mount_&_chroot.sh`
Mounts required system directories and enters a `chroot` environment.

- Mounts `/dev`, `/proc`, `/sys`
- Allows working inside another Linux installation

---

### 🔹 `mount_img.sh`
Mounts a `.img` file using loop devices.

- Useful for inspecting or modifying disk images
- Works with raw disk images

---

### 🔹 `verify_img_vs_drive.sh`
Compares a mounted `.img` filesystem with a mounted directory.

- Checks structure and key system files
- Uses `diff` for identifying differences

📌 Provides a **quick validation**, not a full integrity check.

---

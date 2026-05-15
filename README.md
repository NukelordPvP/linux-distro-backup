# Linux Utility Scripts

A collection of Linux utility scripts for:

- Full Linux system backups
- Root filesystem restoration
- Disk image cloning
- Filesystem comparison
- Chroot recovery
- Storage analysis
- Backup archival

Designed primarily for PS4 Linux environments, but usable on most Linux distributions.

---

# Features

- Automatic backup destination selection
- Background backup execution
- Real-time logging
- Summary logging
- Configurable exclusions
- Persistent remembered backup paths
- Storage analysis tooling
- Safe handling of virtual/system filesystems
- Restore and verification tooling
- Compressed archive generation

---

# Directory Structure

```text
linux-distro-backup/
├── backup-fedora.sh
├── backup-manjaro.sh
├── helper-backup.sh
├── helper-logging.sh
├── helper-process-exclusions.sh
├── common.sh
├── global-exclusions.txt
├── backup-fedora-exclusions.txt
├── backup-manjaro-exclusions.txt
├── topdirs-ignore.txt
├── topdirs.sh
├── extract_tarxz_to_drive.sh
├── clone-img-to-drive.sh
├── mount-img.sh
├── mount-&-chroot.sh
├── verify_img_vs_drive.sh
├── diff-source-vs-backup.sh
└── backups/
```

---

# Backup Scripts

## 🔹 `backup-fedora.sh`

Creates a compressed Linux filesystem backup for Fedora-based systems.

### Features

- Automatic backup destination detection
- Background execution support
- Lock protection against duplicate runs
- Compression support:
  - xz
  - gzip
  - zstd
- Persistent remembered backup path
- Ownership correction for generated files
- Runtime and summary logging

### Example

```bash
bash backup-fedora.sh
```

Custom destination:

```bash
BACKUP_PATH="/mnt/storage/backups" bash backup-fedora.sh
```

---

## 🔹 `backup-manjaro.sh`

Creates a compressed Linux filesystem backup for Manjaro-based systems.

### Features

- Timestamped backups
- Foreground or background execution
- Shared exclusion framework
- Summary statistics logging

### Example

```bash
bash backup-manjaro.sh
```

---

# Backup Framework

## 🔹 `helper-backup.sh`

Core backup engine.

### Handles

- Compression
- Tar archive generation
- Exclusion processing
- Backup validation
- Summary statistics generation

### Supported Compression

```text
xz
gzip
zstd
```

Configured using:

```bash
BACKUP_COMPRESSION
BACKUP_COMPRESSION_LEVEL
```

---

## 🔹 `helper-logging.sh`

Handles:

- Terminal logging
- Summary logging
- Fatal error handling
- Section formatting

---

## 🔹 `common.sh`

Shared helper functions:

- Timestamp generation
- Backup path selection
- Remembered backup path storage
- Filename generation
- Directory creation

---

# Exclusion System

## 🔹 `global-exclusions.txt`

Global exclusions shared across backups.

Examples:

- `/proc`
- `/sys`
- caches
- browser profiles
- machine identity files
- Steam cache/runtime data
- temporary files

---

## 🔹 `backup-fedora-exclusions.txt`

Fedora-specific exclusions.

---

## 🔹 `backup-manjaro-exclusions.txt`

Manjaro-specific exclusions.

---

## 🔹 `topdirs-ignore.txt`

Directories hidden from `topdirs.sh` output.

This allows:

- keeping directories inside backups
- hiding known large/noisy paths from storage analysis

Examples:

- `/usr`
- Flatpak runtimes
- Steam runtimes
- Proton data

---

# Storage Analysis

## 🔹 `topdirs.sh`

Displays the largest directories/files while respecting exclusion and ignore lists.

### Reads

- `global-exclusions.txt`
- distro exclusions
- `topdirs-ignore.txt`

### Example

```bash
bash topdirs.sh
```

---

# Restore / Deployment Scripts

## 🔹 `extract_tarxz_to_drive.sh`

Extracts a `.tar.xz` archive onto a mounted filesystem.

---

## 🔹 `clone-img-to-drive.sh`

Clones a raw `.img` file directly onto a target drive.

⚠️ Completely overwrites the destination drive.

---

# Mounting Utilities

## 🔹 `mount-img.sh`

Mounts raw `.img` files using loop devices.

---

## 🔹 `mount-&-chroot.sh`

Mounts required pseudo-filesystems and enters a `chroot`.

### Mounts

```text
/dev
/proc
/sys
/run
```

---

# Verification / Diff Utilities

## 🔹 `verify_img_vs_drive.sh`

Compares a mounted image against another mounted filesystem.

---

## 🔹 `diff-source-vs-backup.sh`

Compares two extracted root filesystems.

### Checks

- Structural differences
- Missing files
- `/etc/passwd` differences

---

# Logs

## Runtime Log

Contains:

- tar output
- exclusion loading
- errors
- runtime activity

Example:

```text
backup.log
```

---

## Summary Log

Contains:

- backup destination
- compression used
- file counts
- excluded item counts
- archive size
- runtime duration

Example:

```text
backup_summary.log
```

---

# Example Workflow

## Create Backup

```bash
bash backup-fedora.sh
```

---

## Restore Backup

```bash
bash extract_tarxz_to_drive.sh
```

---

## Enter Chroot

```bash
bash mount-\&-chroot.sh
```

---

## Analyze Storage Usage

```bash
bash topdirs.sh
```

---

# Notes

- Scripts are written for Bash
- Most operations require root privileges
- Exclusions prioritize:
  - privacy
  - cache removal
  - runtime filesystem safety
- Compatible with most Linux distributions with minor modification

---

# Intended Use Cases

- PS4 Linux backups
- Long-term archival
- External storage backups
- Linux migration
- Root filesystem restoration
- Offline archive sharing
- Disk image deployment

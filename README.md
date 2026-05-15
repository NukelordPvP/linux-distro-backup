# Linux Utility Scripts

A collection of Linux utility scripts for:

- Full Linux system backups
- Root filesystem restoration
- Disk image cloning
- Filesystem comparison
- Chroot recovery environments
- Storage analysis
- Backup automation

Designed primarily for PS4 Linux environments, but usable on most Linux distributions.

---

# Features

- Automatic backup destination selection
- Background backup execution
- Real-time logging
- Summary logging
- Configurable exclusions
- Persistent remembered backup paths
- Storage analysis tools
- Safe handling of virtual/system filesystems
- Restore and verification tooling

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

Creates a compressed Linux system backup for Fedora-based systems.

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
- Separate runtime log and summary log

### Generated Files

```text
backup.tar.xz
backup.log
backup_summary.log
```

### Example

```bash
bash backup-fedora.sh
```

Custom backup filename:

```bash
bash backup-fedora.sh mybackup
```

Custom destination:

```bash
BACKUP_PATH="/mnt/storage/backups" bash backup-fedora.sh
```

---

## 🔹 `backup-manjaro.sh`

Creates a compressed Linux system backup for Manjaro-based systems.

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

### Responsibilities

- Compression handling
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

Provides:

- Terminal logging
- Summary logging
- Fatal error handling
- Section formatting

---

## 🔹 `common.sh`

Shared framework functions:

- Timestamp generation
- Backup path selection
- Remembered backup path storage
- Filename generation
- Directory creation helpers

---

# Exclusion System

## 🔹 `global-exclusions.txt`

Global exclusions shared across backups.

Examples:

- `/proc`
- `/sys`
- browser profiles
- caches
- machine identity files
- Steam caches
- temporary files

---

## 🔹 `backup-fedora-exclusions.txt`

Fedora-specific exclusions.

---

## 🔹 `backup-manjaro-exclusions.txt`

Manjaro-specific exclusions.

---

## 🔹 `topdirs-ignore.txt`

Directories hidden from `topdirs.sh` analysis output.

This allows:

- keeping directories in backups
- while hiding known large/noisy paths from storage analysis

Examples:

- `/usr`
- Steam runtimes
- Flatpak runtimes
- Proton data

---

# Storage Analysis

## 🔹 `topdirs.sh`

Displays the largest directories/files on the system while respecting exclusion and ignore lists.

### Features

- Reads:
  - `global-exclusions.txt`
  - distro exclusions
  - `topdirs-ignore.txt`
- Filters noisy directories
- Helps identify:
  - unexpected storage growth
  - forgotten files
  - large user data

### Example

```bash
bash topdirs.sh
```

---

# Restore / Deployment Scripts

## 🔹 `extract_tarxz_to_drive.sh`

Extracts a `.tar.xz` backup archive onto a mounted filesystem.

### Use Cases

- Full system restoration
- Migration to another drive
- Recovery operations

---

## 🔹 `clone-img-to-drive.sh`

Clones a raw `.img` file directly onto a target drive.

### Warning

⚠️ This completely overwrites the destination drive.

### Use Cases

- Full disk deployment
- PS4 Linux duplication
- Rapid restore workflows

---

# Mounting Utilities

## 🔹 `mount-img.sh`

Mounts raw `.img` files using loop devices.

### Useful For

- Inspecting disk images
- Editing images
- Recovery operations

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

### Useful For

- Recovery
- Repairing broken installs
- Rebuilding initramfs
- Reinstalling bootloaders

---

# Verification / Diff Utilities

## 🔹 `verify_img_vs_drive.sh`

Compares a mounted image against another mounted filesystem.

### Useful For

- Quick restore verification
- Structural comparison

---

## 🔹 `diff-source-vs-backup.sh`

Compares two extracted root filesystems.

### Features

- Structural difference checks
- Missing file detection
- `/etc/passwd` comparison

---

# Logs

## Runtime Log

Contains:

- detailed tar output
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
- final archive size
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

- Scripts are designed for Bash
- Most operations require root privileges
- Exclusions are intentionally aggressive for:
  - privacy
  - caches
  - runtime filesystems
- Compatible with most Linux distributions with minor modification

---

# Recommended Compression

## Fast

```text
zstd -5
```

## Balanced

```text
xz -3
```

## Maximum Compression

```text
xz -9
```

---

# Intended Use Cases

- PS4 Linux backups
- Disaster recovery
- Offline archival
- Linux migration
- Root filesystem restoration
- Storage auditing
- Image deployment

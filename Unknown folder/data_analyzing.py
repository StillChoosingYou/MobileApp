import os

# ==============================
# SETTINGS
# ==============================
# Change this to the drive or folder you want to scan
SCAN_PATH = r"C:\Users\User"      # Example: "D:\\" or "C:\\Users\\YourName"

TOP_FILES = 50
TOP_FOLDERS = 30


# ==============================
# Convert Bytes
# ==============================
def human_readable(size):
    for unit in ["B", "KB", "MB", "GB", "TB"]:
        if size < 1024:
            return f"{size:.2f} {unit}"
        size /= 1024
    return f"{size:.2f} PB"


# ==============================
# Get Folder Size
# ==============================
def folder_size(path):
    total = 0
    try:
        for root, dirs, files in os.walk(path):
            for file in files:
                try:
                    fp = os.path.join(root, file)
                    total += os.path.getsize(fp)
                except:
                    pass
    except:
        pass
    return total


print("=" * 60)
print("Scanning...")
print("This may take several minutes.")
print("=" * 60)

largest_files = []
largest_folders = []

# ------------------------------
# Scan Files
# ------------------------------
for root, dirs, files in os.walk(SCAN_PATH):
    for file in files:
        try:
            filepath = os.path.join(root, file)
            size = os.path.getsize(filepath)
            largest_files.append((size, filepath))
        except:
            pass

largest_files.sort(reverse=True)

# ------------------------------
# Scan Folder Sizes
# ------------------------------
for item in os.listdir(SCAN_PATH):
    full = os.path.join(SCAN_PATH, item)

    if os.path.isdir(full):
        print(f"Calculating: {full}")
        size = folder_size(full)
        largest_folders.append((size, full))

largest_folders.sort(reverse=True)

# ------------------------------
# Display
# ------------------------------
print("\n" + "=" * 60)
print("TOP LARGEST FILES")
print("=" * 60)

for size, path in largest_files[:TOP_FILES]:
    print(f"{human_readable(size):>10}  {path}")

print("\n" + "=" * 60)
print("TOP LARGEST FOLDERS")
print("=" * 60)

for size, path in largest_folders[:TOP_FOLDERS]:
    print(f"{human_readable(size):>10}  {path}")

# ------------------------------
# Save Report
# ------------------------------
with open("storage_report.txt", "w", encoding="utf-8") as f:

    f.write("TOP LARGEST FILES\n")
    f.write("=" * 60 + "\n")

    for size, path in largest_files[:TOP_FILES]:
        f.write(f"{human_readable(size):>10}  {path}\n")

    f.write("\nTOP LARGEST FOLDERS\n")
    f.write("=" * 60 + "\n")

    for size, path in largest_folders[:TOP_FOLDERS]:
        f.write(f"{human_readable(size):>10}  {path}\n")

print("\nReport saved as storage_report.txt")
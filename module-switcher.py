import os
import subprocess
import sys
import requests
import shutil
import time
import zipfile

# Ensure required packages are installed
REQUIRED_LIBS = ["requests"]

def install_packages():
    for lib in REQUIRED_LIBS:
        try:
            __import__(lib)
        except ImportError:
            print(f"Installing {lib}...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", lib])

install_packages()

# Constants
GITHUB_FOLDER_URL = "https://github.com/DaddyOptis/DISCORD-STEREO-MODULE-SWISHER/tree/main/stereo%20%2B%20modules/discord_voice"
UPDATE_CHECK_URL = "https://raw.githubusercontent.com/DaddyOptis/DISCORD-STEREO-MODULE-SWISHER/refs/heads/main/module-switcher.bat"
UPDATE_FILENAME = "update.bat"
TEMP_FOLDER = os.path.join(os.getenv('TEMP'), 'discord_voice_update')
DISCORD_PATH = os.path.join(os.getenv('LOCALAPPDATA'), 'Discord')
MODULES_FOLDER = "modules"
VOICE_MODULE_PREFIX = "discord_voice-1"
MAX_RETRIES = 3
MIN_FILE_SIZE_BYTES = 2000  # Minimum file size (2 GB = 2,147,483,648 bytes)

def check_for_updates():
    print("Checking for updates...")
    try:
        remote_content = requests.get(UPDATE_CHECK_URL).text
        with open(UPDATE_FILENAME, "r") as current_file:
            current_content = current_file.read()
        
        if current_content != remote_content:
            print("Update available. Downloading...")
            with open(UPDATE_FILENAME, "w") as update_file:
                update_file.write(remote_content)
            
            subprocess.run([UPDATE_FILENAME], shell=True)
            os.remove(UPDATE_FILENAME)
            exit()
        else:
            print("No update available.")
    except Exception as e:
        print(f"Unable to check for updates: {e}")

def kill_discord():
    print("Killing Discord processes...")
    subprocess.run(["taskkill", "/F", "/IM", "discord.exe"], stderr=subprocess.DEVNULL)

def download_with_retry(url, filepath):
    for attempt in range(MAX_RETRIES):
        try:
            print(f"Attempt {attempt + 1} of {MAX_RETRIES}...")
            response = requests.get(url, stream=True)
            with open(filepath, 'wb') as file:
                for chunk in response.iter_content(chunk_size=8192):
                    file.write(chunk)
            if os.path.getsize(filepath) < MIN_FILE_SIZE_BYTES:
                raise ValueError("Downloaded file is too small.")
            return True
        except Exception as e:
            print(f"Error: {e}. Retrying in 5 seconds...")
            time.sleep(5)
    return False

def extract_zip(zip_path, extract_to):
    print("Extracting files...")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_to)

def main():
    os.makedirs(TEMP_FOLDER, exist_ok=True)
    check_for_updates()
    kill_discord()

    # Construct ZIP URL
    zip_url = GITHUB_FOLDER_URL.replace("/tree/main/", "/archive/main/") + ".zip"
    zip_path = os.path.join(TEMP_FOLDER, 'discord_voice.zip')
    
    if not download_with_retry(zip_url, zip_path):
        print("Failed to download files after retries.")
        return

    extract_zip(zip_path, TEMP_FOLDER)
    os.remove(zip_path)

    # Locate Discord directory
    discord_dirs = [os.path.join(DISCORD_PATH, d) for d in os.listdir(DISCORD_PATH) if d.startswith('app-')]
    if not discord_dirs:
        print("Discord installation not found.")
        return

    latest_discord_path = discord_dirs[-1]
    voice_module_path = os.path.join(latest_discord_path, MODULES_FOLDER, VOICE_MODULE_PREFIX)

    if not os.path.exists(voice_module_path):
        print("Voice module not found.")
        return
    
    # Copy extracted files
    extracted_dir = os.path.join(TEMP_FOLDER, "DISCORD-STEREO-MODULE-SWISHER-main", "stereo  + modules", "discord_voice")
    for root, dirs, files in os.walk(extracted_dir):
        for file in files:
            src_file = os.path.join(root, file)
            dest_file = os.path.join(voice_module_path, file)
            shutil.copy2(src_file, dest_file)

    shutil.rmtree(TEMP_FOLDER)
    print("Update complete.")

if __name__ == "__main__":
    main()

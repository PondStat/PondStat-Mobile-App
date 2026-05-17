import urllib.request
import zipfile
import os

url = "https://fonts.google.com/download?family=Inter"
zip_path = "inter.zip"
extract_path = "assets/fonts/Inter"

print("Downloading Inter font...")
urllib.request.urlretrieve(url, zip_path)

print("Extracting...")
with zipfile.ZipFile(zip_path, 'r') as zip_ref:
    zip_ref.extractall(extract_path)

os.remove(zip_path)
print("Done!")

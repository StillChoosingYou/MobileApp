import yt_dlp
import os

def download_yt_video(url):
    # Create downloads folder if it doesn't exist
    os.makedirs("downloads", exist_ok=True)

    ydl_opts = {
        'format': 'bestvideo[height<=1080]+bestaudio/best',  # Good quality + audio
        'outtmpl': 'downloads/%(title)s.%(ext)s',            # Save with video title
        'noplaylist': True,                                  # Only download single video
        'merge_output_format': 'mp4',                        # Force mp4 output
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        print("Downloading...")
        ydl.download([url])
        print("Download completed!")

if __name__ == "__main__":
    url = input("Enter YouTube URL: ").strip()
    download_yt_video(url)
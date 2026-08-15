import yt_dlp
import os

def download_youtube_video(url, output_path="downloads"):
    """
    Download a YouTube video using yt-dlp.
    
    Args:
        url (str): YouTube video URL
        output_path (str): Folder where the video will be saved
    """
    # Create output folder if it doesn't exist
    os.makedirs(output_path, exist_ok=True)

    # yt-dlp options
    ydl_opts = {
        'outtmpl': os.path.join(output_path, '%(title)s.%(ext)s'),  # Save as "Video Title.mp4"
        'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',  # Prefer MP4
        'merge_output_format': 'mp4',
        'noplaylist': True,          # Download only the single video, not the whole playlist
        'quiet': False,              # Show progress
        'progress_hooks': [progress_hook],
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            print(f"Downloading: {url}")
            ydl.download([url])
            print("\n✅ Download completed successfully!")
    except Exception as e:
        print(f"\n❌ Error: {e}")


def progress_hook(d):
    """Show download progress"""
    if d['status'] == 'downloading':
        percent = d.get('_percent_str', 'N/A').strip()
        speed = d.get('_speed_str', 'N/A').strip()
        eta = d.get('_eta_str', 'N/A').strip()
        print(f"\rProgress: {percent} | Speed: {speed} | ETA: {eta}", end='', flush=True)
    elif d['status'] == 'finished':
        print("\nProcessing finished, now converting...")


if __name__ == "__main__":
    video_url = input("Enter YouTube URL: ").strip()
    
    if not video_url:
        print("No URL provided.")
    else:
        download_youtube_video(video_url)
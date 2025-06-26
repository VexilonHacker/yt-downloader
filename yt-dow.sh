#!/bin/bash

# Define constants
declare -r LOGO_DIR="logo"
declare -r DOWNLOADED_HISTORY="$HOME/.yt_videos_history.txt"
declare -r MUSIC_DIR="$HOME/Music"
declare -r VIDEOS_DIR="$HOME/Videos/"

# Function to check if the format code corresponds to an audio format
is_audio_format() {
    local selected_format_code="$1"
    [[ " ${AUDIO_FORMAT_CODES[@]} " =~ " ${selected_format_code} " ]]
}

# Function to display available formats and prompt user to choose
choose_format() {
    local video_url="$1"
    local format_code=""
    local format_type=""
    local output_dir=""

    # Get available audio format codes
    AUDIO_FORMAT_CODES=($(yt-dlp --list-formats "$video_url" | grep "audio only" | awk '{print $1}'))

    echo "Available formats:"
    yt-dlp -F --no-warnings "$video_url"
    read -p "Enter the format code you want to download: " format_code

    if is_audio_format "$format_code"; then
        format_type="mp3"
        output_dir="$MUSIC_DIR"
    else
        format_type="mp4"
        output_dir="$VIDEOS_DIR"
        AUDIO_FORMAT_CODE=($(yt-dlp --no-warnings --list-formats "$video_url" | grep "audio only" | awk '{print $1}' | tail -n 1))
    fi

    # Ensure output directory exists
    mkdir -p "$output_dir"

    if is_audio_format "$format_code"; then
        yt-dlp -f "$format_code" --extract-audio --audio-format "$format_type" --embed-thumbnail -o "$output_dir/%(title)s.$format_type" "$video_url"
    else
        yt-dlp -f "$format_code+$AUDIO_FORMAT_CODE" --merge-output-format "$format_type" -o "$output_dir/%(title)s.$format_type" "$video_url"
    fi

    # Check if the download and conversion were successful
    if [ $? -eq 0 ]; then
        video_name=$(yt-dlp --get-filename -o "%(title)s" "$video_url")
        save_download_info "$video_name" "$video_url" "$format_type"
        printf "\e[38;5;33mVideo '%s' has been successfully downloaded ✓\e[0m\n" "$video_name"
        printf "\e[0;32mInformation about the video has been saved in yt_videos_history.txt :) ✓ \e[0m\n"
    else
        printf "\e[31mError: Unable to download and convert the audio to %s. Check your internet connection and try again.\e[0m\n" "$format_type"
    fi
}

# Function to save download information to history
save_download_info() {
    local video_name="$1"
    local video_url="$2"
    local format_type="$3"

    {
        echo "video_name: $video_name" 
        echo "url: $video_url"
        echo "type: $format_type"
        echo "=========================================="
    } >> "$DOWNLOADED_HISTORY"
}

# Function to print the logo
print_logo() {
    logo='
	             /$$                /$$                                   /$$                           /$$                    
	            | $$               | $$                                  | $$                          | $$                    
	 /$$   /$$ /$$$$$$         /$$$$$$$  /$$$$$$  /$$  /$$  /$$ /$$$$$$$ | $$  /$$$$$$   /$$$$$$   /$$$$$$$  /$$$$$$   /$$$$$$ 
	| $$  | $$|_  $$_//$$$$$$ /$$__  $$ /$$__  $$| $$ | $$ | $$| $$__  $$| $$ /$$__  $$ |____  $$ /$$__  $$ /$$__  $$ /$$__  $$
	| $$  | $$  | $$ |______/| $$  | $$| $$  \ $$| $$ | $$ | $$| $$  \ $$| $$| $$  \ $$  /$$$$$$$| $$  | $$| $$$$$$$$| $$  \__/
	| $$  | $$  | $$ /$$     | $$  | $$| $$  | $$| $$ | $$ | $$| $$  | $$| $$| $$  | $$ /$$__  $$| $$  | $$| $$_____/| $$      
	|  $$$$$$$  |  $$$$/     |  $$$$$$$|  $$$$$$/|  $$$$$/$$$$/| $$  | $$| $$|  $$$$$$/|  $$$$$$$|  $$$$$$$|  $$$$$$$| $$      
	 \____  $$   \___/        \_______/ \______/  \_____/\___/ |__/  |__/|__/ \______/  \_______/ \_______/ \_______/|__/      
	 /$$  | $$                                                                                                                 
	|  $$$$$$/                                                                                                                 
	 \______/                                                                                                                  

'
    printf "%s\n" "$logo"

}

# Main script
print_logo

if command -v yt-dlp &> /dev/null; then
    # Check if a URL was provided as an argument
    if [ $# -gt 0 ]; then
        video_url="$1"
    else
        read -p "Enter the YouTube video URL: " video_url
    fi
    
    # Validate the URL before proceeding
    if [[ "$video_url" =~ ^https?://(www\.)?youtube\.com/ || "$video_url" =~ ^https?://youtu\.be/ ]]; then
        choose_format "$video_url"
    else
        printf "\e[31mError: Invalid YouTube video URL. Please enter a valid URL.\e[0m\n"
    fi
else
    printf "\e[31myt-dlp is not installed. Please install it to use this script.\e[0m\n"
fi


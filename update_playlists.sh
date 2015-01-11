#!/bin/bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

USER=musicbot
ROOT_DIRECTORY=/opt/musicbot
MUSIC_DIRECTORY=/home/musicbot/music
PLAYLIST_DIRECTORY=/home/musicbot/playlist

track_fixname() {
    old_path=$1
    new_path="${file//[^a-zA-Z0-9-._\ \/]/}"
    
    if [ "$old_path" != "$new_path" ]; then
        mv "$old_path" "$new_path"
    fi
    echo "$new_path"
}

playlist_fixname() {
    fixed_name=$1
    # We map videos downloaded from YT to playlist name youtube
    if [ "$1" == "Youtube downloads" ]; then
        fixed_name="youtube"
    fi
    echo "$fixed_name"
}

# Check if playlist file exists
playlist_exists() {
    if [ -f "$PLAYLIST_DIRECTORY/$1" ]; then
        echo "1"
    else
        echo "0"
    fi
}

# Create playlist file
playlist_create() {
    fixed_name=$(playlist_fixname "$1")

    if [ $(playlist_exists $fixed_name) = "1" ]; then
        echo -e "Wiping playlist file: $fixed_name"
        cat /dev/null > "$PLAYLIST_DIRECTORY/$fixed_name"
    else
        echo -e "Creating playlist file: $fixed_name"
        su $USER -c "touch $PLAYLIST_DIRECTORY/$fixed_name"
    fi
    
    echo -e "Adding files to playlist: $fixed_name"
    for file in $MUSIC_DIRECTORY/$1/* ; do
        if [ -f "$file" ]; then
            #echo "$file";
            fixed_file_name=$(track_fixname "$file");
            #echo "$fixed_file_name"
            file_path=$(basename "$fixed_file_name")
            file_extension="${file_path##*.}"
            file_name="${file_path%.*}"
            echo "../music/${1}/${file_name}.${file_extension}" >> "$PLAYLIST_DIRECTORY/$fixed_name"
        fi
    done
}

playlist_shuffle() {
    fixed_name=$(playlist_fixname "$1")

    if [ $(playlist_exists $fixed_name) = "1" ]; then
        echo -e "Shuffling playlist: $fixed_name"
        sort -R "$PLAYLIST_DIRECTORY/$fixed_name" -o "$PLAYLIST_DIRECTORY/$fixed_name"
    fi
}

for directory in $MUSIC_DIRECTORY/* ; do
    if [ -d "$directory" ]; then
        name=${directory##*/}
        playlist_create "$name"
        sleep 1
        playlist_shuffle "$name"
        echo -e ""
    fi
done

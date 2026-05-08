# T2000 Topical Series - Transcript Fetch Summary

Date: 2026-05-06
Playlist: https://www.youtube.com/playlist?list=PLQ3qrb3QVe8AAURCzjnVZymwdDQDku5dj

## Results
- Total unique videos: 270 (271 IDs minus 1 duplicate: DlNHVtHnUe0 at indices 166 & 167)
- Successful transcripts: 0
- Placeholder files: 270
- Skipped duplicates: 1

## Why no transcripts?
YouTube's timedtext API (used by youtube-transcript-api) blocks requests from
this server's cloud provider IP range (HTTP 429 / IP block). The oembed API
works fine for fetching video titles, which are included in each placeholder.

## What's in each file
Each file (`VIDEOID.md`) has YAML frontmatter with:
- video_id, title, url
- playlist, playlist_url, playlist_index
- scripture (extracted from title when present)
- status: placeholder
- error description

## Known issues
- Video 166 (DlNHVtHnUe0) and 167 are the same ID — only one file created
- Video 271 (BPrbRlbCVsU) appears at end of playlist with title "187 Fullness of Joy, John 16:22"
- All transcripts need to be re-fetched from an IP not blocked by YouTube, or via an alternative method

## File count
270 placeholder files + this summary = 271 total files in _transcripts/

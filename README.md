# Meeting Transcriber

### Requirements

* [Blackhole Virtual Audio Driver](https://github.com/ExistentialAudio/BlackHole) (combined output and aggregate device)
* Whisper
* ffmpeg
* OpenAI API Key

### Start recording

```sh
bundle exec ruby meeting_transcriber.rb --record
```

CTRL+C to stop recording.

### Transcribe recording

```sh
bundle exec ruby meeting_transcriber.rb --transcribe <recording_file>
```

### Summarize notes

```sh
bundle exec ruby meeting_transcriber.rb --summarize <transcription_file>
```

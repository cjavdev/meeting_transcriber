#!/usr/bin/env ruby

require 'optparse'
require 'open3'
require 'json'
require 'openai'
require 'date'
require 'byebug'

class MeetingTranscriber
  def initialize
    @options = {}

    parse_options

    api_key = ENV.fetch('OPENAI_API_KEY', nil)
    @openai_client = OpenAI::Client.new(access_token: api_key, log_errors: true)
  end

  def parse_options
    OptionParser.new do |opts|
      opts.banner = "Usage: meeting_transcriber.rb [options]"

      opts.on("-r", "--record", "Record the meeting") do
        @options[:record] = true
      end

      opts.on("-t", "--transcribe FILE", "Transcribe the recorded audio file") do |file|
        @options[:transcribe] = file
      end

      opts.on("-s", "--summarize FILE", "Summarize the transcription file") do |file|
        @options[:summarize] = file
      end

      opts.on("-h", "--help", "Show this help message") do
        puts opts
        exit
      end
    end.parse!
  end

  def run
    if @options[:record]
      record_meeting
    elsif @options[:transcribe]
      transcribe_meeting(@options[:transcribe])
    elsif @options[:summarize]
      summarize_meeting(@options[:summarize])
    else
      puts "Please specify an action: --record, --transcribe, or --summarize"
    end
  end

  def record_meeting
    puts "Recording meeting... Press Ctrl+C to stop."
    filename = "meeting_#{Time.now.strftime('%Y%m%d_%H%M%S')}.wav"
    command = "ffmpeg -f avfoundation -i ':1' -ac 2 -ar 16000 -c:a pcm_s16le -b:a 160k -y #{filename}"
    p command
    system(command)
    puts "Meeting recorded: #{filename}"
  end

  def transcribe_meeting(audio_file)
    puts "Transcribing meeting..."
    output, status = Open3.capture2e(
      "/Users/cjavilla/repos/whisper.cpp/main",
      "-m", "/Users/cjavilla/repos/whisper.cpp/models/ggml-large-v3.bin",
      "--diarize",
      "--output-txt",
      "-of", audio_file,
      audio_file
    )
    if status.success?
      puts "Transcription complete. Output saved to #{audio_file}.txt"
    else
      puts "Error during transcription: #{output}"
    end
  end

  def summarize_meeting(transcription_file)
    puts "Summarizing meeting..."
    transcription = File.read(transcription_file)

    response = @openai_client.chat(
      parameters: {
        model: "gpt-4o-2024-08-06",
        messages: [
          { role: "system",
            content: "You are a helpful assistant that summarizes meeting transcripts and extracts high level takeaways and action items.", },
          { role: "user",
            content: "Please summarize the following meeting transcript and list any action items in a simple bulleted format with 2 levels of nesting:\n\n#{transcription}", },
        ],
        temperature: 0.7,
      },
    )

    summary = response.dig("choices", 0, "message", "content")

    output_file = "meeting_summary_#{Date.today}.md"
    File.write(output_file, summary)
    puts "Summary and action items saved to #{output_file}"
  end
end

MeetingTranscriber.new.run

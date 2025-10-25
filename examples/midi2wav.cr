require "option_parser"
require "../src/tiny_sound_font"
require "./wav"

# Simple MIDI to WAV converter using TinySoundFont high-level API and TinyMidiLoader.
# It renders a MIDI file to a WAV file (no realtime audio backend required).

LibTML = TinySoundFont::LibTML

DEFAULT_SAMPLE_RATE  = 44_100
DEFAULT_GAIN_DB      = -10.0_f32
DEFAULT_OUTPUT_MODE  = TinySoundFont::OutputMode::StereoInterleaved
DEFAULT_BLOCK_SIZE   = 64
DEFAULT_SOUNDFONT_SF2 = {{ read_file("#{__DIR__}/../ext/florestan-subset.sf2") }}

struct CliOptions
  property midi_path : String?
  property soundfont_path : String?
  property output_path : String?
  property sample_rate : Int32 = DEFAULT_SAMPLE_RATE
  property gain_db : Float32 = DEFAULT_GAIN_DB
  property block_size : Int32 = DEFAULT_BLOCK_SIZE
  property output_mode : TinySoundFont::OutputMode = DEFAULT_OUTPUT_MODE
  property drums_channel : Int32 = 9
end

# Extract MIDI message parameters from TinyMidiLoader's packed format
private def midi_param_first(msg) : Int32
  (msg.param & 0xFF).to_i
end

private def midi_param_second(msg) : Int32
  ((msg.param >> 8) & 0xFF).to_i
end

private def calculate_total_duration_ms(midi_sequence) : UInt32
  LibTML.get_info(midi_sequence, out _channels, out _programs, out _notes, out _start_ms, out duration_ms)
  duration_ms + 1000_u32
end

private def process_midi_message(sf : TinySoundFont::SoundFont, msg, drums_channel : Int32)
  channel = sf.channel(msg.channel)
  case TinySoundFont::LibTML::MessageType.new(msg.type)
  when .program_change?
    program = midi_param_first(msg)
    channel.set_preset_number(program, drums: msg.channel == drums_channel)
  when .note_on?
    note = midi_param_first(msg)
    velocity = midi_param_second(msg)
    if velocity == 0
      channel.note_off(note)
    else
      channel.note_on(note, velocity / 127.0_f32)
    end
  when .note_off?
    note = midi_param_first(msg)
    channel.note_off(note)
  when .pitch_bend?
    channel.pitch_wheel = msg.param
  when .control_change?
    controller = midi_param_first(msg)
    value = midi_param_second(msg)
    channel.midi_control(controller, value)
  end
end

private def render_midi_to_audio(sf : TinySoundFont::SoundFont,
                                  midi_sequence,
                                  total_frames : Int32,
                                  block_size : Int32,
                                  channel_count : Int32,
                                  drums_channel : Int32) : Slice(Float32)
  audio_buffer = Slice(Float32).new(total_frames * channel_count)
  frames_written = 0
  current_time_ms = 0.0
  current_message = midi_sequence

  while frames_written < total_frames
    frames_to_render = Math.min(block_size, total_frames - frames_written)
    next_time_ms = current_time_ms + frames_to_render * (1000.0 / sf.sample_rate)

    while !current_message.null? && current_message.value.time <= next_time_ms
      break if current_message.value.time < current_time_ms
      process_midi_message(sf, current_message.value, drums_channel)
      current_message = current_message.value.next
    end

    output_segment = audio_buffer[frames_written * channel_count, frames_to_render * channel_count]
    sf.render_float!(output_segment, frames_to_render)

    frames_written += frames_to_render
    current_time_ms = next_time_ms
  end

  audio_buffer
end

# Parse CLI
options = CliOptions.new
# Parse CLI
options = CliOptions.new
parser = OptionParser.new do |p|
  p.summary_width = 20
  p.banner = "Usage: midi2wav [options] -m <midi_file> [-s <soundfont.sf2>]"
  p.on("-m", "--midi PATH", "MIDI file path") { |v| options.midi_path = v }
  p.on("-s", "--sf2 PATH", "SoundFont (.sf2) path (default: florestan-subset.sf2)") { |v| options.soundfont_path = v }
  p.on("-o", "--out PATH", "Output WAV path (default: <midi>.wav)") { |v| options.output_path = v }
  p.on("--sr N", "Sample rate (default: #{DEFAULT_SAMPLE_RATE})") { |v| options.sample_rate = v.to_i }
  p.on("--gain DB", "Global gain in dB (default: #{DEFAULT_GAIN_DB})") { |v| options.gain_db = v.to_f32 }
  p.on("--block N", "Block size in frames (default: #{DEFAULT_BLOCK_SIZE})") { |v| options.block_size = v.to_i }
  p.on("--mono", "Render mono output") { options.output_mode = TinySoundFont::OutputMode::Mono }
  p.on("--drums-channel N", "Drums channel index (default: 9, -1 to disable)") { |v| options.drums_channel = v.to_i }
  p.on("-h", "--help", "Show help") { puts p; exit 0 }
end
parser.parse

midi_path = options.midi_path || ARGV[0]?
soundfont_path = options.soundfont_path || ARGV[1]?

unless midi_path
  STDERR.puts parser
  exit 1
end

raise "MIDI file not found: #{midi_path}" unless File.exists?(midi_path)

if soundfont_path
  raise "SoundFont file not found: #{soundfont_path}" unless File.exists?(soundfont_path)
end

output_path = options.output_path || (File.basename(midi_path, File.extname(midi_path)) + ".wav")

midi_sequence = LibTML.load_filename(midi_path)
raise "Failed to load MIDI file: #{midi_path}" if midi_sequence.null?

begin
  duration_ms = calculate_total_duration_ms(midi_sequence)
  total_frames = (duration_ms.to_f64 * options.sample_rate / 1000.0).ceil.to_i
  channel_count = (options.output_mode == TinySoundFont::OutputMode::Mono ? 1 : 2)

  sf = if soundfont_path
    TinySoundFont::SoundFont.new(soundfont_path, options.sample_rate, options.output_mode, options.gain_db)
  else
    TinySoundFont::SoundFont.from_memory(DEFAULT_SOUNDFONT_SF2.to_slice, options.sample_rate, options.output_mode, options.gain_db)
  end

  begin
    if options.drums_channel >= 0
      sf.channel(options.drums_channel).set_bank_and_preset(128, 0)
    end

    audio_data = render_midi_to_audio(sf, midi_sequence, total_frames, options.block_size, channel_count, options.drums_channel)

    WAV.write_f32(output_path, options.sample_rate, channel_count, audio_data)
    puts "Wrote #{output_path} (#{duration_ms} ms, #{options.sample_rate} Hz, #{channel_count == 1 ? "mono" : "stereo"})"
  ensure
    sf.close
  end
ensure
  LibTML.free(midi_sequence)
end

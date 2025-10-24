require "../src/tiny_sound_font"
require "./wav"

# Example3 using high-level API + TinyMidiLoader: offline render MIDI to WAV.

LibTML = TinySoundFont::LibTML

SAMPLE_RATE      =    44_100
CHANNELS         =         2
BLOCK            =        64
GAIN_DB          = -10.0_f32
BYTES_PER_SAMPLE =         2

def calculate_length(first_msg)
  LibTML.get_info(
    first_msg,
    out _used_ch,
    out _used_pg,
    out _total_notes,
    out _time_first,
    out time_len
  )
  time_len + 1000_u32 # Add tail for releases
end

def configure_synth(sf : TinySoundFont::SoundFont)
  sf.set_output(TinySoundFont::OutputMode::StereoInterleaved, SAMPLE_RATE, GAIN_DB)
  sf.channel(9).set_bank_and_preset(128, 0) # Map channel 9 to percussion
end

def render_midi(sf : TinySoundFont::SoundFont, first_msg, total_frames)
  out_f32 = Slice(Float32).new(total_frames * CHANNELS)
  write_frames = 0
  msec = 0.0
  current = first_msg

  while write_frames < total_frames
    block = Math.min(BLOCK, total_frames - write_frames)
    next_msec = msec + block * (1000.0 / SAMPLE_RATE)

    # Dispatch all MIDI messages up to next_msec
    while !current.null? && current.value.time <= next_msec
      break if current.value.time < msec
      dispatch_message(sf, current.value)
      current = current.value.next
    end

    # Render this block
    seg = out_f32[write_frames * CHANNELS, block * CHANNELS]
    sf.render_float!(seg, block)

    write_frames += block
    msec = next_msec
  end

  out_f32
end

def dispatch_message(sf : TinySoundFont::SoundFont, msg)
  ch = sf.channel(msg.channel)
  case TinySoundFont::LibTML::MessageType.new(msg.type)
  when .program_change?
    ch.set_preset_number(param_low(msg).to_i, drums: msg.channel == 9)
  when .note_on?
    velocity = param_high(msg).to_f32 / 127.0_f32
    ch.note_on(param_low(msg).to_i, velocity)
  when .note_off?
    ch.note_off(param_low(msg).to_i)
  when .pitch_bend?
    ch.pitch_wheel = msg.param
  when .control_change?
    ch.midi_control(param_low(msg).to_i, param_high(msg).to_i)
  end
end

def param_low(msg) : UInt8
  (msg.param & 0xFF).to_u8
end

def param_high(msg) : UInt8
  ((msg.param >> 8) & 0xFF).to_u8
end

# Main execution
midi_path = ARGV[0]? || File.expand_path("../ext/TinySoundFont/examples/venture.mid", __DIR__)
sf2_path = ARGV[1]? || File.expand_path("../ext/TinySoundFont/examples/florestan-subset.sf2", __DIR__)
output_path = File.expand_path("example3.wav", __DIR__)

raise "MIDI not found: #{midi_path}" unless File.exists?(midi_path)
raise "SF2 not found: #{sf2_path}" unless File.exists?(sf2_path)

first_msg = LibTML.load_filename(midi_path)
raise "Failed to load MIDI: #{midi_path}" if first_msg.null?

total_ms = calculate_length(first_msg)
total_frames = (total_ms.to_f64 * SAMPLE_RATE / 1000.0).ceil.to_i

TinySoundFont::SoundFont.open(sf2_path, SAMPLE_RATE, TinySoundFont::OutputMode::StereoInterleaved, GAIN_DB) do |sf|
  configure_synth(sf)
  audio_data = render_midi(sf, first_msg, total_frames)
  WAV.write_f32(output_path, SAMPLE_RATE, CHANNELS, audio_data)
  puts "Wrote #{output_path} (#{total_ms} ms, #{SAMPLE_RATE} Hz, stereo)"
end

LibTML.free(first_msg)

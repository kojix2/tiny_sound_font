require "../src/tiny_sound_font"

# Example3: Load a MIDI (via TinyMidiLoader), schedule messages while rendering TinySoundFont,
# write result as WAV offline (no realtime audio backend required).

LibTSF = TinySoundFont::LibTSF
LibTML = TinySoundFont::LibTML

SAMPLE_RATE      =    44_100
CHANNELS         =         2
BLOCK            =        64 # TSF_RENDER_EFFECTSAMPLEBLOCK default
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

def configure_synth(tsf)
  LibTSF.channel_set_bank_preset(tsf, 9, 128, 0) # Percussion on channel 9
  LibTSF.set_output(tsf, TinySoundFont::LibTSF::OutputMode::StereoInterleaved, SAMPLE_RATE, GAIN_DB)
end

def render_midi(tsf, first_msg, total_frames)
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
      dispatch_message(tsf, current.value)
      current = current.value.next
    end

    # Render this block
    seg = out_f32[write_frames * CHANNELS, block * CHANNELS]
    LibTSF.render_float(tsf, seg, block, 0)

    write_frames += block
    msec = next_msec
  end

  out_f32
end

def dispatch_message(tsf, msg)
  case TinySoundFont::LibTML::MessageType.new(msg.type)
  when .program_change?
    LibTSF.channel_set_presetnumber(tsf, msg.channel, param_low(msg), (msg.channel == 9) ? 1 : 0)
  when .note_on?
    velocity = param_high(msg).to_f32 / 127.0_f32
    LibTSF.channel_note_on(tsf, msg.channel, param_low(msg), velocity)
  when .note_off?
    LibTSF.channel_note_off(tsf, msg.channel, param_low(msg))
  when .pitch_bend?
    LibTSF.channel_set_pitchwheel(tsf, msg.channel, msg.param)
  when .control_change?
    LibTSF.channel_midi_control(tsf, msg.channel, param_low(msg), param_high(msg))
  end
end

def param_low(msg) : UInt8
  (msg.param & 0xFF).to_u8
end

def param_high(msg) : UInt8
  ((msg.param >> 8) & 0xFF).to_u8
end

def write_wav(path : String, float_data : Slice(Float32))
  pcm_bytes = float_to_int16(float_data)
  byte_rate = SAMPLE_RATE * CHANNELS * BYTES_PER_SAMPLE
  block_align = CHANNELS * BYTES_PER_SAMPLE
  riff_size = 4 + (8 + 16) + (8 + pcm_bytes.size)

  File.open(path, "wb") do |io|
    io.write "RIFF".to_slice
    io.write_bytes(riff_size.to_u32, IO::ByteFormat::LittleEndian)
    io.write "WAVE".to_slice

    io.write "fmt ".to_slice
    io.write_bytes(16_u32, IO::ByteFormat::LittleEndian)
    io.write_bytes(1_u16, IO::ByteFormat::LittleEndian)
    io.write_bytes(CHANNELS.to_u16, IO::ByteFormat::LittleEndian)
    io.write_bytes(SAMPLE_RATE.to_u32, IO::ByteFormat::LittleEndian)
    io.write_bytes(byte_rate.to_u32, IO::ByteFormat::LittleEndian)
    io.write_bytes(block_align.to_u16, IO::ByteFormat::LittleEndian)
    io.write_bytes((BYTES_PER_SAMPLE * 8).to_u16, IO::ByteFormat::LittleEndian)

    io.write "data".to_slice
    io.write_bytes(pcm_bytes.size.to_u32, IO::ByteFormat::LittleEndian)
    io.write(pcm_bytes)
  end
end

def float_to_int16(float_data : Slice(Float32)) : Bytes
  bytes = Bytes.new(float_data.size * 2)
  int16_data = Slice.new(bytes.to_unsafe.as(Int16*), float_data.size)

  float_data.each_with_index do |sample, i|
    int16_data[i] = (sample.clamp(-1.0_f32, 1.0_f32) * 32_767.0_f32).round.to_i16
  end

  bytes
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

tsf = LibTSF.load_filename(sf2_path)
if tsf.null?
  LibTML.free(first_msg)
  raise "Failed to load SoundFont: #{sf2_path}"
end

begin
  configure_synth(tsf)
  audio_data = render_midi(tsf, first_msg, total_frames)
  write_wav(output_path, audio_data)
  puts "Wrote #{output_path} (#{total_ms} ms, #{SAMPLE_RATE} Hz, stereo)"
ensure
  LibTSF.note_off_all(tsf)
  LibTSF.close(tsf)
  LibTML.free(first_msg)
end

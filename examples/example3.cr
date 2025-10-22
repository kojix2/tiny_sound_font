require "../src/tiny_sound_font"

LibTSF = TinySoundFont::LibTSF
LibTML = TinySoundFont::LibTML

# Example3: Load a MIDI (via TinyMidiLoader), schedule messages while rendering TinySoundFont,
# write result as WAV offline (no realtime audio backend required).

SAMPLE_RATE      =    44_100
CHANNELS         =         2
BLOCK            =        64 # TSF_RENDER_EFFECTSAMPLEBLOCK default
GAIN_DB          = -10.0_f32
BYTES_PER_SAMPLE =         2

def write_wav(path : String, pcm_bytes : Bytes, sample_rate : Int32, channels : Int32)
  byte_rate = sample_rate * channels * BYTES_PER_SAMPLE
  block_align = channels * BYTES_PER_SAMPLE
  data_size = pcm_bytes.size
  riff_size = 4 + (8 + 16) + (8 + data_size)

  File.open(path, "wb") do |io|
    # RIFF
    io.write "RIFF".to_slice
    io.write_bytes(riff_size.to_u32, IO::ByteFormat::LittleEndian)
    io.write "WAVE".to_slice

    # fmt
    io.write "fmt ".to_slice
    io.write_bytes(16_u32, IO::ByteFormat::LittleEndian)
    io.write_bytes(1_u16, IO::ByteFormat::LittleEndian)
    io.write_bytes(channels.to_u16, IO::ByteFormat::LittleEndian)
    io.write_bytes(sample_rate.to_u32, IO::ByteFormat::LittleEndian)
    io.write_bytes(byte_rate.to_u32, IO::ByteFormat::LittleEndian)
    io.write_bytes(block_align.to_u16, IO::ByteFormat::LittleEndian)
    io.write_bytes((BYTES_PER_SAMPLE * 8).to_u16, IO::ByteFormat::LittleEndian)

    # data
    io.write "data".to_slice
    io.write_bytes(data_size.to_u32, IO::ByteFormat::LittleEndian)
    io.write(pcm_bytes)
  end
end

def float_to_int16!(buf_f32 : Slice(Float32), out_i16 : Slice(Int16))
  buf_f32.size.times do |i|
    out_i16[i] = (buf_f32[i].clamp(-1.0_f32, 1.0_f32) * 32_767.0_f32).round.to_i16
  end
end

# Helpers to extract low/high byte from TML param (UInt16)
private def self.b1(param : UInt16) : UInt8
  (param & 0xFF).to_u8
end

private def self.b2(param : UInt16) : UInt8
  ((param >> 8) & 0xFF).to_u8
end

midi_path = ARGV[0]? || File.expand_path("../ext/TinySoundFont/examples/venture.mid", __DIR__)
sf2_path = ARGV[1]? || File.expand_path("../ext/TinySoundFont/examples/florestan-subset.sf2", __DIR__)

raise "MIDI not found: #{midi_path}" unless File.exists?(midi_path)
raise "SF2 not found: #{sf2_path}" unless File.exists?(sf2_path)

# Load MIDI
first_msg = LibTML.load_filename(midi_path)
raise "Failed to load MIDI: #{midi_path}" if first_msg.null?

# Query info to get total length
used_ch = uninitialized Int32
used_pg = uninitialized Int32
total_notes = uninitialized Int32
time_first = uninitialized UInt32
time_len = uninitialized UInt32
LibTML.get_info(first_msg, pointerof(used_ch), pointerof(used_pg), pointerof(total_notes), pointerof(time_first), pointerof(time_len))

# Add tail for releases
tail_ms = 1000_u32
total_ms = time_len + tail_ms
total_frames = (total_ms.to_f64 * SAMPLE_RATE / 1000.0).ceil.to_i

# Load SoundFont
tsf = LibTSF.load_filename(sf2_path)
if tsf.null?
  LibTML.free(first_msg)
  raise "Failed to load SoundFont: #{sf2_path}"
end

begin
  # Percussion bank on channel 9
  LibTSF.channel_set_bank_preset(tsf, 9, 128, 0)
  LibTSF.set_output(tsf, TinySoundFont::LibTSF::OutputMode::StereoInterleaved, SAMPLE_RATE, GAIN_DB)

  # Prepare buffers
  out_f32 = Slice(Float32).new(total_frames * CHANNELS)
  write_frames = 0

  # Iterate in blocks and schedule MIDI
  msec = 0.0
  current = first_msg
  while write_frames < total_frames
    block = Math.min(BLOCK, total_frames - write_frames)
    next_msec = msec + block * (1000.0 / SAMPLE_RATE)

    # Dispatch all MIDI messages up to next_msec
    while !current.null? && msec <= current.value.time.to_f64 && current.value.time.to_f64 <= next_msec
      msg = current.value
      case TinySoundFont::LibTML::MessageType.new(msg.type)
      when .program_change?
        LibTSF.channel_set_presetnumber(tsf, msg.channel, b1(msg.param), (msg.channel == 9) ? 1 : 0)
      when .note_on?
        vel = b2(msg.param).to_f32 / 127.0_f32
        LibTSF.channel_note_on(tsf, msg.channel, b1(msg.param), vel)
      when .note_off?
        LibTSF.channel_note_off(tsf, msg.channel, b1(msg.param))
      when .pitch_bend?
        # pitch bend: 14-bit (combined by loader), already in param
        bend = msg.param
        LibTSF.channel_set_pitchwheel(tsf, msg.channel, bend)
      when .control_change?
        LibTSF.channel_midi_control(tsf, msg.channel, b1(msg.param), b2(msg.param))
      else
        # ignore others
      end
      current = msg.next
    end

    # Render this block
    seg = out_f32[write_frames * CHANNELS, block * CHANNELS]
    LibTSF.render_float(tsf, seg.to_unsafe, block, 0)

    write_frames += block
    msec = next_msec
  end

  # Convert to Int16 and write WAV
  out_bytes = Bytes.new(out_f32.size * 2)
  out_i16 = Slice.new(out_bytes.to_unsafe.as(Int16*), out_bytes.size // 2)
  float_to_int16!(out_f32, out_i16)

  out_path = File.expand_path("example3.wav", __DIR__)
  write_wav(out_path, out_bytes, SAMPLE_RATE, CHANNELS)
  puts "Wrote #{out_path} (#{total_ms} ms, #{SAMPLE_RATE} Hz, stereo)"
ensure
  LibTSF.note_off_all(tsf)
  LibTSF.close(tsf)
  LibTML.free(first_msg)
end

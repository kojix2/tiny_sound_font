require "../src/tiny_sound_font"

LibTSF = TinySoundFont::LibTSF

# Example2: iterate through all presets, play a 1-second note per preset,
# render in float32, convert to Int16, and write a single WAV file.

SAMPLE_RATE        = 44_100
CHANNELS           =      2
SECONDS_PER_PRESET =      1
BYTES_PER_SAMPLE   =      2 # s16

NOTES = [48, 50, 52, 53, 55, 57, 59]

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
    io.write_bytes(16_u32, IO::ByteFormat::LittleEndian) # chunk size
    io.write_bytes(1_u16, IO::ByteFormat::LittleEndian)  # PCM
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

sf2_path = File.expand_path("../ext/TinySoundFont/examples/florestan-subset.sf2", __DIR__)
raise "SF2 not found: #{sf2_path}" unless File.exists?(sf2_path)

tsf = LibTSF.load_filename(sf2_path)
raise "Failed to load SoundFont: #{sf2_path}" if tsf.null?

begin
  LibTSF.set_output(tsf, TinySoundFont::LibTSF::OutputMode::StereoInterleaved, SAMPLE_RATE, 0.0_f32)

  preset_count = LibTSF.get_presetcount(tsf)
  seconds = SECONDS_PER_PRESET * preset_count
  frames_total = SAMPLE_RATE * seconds
  total_samples = frames_total * CHANNELS

  pcm_bytes = Bytes.new(total_samples * BYTES_PER_SAMPLE)
  pcm_i16 = Slice.new(pcm_bytes.to_unsafe.as(Int16*), pcm_bytes.size // 2)

  # temp float32 stereo buffer for 1 second
  frames_per_step = SAMPLE_RATE * SECONDS_PER_PRESET
  f32_tmp = Slice(Float32).new(frames_per_step * CHANNELS)

  write_pos = 0

  notes = NOTES

  (0...preset_count).each do |i|
    note = notes[i % notes.size]

    name_ptr = LibTSF.get_presetname(tsf, i)
    name = name_ptr ? String.new(name_ptr) : "(null)"
    puts "Play note #{note} with preset ##{i} '#{name}'"

    # End previous note and start new one
    if i > 0
      prev_note = notes[(i - 1) % notes.size]
      LibTSF.note_off(tsf, i - 1, prev_note)
    end
    LibTSF.note_on(tsf, i, note, 1.0_f32)

    # Render 1 second into float32 buffer
    LibTSF.render_float(tsf, f32_tmp.to_unsafe, frames_per_step, 0)

    # Convert to int16 and copy into final buffer
    seg_i16 = Slice.new(pcm_i16.to_unsafe + write_pos, frames_per_step * CHANNELS)
    float_to_int16!(f32_tmp, seg_i16)
    write_pos += frames_per_step * CHANNELS
  end

  out_path = File.expand_path("example2.wav", __DIR__)
  write_wav(out_path, pcm_bytes, SAMPLE_RATE, CHANNELS)
  puts "Wrote #{out_path} (#{seconds}s, #{SAMPLE_RATE} Hz, stereo)"
ensure
  LibTSF.note_off_all(tsf)
  LibTSF.close(tsf)
end

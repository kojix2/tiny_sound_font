require "../src/tiny_sound_font"

LibTSF       = TinySoundFont::LibTSF
LittleEndian = IO::ByteFormat::LittleEndian

# Short demo: load a SoundFont, start two notes, render 3 seconds into a WAV file.

SAMPLE_RATE      = 44_100
CHANNELS         =      2
SECONDS          =      3
FRAMES           = SAMPLE_RATE * SECONDS
BYTES_PER_SAMPLE = 2 # s16

# Simple WAV writer for 16-bit PCM stereo
def write_wav(path : String, pcm_bytes : Bytes, sample_rate : Int32, channels : Int32)
  bytes_per_sample = 2
  byte_rate = sample_rate * channels * bytes_per_sample
  block_align = channels * bytes_per_sample
  data_size = pcm_bytes.size
  riff_size = 4 + (8 + 16) + (8 + data_size)

  File.open(path, "wb") do |io|
    # RIFF header
    io.write "RIFF".to_slice
    io.write_bytes(riff_size.to_u32, LittleEndian)
    io.write "WAVE".to_slice

    # fmt chunk
    io.write "fmt ".to_slice
    io.write_bytes(16_u32, LittleEndian) # PCM chunk size
    io.write_bytes(1_u16, LittleEndian)  # PCM format
    io.write_bytes(channels.to_u16, LittleEndian)
    io.write_bytes(sample_rate.to_u32, LittleEndian)
    io.write_bytes(byte_rate.to_u32, LittleEndian)
    io.write_bytes(block_align.to_u16, LittleEndian)
    io.write_bytes((bytes_per_sample * 8).to_u16, LittleEndian)

    # data chunk
    io.write "data".to_slice
    io.write_bytes(data_size.to_u32, LittleEndian)
    io.write(pcm_bytes)
  end
end

# Use the sample SF2 in the repository
sf2_path = File.expand_path("../ext/TinySoundFont/examples/florestan-subset.sf2", __DIR__)
raise "SF2 not found: #{sf2_path}" unless File.exists?(sf2_path)

tsf = LibTSF.load_filename(sf2_path)
raise "Failed to load SoundFont: #{sf2_path}" if tsf.null?

begin
  LibTSF.set_output(tsf, TinySoundFont::LibTSF::OutputMode::StereoInterleaved, SAMPLE_RATE, -10.0_f32)

  # Start two notes (C2=48, E2=52)
  LibTSF.note_on(tsf, 0, 48, 1.0_f32)
  LibTSF.note_on(tsf, 0, 52, 1.0_f32)

  # Render 3 seconds
  samples_total = FRAMES # parameter expects frames (per docs/examples)
  pcm = Bytes.new(samples_total * CHANNELS * BYTES_PER_SAMPLE)
  pcm_i16 = Slice.new(pcm.to_unsafe.as(Int16*), pcm.size // 2)
  LibTSF.render_short(tsf, pcm_i16.to_unsafe, samples_total, 0)

  out_path = File.expand_path("example1.wav", __DIR__)
  write_wav(out_path, pcm, SAMPLE_RATE, CHANNELS)
  puts "Wrote #{out_path} (#{SECONDS}s, #{SAMPLE_RATE} Hz, stereo)"
ensure
  LibTSF.note_off_all(tsf)
  LibTSF.close(tsf)
end

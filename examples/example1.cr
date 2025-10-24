require "../src/tiny_sound_font"

LittleEndian = IO::ByteFormat::LittleEndian

# Short demo using high-level API: render two notes to a WAV file.

SAMPLE_RATE = 44_100
CHANNELS    =      2
SECONDS     =      3
FRAMES      = SAMPLE_RATE * SECONDS

# Simple WAV writer for 16-bit PCM stereo
def write_wav(path : String, pcm_i16 : Slice(Int16), sample_rate : Int32, channels : Int32)
  bytes_per_sample = 2
  byte_rate = sample_rate * channels * bytes_per_sample
  block_align = channels * bytes_per_sample
  data_size = pcm_i16.size * bytes_per_sample
  riff_size = 4 + (8 + 16) + (8 + data_size)

  File.open(path, "wb") do |io|
    # RIFF header
    io.write "RIFF".to_slice
    io.write_bytes(riff_size.to_u32, LittleEndian)
    io.write "WAVE".to_slice

    # fmt chunk
    io.write "fmt ".to_slice
    io.write_bytes(16_u32, LittleEndian)
    io.write_bytes(1_u16, LittleEndian)
    io.write_bytes(channels.to_u16, LittleEndian)
    io.write_bytes(sample_rate.to_u32, LittleEndian)
    io.write_bytes(byte_rate.to_u32, LittleEndian)
    io.write_bytes(block_align.to_u16, LittleEndian)
    io.write_bytes((bytes_per_sample * 8).to_u16, LittleEndian)

    # data chunk
    io.write "data".to_slice
    io.write_bytes(data_size.to_u32, LittleEndian)
    raw = Slice.new(pcm_i16.to_unsafe.as(UInt8*), data_size)
    io.write(raw)
  end
end

# Use the sample SF2 in the repository
sf2_path = File.expand_path("../ext/TinySoundFont/examples/florestan-subset.sf2", __DIR__)
raise "SF2 not found: #{sf2_path}" unless File.exists?(sf2_path)

TinySoundFont::SoundFont.open(sf2_path, SAMPLE_RATE, TinySoundFont::OutputMode::StereoInterleaved, -10.0_f32) do |sf|
  # Start two notes (C2=48, E2=52)
  sf.note_on(0, 48, 1.0_f32)
  sf.note_on(0, 52, 1.0_f32)

  # Render 3 seconds
  pcm_i16 = sf.render_short(FRAMES)

  out_path = File.expand_path("example1.wav", __DIR__)
  write_wav(out_path, pcm_i16, SAMPLE_RATE, CHANNELS)
  puts "Wrote #{out_path} (#{SECONDS}s, #{SAMPLE_RATE} Hz, stereo)"
end

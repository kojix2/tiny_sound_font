require "../src/tiny_sound_font"
require "./wav"

SAMPLE_RATE = 44_100
CHANNELS    =      2
SECONDS     =      3
FRAMES      = SAMPLE_RATE * SECONDS

# Use the sample SF2 in the repository
sf2_path = File.expand_path("../ext/florestan-subset.sf2", __DIR__)
raise "SF2 not found: #{sf2_path}" unless File.exists?(sf2_path)

TinySoundFont::SoundFont.open(sf2_path, SAMPLE_RATE, TinySoundFont::OutputMode::StereoInterleaved, -10.0_f32) do |sf|
  # Start two notes (C2=48, E2=52)
  sf.note_on(0, 48, 1.0_f32)
  sf.note_on(0, 52, 1.0_f32)

  # Render 3 seconds
  pcm_i16 = sf.render_short(FRAMES)

  out_path = File.expand_path("example1.wav", __DIR__)
  WAV.write_i16(out_path, SAMPLE_RATE, CHANNELS, pcm_i16)
  puts "Wrote #{out_path} (#{SECONDS}s, #{SAMPLE_RATE} Hz, stereo)"
end

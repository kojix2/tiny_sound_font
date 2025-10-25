require "../src/tiny_sound_font"
require "./wav"

LittleEndian = IO::ByteFormat::LittleEndian

# Example2 using high-level API: iterate presets and render 1s per preset.

SAMPLE_RATE        = 44_100
CHANNELS           =      2
SECONDS_PER_PRESET =      1
BYTES_PER_SAMPLE   =      2

NOTES = [48, 50, 52, 53, 55, 57, 59]

def float_to_int16!(buf_f32 : Slice(Float32), out_i16 : Slice(Int16))
  buf_f32.size.times do |i|
    out_i16[i] = (buf_f32[i].clamp(-1.0_f32, 1.0_f32) * 32_767.0_f32).round.to_i16
  end
end

sf2_path = File.expand_path("../ext/florestan-subset.sf2", __DIR__)
raise "SF2 not found: #{sf2_path}" unless File.exists?(sf2_path)

TinySoundFont::SoundFont.open(sf2_path, SAMPLE_RATE, TinySoundFont::OutputMode::StereoInterleaved, 0.0_f32) do |sf|
  preset_count = sf.preset_count
  seconds = SECONDS_PER_PRESET * preset_count
  frames_total = SAMPLE_RATE * seconds
  total_samples = frames_total * CHANNELS

  pcm_bytes = Bytes.new(total_samples * BYTES_PER_SAMPLE)
  pcm_i16 = Slice.new(pcm_bytes.to_unsafe.as(Int16*), pcm_bytes.size // 2)

  frames_per_step = SAMPLE_RATE * SECONDS_PER_PRESET
  f32_tmp = Slice(Float32).new(frames_per_step * CHANNELS)

  write_pos = 0
  notes = NOTES

  (0...preset_count).each do |i|
    note = notes[i % notes.size]

    name = sf.preset_name(i)
    puts "Play note #{note} with preset ##{i} '#{name}'"

    if i > 0
      prev_note = notes[(i - 1) % notes.size]
      sf.note_off(i - 1, prev_note)
    end
    sf.note_on(i, note, 1.0_f32)

    sf.render_float!(f32_tmp, frames_per_step)

    seg_i16 = Slice.new(pcm_i16.to_unsafe + write_pos, frames_per_step * CHANNELS)
    float_to_int16!(f32_tmp, seg_i16)
    write_pos += frames_per_step * CHANNELS
  end

  out_path = File.expand_path("example2.wav", __DIR__)
  WAV.write_i16(out_path, SAMPLE_RATE, CHANNELS, pcm_i16)
  puts "Wrote #{out_path} (#{seconds}s, #{SAMPLE_RATE} Hz, stereo)"
end

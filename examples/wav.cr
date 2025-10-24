# Minimal WAV writer for examples.
module WAV
  extend self

  BYTE_ORDER = IO::ByteFormat::LittleEndian

  def write_i16(path : String, sample_rate : Int32, channels : Int32, data_i16 : Slice(Int16))
    bytes_per_sample = 2
    data_size = data_i16.size * bytes_per_sample
    byte_rate = sample_rate * channels * bytes_per_sample
    block_align = channels * bytes_per_sample
    riff_size = 4 + (8 + 16) + (8 + data_size)

    File.open(path, "wb") do |io|
      io.write "RIFF".to_slice
      io.write_bytes riff_size.to_u32, BYTE_ORDER
      io.write "WAVE".to_slice

      io.write "fmt ".to_slice
      io.write_bytes 16_u32, BYTE_ORDER # PCM fmt chunk size
      io.write_bytes 1_u16, BYTE_ORDER  # PCM format
      io.write_bytes channels.to_u16, BYTE_ORDER
      io.write_bytes sample_rate.to_u32, BYTE_ORDER
      io.write_bytes byte_rate.to_u32, BYTE_ORDER
      io.write_bytes block_align.to_u16, BYTE_ORDER
      io.write_bytes (bytes_per_sample * 8).to_u16, BYTE_ORDER

      io.write "data".to_slice
      io.write_bytes data_size.to_u32, BYTE_ORDER
      raw = Slice.new(data_i16.to_unsafe.as(UInt8*), data_size)
      io.write raw
    end
  end

  def write_f32(path : String, sample_rate : Int32, channels : Int32, data_f32 : Slice(Float32))
    tmp = Slice(Int16).new(data_f32.size)
    data_f32.each_with_index do |v, i|
      tmp[i] = (v.clamp(-1.0_f32, 1.0_f32) * 32_767.0_f32).round.to_i16
    end
    write_i16(path, sample_rate, channels, tmp)
  end
end

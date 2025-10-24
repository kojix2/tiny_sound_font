require "./lib_tsf"

module TinySoundFont
  # High-level wrapper around LibTSF::TSF
  # Note: Thread safety depends on the underlying C library.
  class SoundFont
    getter sample_rate : Int32
    getter handle : LibTSF::TSF
    @output_mode : LibTSF::OutputMode

    def initialize(filename : String, @sample_rate : Int32 = 44100,
                   output_mode : LibTSF::OutputMode = LibTSF::OutputMode::StereoInterleaved,
                   gain_db : Float32 = 0.0_f32)
      @handle = LibTSF.load_filename(filename)
      raise "Failed to load SoundFont: #{filename} (file may not exist or be invalid)" if @handle.null?
      @output_mode = output_mode
      LibTSF.set_output(@handle, @output_mode, @sample_rate, gain_db)
    end

    # Load from memory buffer
    def self.from_memory(data : Bytes, sample_rate : Int32 = 44100,
                         output_mode : LibTSF::OutputMode = LibTSF::OutputMode::StereoInterleaved,
                         gain_db : Float32 = 0.0_f32) : self
      handle = LibTSF.load_memory(data.to_unsafe, data.size)
      raise "Failed to load SoundFont from memory (buffer invalid or unsupported)" if handle.null?
      new_from_handle(handle, sample_rate, output_mode, gain_db)
    end

    private def self.new_from_handle(handle : LibTSF::TSF, sample_rate : Int32,
                                     output_mode : LibTSF::OutputMode, gain_db : Float32) : self
      instance = allocate
      instance.initialize_from_handle(handle, sample_rate, output_mode, gain_db)
      instance
    end

    # RAII helper that ensures close is called
    def self.open(filename : String, sample_rate : Int32 = 44100,
                  output_mode : LibTSF::OutputMode = LibTSF::OutputMode::StereoInterleaved,
                  gain_db : Float32 = 0.0_f32, &)
      sf = new(filename, sample_rate, output_mode, gain_db)
      begin
        yield sf
      ensure
        sf.close
      end
    end

    # Rescue-only finalizer to avoid leaking native handle
    def finalize
      # Rescue-only: ensure native handle is released if user forgot to call close
      close
    end

    def closed? : Bool
      @handle.null?
    end

    def close
      return if closed?
      LibTSF.close(@handle)
      @handle = Pointer(Void).null
    end

    # Configure output again if needed
    def set_output(mode : LibTSF::OutputMode, sample_rate : Int32 = @sample_rate, gain_db : Float32 = 0.0_f32)
      raise "SoundFont is closed" if closed?
      @sample_rate = sample_rate
      @output_mode = mode
      LibTSF.set_output(@handle, @output_mode, @sample_rate, gain_db)
    end

    # Global controls
    def reset
      raise "SoundFont is closed" if closed?
      LibTSF.reset(@handle)
    end

    def volume=(v : Float32)
      raise "SoundFont is closed" if closed?
      LibTSF.set_volume(@handle, v)
    end

    def max_voices=(n : Int32)
      raise "SoundFont is closed" if closed?
      LibTSF.set_max_voices(@handle, n)
    end

    def active_voices : Int32
      return 0 if closed?
      LibTSF.active_voice_count(@handle)
    end

    # Presets
    def preset_count : Int32
      raise "SoundFont is closed" if closed?
      LibTSF.get_presetcount(@handle)
    end

    def preset_name(index : Int32) : String
      raise "SoundFont is closed" if closed?
      ptr = LibTSF.get_presetname(@handle, index)
      ptr ? String.new(ptr) : ""
    end

    def preset_index(bank : Int32, program : Int32) : Int32
      raise "SoundFont is closed" if closed?
      LibTSF.get_presetindex(@handle, bank, program)
    end

    # Notes using preset index
    def note_on(preset_index : Int32, key : Int32, velocity : Float32 = 1.0_f32) : Int32
      raise "SoundFont is closed" if closed?
      LibTSF.note_on(@handle, preset_index, key, velocity)
    end

    def note_off(preset_index : Int32, key : Int32)
      return if closed?
      LibTSF.note_off(@handle, preset_index, key)
    end

    def note_off_all
      return if closed?
      LibTSF.note_off_all(@handle)
    end

    # Notes using bank/program
    def bank_note_on(bank : Int32, program : Int32, key : Int32, velocity : Float32 = 1.0_f32) : Int32
      raise "SoundFont is closed" if closed?
      LibTSF.bank_note_on(@handle, bank, program, key, velocity)
    end

    def bank_note_off(bank : Int32, program : Int32, key : Int32) : Int32
      return 0 if closed?
      LibTSF.bank_note_off(@handle, bank, program, key)
    end

    # Rendering API
    # samples is the number of frames per channel
    def render_short!(buffer : Slice(Int16), samples : Int32, mixing : Bool = false)
      raise "SoundFont is closed" if closed?
      LibTSF.render_short(@handle, buffer.to_unsafe, samples, mixing ? 1 : 0)
    end

    def render_float!(buffer : Slice(Float32), samples : Int32, mixing : Bool = false)
      raise "SoundFont is closed" if closed?
      LibTSF.render_float(@handle, buffer.to_unsafe, samples, mixing ? 1 : 0)
    end

    def render_short(samples : Int32, mixing : Bool = false) : Slice(Int16)
      ch = channels_for_mode
      buf = Slice(Int16).new(samples * ch)
      render_short!(buf, samples, mixing)
      buf
    end

    def render_float(samples : Int32, mixing : Bool = false) : Slice(Float32)
      ch = channels_for_mode
      buf = Slice(Float32).new(samples * ch)
      render_float!(buf, samples, mixing)
      buf
    end

    # Channel access
    def channel(index : Int32) : Channel
      raise "SoundFont is closed" if closed?
      Channel.new(@handle, index)
    end

    protected def initialize_from_handle(handle : LibTSF::TSF, sample_rate : Int32,
                                         output_mode : LibTSF::OutputMode, gain_db : Float32)
      @handle = handle
      @sample_rate = sample_rate
      @output_mode = output_mode
      LibTSF.set_output(@handle, @output_mode, @sample_rate, gain_db)
    end

    private def channels_for_mode : Int32
      case @output_mode
      when LibTSF::OutputMode::StereoInterleaved, LibTSF::OutputMode::StereoUnweaved
        2
      when LibTSF::OutputMode::Mono
        1
      else
        2
      end
    end
  end

  # Optional alias for convenience
  alias OutputMode = LibTSF::OutputMode
end

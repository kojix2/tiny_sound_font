module TinySoundFont
  @[Link(ldflags: "-L#{__DIR__}/../../ext -ltsf -lm")]
  lib LibTSF
    # Opaque C handle to `struct tsf`
    alias TSF = Void*

    # Mirror of C enum TSFOutputMode
    enum OutputMode : Int32
      StereoInterleaved = 0
      StereoUnweaved    = 1
      Mono              = 2
    end

    # C struct tsf_stream for custom loading (optional to use)
    struct Stream
      data : Void*
      read : (Void*, Void*, UInt32 -> Int32)
      skip : (Void*, UInt32 -> Int32)
    end

    # Loading and lifecycle
    fun load_filename = tsf_load_filename(filename : LibC::Char*) : TSF
    fun load_memory = tsf_load_memory(buffer : Void*, size : Int32) : TSF
    fun load = tsf_load(stream : Stream*) : TSF
    fun copy = tsf_copy(f : TSF) : TSF
    fun close = tsf_close(f : TSF) : Void
    fun reset = tsf_reset(f : TSF) : Void

    # Presets
    fun get_presetindex = tsf_get_presetindex(f : TSF, bank : Int32, preset_number : Int32) : Int32
    fun get_presetcount = tsf_get_presetcount(f : TSF) : Int32
    fun get_presetname = tsf_get_presetname(f : TSF, preset_index : Int32) : LibC::Char*
    fun bank_get_presetname = tsf_bank_get_presetname(f : TSF, bank : Int32, preset_number : Int32) : LibC::Char*

    # Output configuration
    fun set_output = tsf_set_output(f : TSF, outputmode : OutputMode, samplerate : Int32, global_gain_db : LibC::Float) : Void
    fun set_volume = tsf_set_volume(f : TSF, global_gain : LibC::Float) : Void
    fun set_max_voices = tsf_set_max_voices(f : TSF, max_voices : Int32) : Int32

    # Note on/off
    fun note_on = tsf_note_on(f : TSF, preset_index : Int32, key : Int32, vel : LibC::Float) : Int32
    fun bank_note_on = tsf_bank_note_on(f : TSF, bank : Int32, preset_number : Int32, key : Int32, vel : LibC::Float) : Int32
    fun note_off = tsf_note_off(f : TSF, preset_index : Int32, key : Int32) : Void
    fun bank_note_off = tsf_bank_note_off(f : TSF, bank : Int32, preset_number : Int32, key : Int32) : Int32
    fun note_off_all = tsf_note_off_all(f : TSF) : Void
    fun active_voice_count = tsf_active_voice_count(f : TSF) : Int32

    # Rendering
    fun render_short = tsf_render_short(f : TSF, buffer : LibC::Short*, samples : Int32, flag_mixing : Int32) : Void
    fun render_float = tsf_render_float(f : TSF, buffer : LibC::Float*, samples : Int32, flag_mixing : Int32) : Void

    # Channel configuration
    fun channel_set_presetindex = tsf_channel_set_presetindex(f : TSF, channel : Int32, preset_index : Int32) : Int32
    fun channel_set_presetnumber = tsf_channel_set_presetnumber(f : TSF, channel : Int32, preset_number : Int32, flag_mididrums : Int32) : Int32
    fun channel_set_bank = tsf_channel_set_bank(f : TSF, channel : Int32, bank : Int32) : Int32
    fun channel_set_bank_preset = tsf_channel_set_bank_preset(f : TSF, channel : Int32, bank : Int32, preset_number : Int32) : Int32
    fun channel_set_pan = tsf_channel_set_pan(f : TSF, channel : Int32, pan : LibC::Float) : Int32
    fun channel_set_volume = tsf_channel_set_volume(f : TSF, channel : Int32, volume : LibC::Float) : Int32
    fun channel_set_pitchwheel = tsf_channel_set_pitchwheel(f : TSF, channel : Int32, pitch_wheel : Int32) : Int32
    fun channel_set_pitchrange = tsf_channel_set_pitchrange(f : TSF, channel : Int32, pitch_range : LibC::Float) : Int32
    fun channel_set_tuning = tsf_channel_set_tuning(f : TSF, channel : Int32, tuning : LibC::Float) : Int32
    fun channel_set_sustain = tsf_channel_set_sustain(f : TSF, channel : Int32, flag_sustain : Int32) : Int32

    # Channel notes
    fun channel_note_on = tsf_channel_note_on(f : TSF, channel : Int32, key : Int32, vel : LibC::Float) : Int32
    fun channel_note_off = tsf_channel_note_off(f : TSF, channel : Int32, key : Int32) : Void
    fun channel_note_off_all = tsf_channel_note_off_all(f : TSF, channel : Int32) : Void
    fun channel_sounds_off_all = tsf_channel_sounds_off_all(f : TSF, channel : Int32) : Void

    # MIDI controls
    fun channel_midi_control = tsf_channel_midi_control(f : TSF, channel : Int32, controller : Int32, control_value : Int32) : Int32

    # Channel getters
    fun channel_get_preset_index = tsf_channel_get_preset_index(f : TSF, channel : Int32) : Int32
    fun channel_get_preset_bank = tsf_channel_get_preset_bank(f : TSF, channel : Int32) : Int32
    fun channel_get_preset_number = tsf_channel_get_preset_number(f : TSF, channel : Int32) : Int32
    fun channel_get_pan = tsf_channel_get_pan(f : TSF, channel : Int32) : LibC::Float
    fun channel_get_volume = tsf_channel_get_volume(f : TSF, channel : Int32) : LibC::Float
    fun channel_get_pitchwheel = tsf_channel_get_pitchwheel(f : TSF, channel : Int32) : Int32
    fun channel_get_pitchrange = tsf_channel_get_pitchrange(f : TSF, channel : Int32) : LibC::Float
    fun channel_get_tuning = tsf_channel_get_tuning(f : TSF, channel : Int32) : LibC::Float
  end
end

require "./lib_tsf"

module TinySoundFont
  class Channel
    def initialize(@handle : LibTSF::TSF, @index : Int32)
      raise ArgumentError.new("Channel index must be >= 0, got #{@index}") if @index < 0
    end

    # Setters
    def preset_index=(idx : Int32)
      LibTSF.channel_set_presetindex(@handle, @index, idx)
    end

    # Setter version (melodic by default)
    def preset_number=(program : Int32)
      LibTSF.channel_set_presetnumber(@handle, @index, program, 0)
    end

    # Full control with drums flag
    def set_preset_number(program : Int32, drums : Bool = false)
      LibTSF.channel_set_presetnumber(@handle, @index, program, drums ? 1 : 0)
    end

    def bank=(bank : Int32)
      LibTSF.channel_set_bank(@handle, @index, bank)
    end

    def bank_preset=(tuple : {Int32, Int32})
      bank, program = tuple
      LibTSF.channel_set_bank_preset(@handle, @index, bank, program)
    end

    # Explicit method name variant for readability
    def set_bank_and_preset(bank : Int32, program : Int32)
      LibTSF.channel_set_bank_preset(@handle, @index, bank, program)
    end

    def pan=(v : Float32)
      LibTSF.channel_set_pan(@handle, @index, v)
    end

    def volume=(v : Float32)
      LibTSF.channel_set_volume(@handle, @index, v)
    end

    def pitch_wheel=(v : Int32)
      LibTSF.channel_set_pitchwheel(@handle, @index, v)
    end

    def pitch_range=(v : Float32)
      LibTSF.channel_set_pitchrange(@handle, @index, v)
    end

    def tuning=(v : Float32)
      LibTSF.channel_set_tuning(@handle, @index, v)
    end

    def sustain=(on : Bool)
      LibTSF.channel_set_sustain(@handle, @index, on ? 1 : 0)
    end

    # Notes
    def note_on(key : Int32, velocity : Float32 = 1.0_f32)
      LibTSF.channel_note_on(@handle, @index, key, velocity)
    end

    def note_off(key : Int32)
      LibTSF.channel_note_off(@handle, @index, key)
    end

    def note_off_all
      LibTSF.channel_note_off_all(@handle, @index)
    end

    def sounds_off_all
      LibTSF.channel_sounds_off_all(@handle, @index)
    end

    # MIDI control (CC)
    def midi_control(controller : Int32, value : Int32)
      LibTSF.channel_midi_control(@handle, @index, controller, value)
    end

    # Getters
    def preset_index : Int32
      LibTSF.channel_get_preset_index(@handle, @index)
    end

    def preset_bank : Int32
      LibTSF.channel_get_preset_bank(@handle, @index)
    end

    def preset_number : Int32
      LibTSF.channel_get_preset_number(@handle, @index)
    end

    def pan : Float32
      LibTSF.channel_get_pan(@handle, @index)
    end

    def volume : Float32
      LibTSF.channel_get_volume(@handle, @index)
    end

    def pitch_wheel : Int32
      LibTSF.channel_get_pitchwheel(@handle, @index)
    end

    def pitch_range : Float32
      LibTSF.channel_get_pitchrange(@handle, @index)
    end

    def tuning : Float32
      LibTSF.channel_get_tuning(@handle, @index)
    end
  end
end

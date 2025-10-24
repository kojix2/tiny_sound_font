require "./lib_tml"

module TinySoundFont
  {% if flag?(:msvc) %}
    @[Link("tml", ldflags: "/LIBPATH:#{__DIR__}\\..\\..\\ext")]
  {% else %}
    @[Link("tml", ldflags: "-L#{__DIR__}/../../ext")]
  {% end %}
  lib LibTML
    enum MessageType : UInt8
      NoteOff         = 0x80
      NoteOn          = 0x90
      KeyPressure     = 0xA0
      ControlChange   = 0xB0
      ProgramChange   = 0xC0
      ChannelPressure = 0xD0
      PitchBend       = 0xE0
      SetTempo        = 0x51
    end

    # MIDI controller numbers (complete; values mirror TinyMidiLoader's tml.h)
    enum Controller : UInt32
      # MSB controllers (0-31, with some gaps by spec)
      BankSelectMSB      =  0
      ModulationWheelMSB =  1
      BreathMSB          =  2
      FootMSB            =  4
      PortamentoTimeMSB  =  5
      DataEntryMSB       =  6
      VolumeMSB          =  7
      BalanceMSB         =  8
      PanMSB             = 10
      ExpressionMSB      = 11
      Effects1MSB        = 12
      Effects2MSB        = 13
      GPC1MSB            = 16
      GPC2MSB            = 17
      GPC3MSB            = 18
      GPC4MSB            = 19

      # LSB controllers (32-63, with some gaps by spec)
      BankSelectLSB      = 32
      ModulationWheelLSB = 33
      BreathLSB          = 34
      FootLSB            = 36
      PortamentoTimeLSB  = 37
      DataEntryLSB       = 38
      VolumeLSB          = 39
      BalanceLSB         = 40
      PanLSB             = 42
      ExpressionLSB      = 43
      Effects1LSB        = 44
      Effects2LSB        = 45
      GPC1LSB            = 48
      GPC2LSB            = 49
      GPC3LSB            = 50
      GPC4LSB            = 51

      # Switches and sound controls (64-95)
      SustainSwitch     = 64
      PortamentoSwitch  = 65
      SostenutoSwitch   = 66
      SoftPedalSwitch   = 67
      LegatoSwitch      = 68
      Hold2Switch       = 69
      SoundControl1     = 70
      SoundControl2     = 71
      SoundControl3     = 72
      SoundControl4     = 73
      SoundControl5     = 74
      SoundControl6     = 75
      SoundControl7     = 76
      SoundControl8     = 77
      SoundControl9     = 78
      SoundControl10    = 79
      GPC5              = 80
      GPC6              = 81
      GPC7              = 82
      GPC8              = 83
      PortamentoControl = 84
      FxReverb          = 91
      FxTremolo         = 92
      FxChorus          = 93
      FxCelesteDetune   = 94
      FxPhaser          = 95

      # Data entry and parameter number (96-101)
      DataEntryIncrement =  96
      DataEntryDecrement =  97
      NRPNLSB            =  98
      NRPNMSB            =  99
      RPNLSB             = 100
      RPNMSB             = 101

      # Channel mode messages (120-127)
      AllSoundOff  = 120
      AllCtrlOff   = 121
      LocalControl = 122
      AllNotesOff  = 123
      OmniOff      = 124
      OmniOn       = 125
      PolyOff      = 126
      PolyOn       = 127
    end

    # C struct tml_message (param packs key/velocity, control/value, program/channel_pressure, or 14-bit pitch_bend)
    struct Message
      time : UInt32
      type : UInt8
      channel : UInt8
      param : UInt16 # two bytes: [low=b1, high=b2]; or 14-bit pitch bend
      next : Message*
    end

    fun load_filename = tml_load_filename(filename : LibC::Char*) : Message*
    fun load_memory = tml_load_memory(buffer : Void*, size : Int32) : Message*

    struct TMLStream
      data : Void*
      read : (Void*, Void*, UInt32 -> Int32)
    end

    fun load = tml_load(stream : TMLStream*) : Message*
    fun load_tsf_stream = tml_load_tsf_stream(stream : LibTSF::Stream*) : Message*
    fun free = tml_free(first : Message*) : Void
    fun get_info = tml_get_info(first : Message*, used_channels : Int32*, used_programs : Int32*, total_notes : Int32*, time_first_note : UInt32*, time_length : UInt32*) : Int32
    fun get_tempo_value = tml_get_tempo_value(set_tempo_message : Message*) : Int32
  end
end

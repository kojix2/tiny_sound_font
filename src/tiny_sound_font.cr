require "./tiny_sound_font/lib_tsf"
require "./tiny_sound_font/lib_tml"
require "./tiny_sound_font/channel"
require "./tiny_sound_font/sound_font"

module TinySoundFont
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}
end

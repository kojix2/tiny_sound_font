require "./tiny_sound_font/lib_tsf"
require "./tiny_sound_font/lib_tml"

module TinySoundFont
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}
end

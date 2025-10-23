# tiny_sound_font

[![test](https://github.com/kojix2/tiny_sound_font/actions/workflows/ci.yml/badge.svg)](https://github.com/kojix2/tiny_sound_font/actions/workflows/ci.yml)
[![Lines of Code](https://img.shields.io/endpoint?url=https%3A%2F%2Ftokei.kojix2.net%2Fbadge%2Fgithub%2Fkojix2%2Ftiny_sound_font%2Flines)](https://tokei.kojix2.net/github/kojix2/tiny_sound_font)

[TinySoundFont](https://github.com/schellingb/TinySoundFont) - software synthesizer - for Crystal

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     tiny_sound_font:
       github: kojix2/tiny_sound_font
   ```

2. Run `shards install`

## Usage

```crystal
require "tiny_sound_font"
```

## Development

```sh
git clone --recursive https://github.com/kojix2/tiny_sound_font
make -C ext
crystal spec
```

## Contributing

1. Fork it (<https://github.com/your-github-user/tiny_sound_font/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

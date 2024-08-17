# AmstradGpt

Get your Amstrad CPC to talk to ChatGPT via a USB to RS232 serial cable.

# Getting started
- Invent the universe
- Open a time portal to 1985. 👾
- Alternatively, buy an Amstrad CPC on ebay. 🖥️
- Connect USB to serial port somehow (this is possible the hardest bit) see [Serial port communication](#serial-port-communication)
- `gem install amstrad_gpt`
- Plug your Amstrad into your Mac with your cable.
- Find the tty id

```
ls /dev/tty.*
```

```
amstrad_gpt run --tty /dev/tty.<your_tty> --api-key <open_ai_api_key>
```

in your Amstrad at the ready prompt
```
Amstrad 64K Microcomputer <v1>
©1984 Amstrad Consumer Electronics plc
          and Locomotive Software Ltd.
BASIC 1.0
Ready
```

type in the bootstrap program from this repo. `/basic/BOOTSTRP.BAS` then type 

```
run
```

This will allow us to send the full AmstradGPT program to your Amstrad over the serial port.
It will then prompt you to save to disk.

Alternatively you can type in the full `/basic/AMSTRGPT.BAS` program and skip that step.

# Help?
If you want any help and meet these criteria:
- you have a serial port connection
- you have it connected to your linux/mac/windows machine
- you can demonstrate communication between your device and the Amstrad (not AmstradGPT but any other connection)
- you are willing to setup an OpenAI account and create an API token (for your personal use)
- you are still struggling to get AmstradGPT working

I would be more than happy to help you debug any software issues you're experiencing and fix them.
We could arrange a video call or whatever works for you. 

I don't think I'd be as useful in debugging any hardware or serial port issues themselves, and I'd advice you to go to the CPC wiki then read and ask around.
https://www.cpcwiki.eu/
https://www.cpcwiki.eu/forum/

# Architecture

[Diagram](https://github.com/markburns/amstrad_gpt/blob/main/ARCHITECTURE.md)

Components

- Mac physical machine
- Amstrad physical machine
- OpenAI API 3rd party API
- `socat` software to run on your Mac to create a virtual socket
- Classes
  - `Gateway` - coordinates sending and receiving messages between the Amstrad/ChatGPT/AmstradClientSimulator
  - `Amstrad` - abstracts commonicating with the physical machine
  - `AmstradClientSimulator` - quacks like an `Amstrad` sending messages down a serial port, accessed through the web api
  - `ChatGpt` - abstracts communicating with the ChatGPT API
  - `Interface` - wraps the socket library
  - `Serial` - the socket library from the `rubyserial` gem
- Web server endpoints
  - `GET /messages` inspect interactions
  - `POST /simulate_amstrad_to_gpt_message` Triggers the AmstradClientSimulator via a socket set up in socat
  - `POST /send_message` Short circuits straight to the gateway sending a message to ChatGPT

# Serial port communication
This is possibly the most challenging part of the project. Your mileage may vary depending on your aptitude for electronics and/or ability to source ancient hardware.
I was lucky enough to have the creator of this https://github.com/rabs664/Amstrad-CPC-CTC-DART send me one. This is a personal project for him though, rather than a commercial venture so I make no guarantees for anyone trying to follow the same path I did.

There are other options, but some of them are defunct projects. I think the best solution if you are embarking on this path would be to create an account on the CPC wiki forum and read around and/or ask for advice.

This basically allows me to plug the hardware into the Amstrad and have a USB cable going into my Mac.

You could also attempt to obtain an horrifically expensive original RS232 expansion kit 😱
![image](https://github.com/user-attachments/assets/9386a91c-777a-4914-aadb-6686be6c3ced)

- Get a USB to RS232 cable. e.g. https://www.amazon.co.uk/dp/B00QUZY4UG?psc=1&ref=ppx_yo2ov_dt_b_product_details

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/markburns/amstrad_gpt.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).



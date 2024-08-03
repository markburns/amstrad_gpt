# AmstradGpt

Get your Amstrad CPC to talk to ChatGPT via a USB to RS232 serial cable.

# Getting started
- Invent the universe
- Open a time portal to 1985.
- Alternatively, buy an Amstrad CPC on ebay.
- Get a USB to RS232 cable. e.g. https://www.amazon.co.uk/dp/B00QUZY4UG?psc=1&ref=ppx_yo2ov_dt_b_product_details
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

type in
```
10 MODE 1
15 PRINT "Enter your question then press [Enter] three times"
20 OPENIN "#2"
30 WHILE NOT EOF(2)
40   A$ = INPUT$(1,#2)
50   PRINT A$;
60 WEND
70 CLOSEIN #2

RUN
```


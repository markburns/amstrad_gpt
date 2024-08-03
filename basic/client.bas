10 MODE 1                 ' Set screen mode to mode 1 (medium resolution)
20 OPENIN "#2"            ' Open the serial port for input
30 WHILE NOT EOF(2)       ' Loop until there is no more data
40   A$ = INPUT$(1,#2)    ' Read 1 character from the serial port
50   PRINT A$;            ' Display the character on the screen
60 WEND
70 CLOSEIN #2             ' Close the serial port

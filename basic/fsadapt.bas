10 REM Amstrad to ChatGPT File-Based Communication System
20 REM File names
30 AMSTRAD.TO.GPT$ = "AMSGPT.TXT"
40 GPT.TO.AMSTRAD$ = "GPTAMS.TXT"
50 STATUS.FILE$ = "STATUS.TXT"
60 REM Status codes
70 READY$ = "READY"
80 SENDING$ = "SENDING"
90 RECEIVED$ = "RECEIVED"
100 ERROR$ = "ERROR"

200 REM Main loop
210 WHILE 1
220   GOSUB 1000 : REM Check for incoming messages
230   GOSUB 2000 : REM Send outgoing messages
240   GOSUB 3000 : REM Check and update status
250   REM Add a small delay to prevent excessive CPU usage
260   FOR i = 1 TO 1000: NEXT i
270 WEND

1000 REM Check for incoming messages
1010 IF NOT OPENIN(GPT.TO.AMSTRAD$) THEN RETURN
1020 INPUT #9, message$
1030 CLOSEIN
1040 IF message$ <> "" THEN
1050   PRINT "Assistant: "; message$
1060   GOSUB 4000 : REM Acknowledge receipt
1070 ENDIF
1080 RETURN

2000 REM Send outgoing messages
2010 PRINT "Enter message to send (or press ENTER to skip): ";
2020 INPUT user.input$
2030 IF user.input$ = "" THEN RETURN
2040 OPENOUT AMSTRAD.TO.GPT$
2050 PRINT #9, user.input$
2060 CLOSEOUT
2070 GOSUB 5000 : REM Update status to SENDING
2080 RETURN

3000 REM Check and update status
3010 IF NOT OPENIN(STATUS.FILE$) THEN RETURN
3020 INPUT #9, status$
3030 CLOSEIN
3040 IF status$ = RECEIVED$ THEN
3050   PRINT "Message received by GPT"
3060   GOSUB 6000 : REM Clear sent message
3070 ELSEIF status$ = ERROR$ THEN
3080   PRINT "Error in communication. Please try again."
3090 ENDIF
3100 RETURN

4000 REM Acknowledge receipt
4010 OPENOUT GPT.TO.AMSTRAD$
4020 PRINT #9, ""
4030 CLOSEOUT
4040 RETURN

5000 REM Update status to SENDING
5010 OPENOUT STATUS.FILE$
5020 PRINT #9, SENDING$
5030 CLOSEOUT
5040 RETURN

6000 REM Clear sent message
6010 OPENOUT AMSTRAD.TO.GPT$
6020 PRINT #9, ""
6030 CLOSEOUT
6040 RETURN

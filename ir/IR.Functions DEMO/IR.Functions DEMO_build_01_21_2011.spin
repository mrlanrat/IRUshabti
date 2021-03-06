CON
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 5_000_000

{{
*********************************************
* IR.Functions DEMO_build_01_21_2011   v1.0 *
*                                           *
* Author: Beau Schwabe                      *
* Copyright (c) 2011 Parallax               *
* See end of file for terms of use.         *
*********************************************

Revision History:
                  Version 1.0   - (01-15-2011) original file created


Tested Remotes:
BIONAIRE             - Wireless floor heater (threshold of 5000,     Ratio of 2)(12-Bits)(Manchester)
PANASONIC            - TV/VCR                (5000/10000 didn't care,Ratio of 2)(50-Bits)(Fixed Mark)
RCA Generic          - UNIVERSAL             (5000/10000 didn't care,Ratio of 2)(18-Bits)(Fixed Mark)
Phillips             - DVD/VCR Player        (5000/10000 didn't care,Ratio of 2)(18-Bits)(Fixed Space)
JVC  (RM-V715U)      - VIDEO camera          (5000/10000 didn't care,Ratio of 2)(17-Bits)(Fixed Mark)
SONY (RMT-V154A)     - TV/VCR                (5000/10000 didn't care,Ratio of 2)(13-Bits)(Fixed Space)
SONY (RM-736)        - TV/VCR                (5000/10000 didn't care,Ratio of 2)(13-Bits)(Fixed Space)
SONY (RM-D190)       - CD PLAYER             (5000/10000 didn't care,Ratio of 2)(13-Bits)(Fixed Space)
Technics (SH-R808)   - Radio/Tape/Turntable  (threshold of 10000,    Ratio of 3)(11-Bits)(Fixed Mark)
Chrysler Auto Remote - Rear Seat DVD remote  (5000/10000 didn't care,Ratio of 2)(33-Bits)(Fixed Mark)
Generic DVD          - DVD Video / TV        (5000/10000 didn't care,Ratio of 2)(33-Bits)(Fixed Mark)
iLive (IBCD2817DP)   - Radio/CD player       (5000/10000 didn't care,Ratio of 2)( 8-Bits)(Fixed Space and Fixed Mark)
Credit Card Remote   - Generic 008           (5000/10000 didn't care,Ratio of 2)(33-Bits)(Fixed Mark)                                 
Polariod (RC-6007)   - Camera                (5000/10000 didn't care,Ratio of 2)(33-Bits)(Fixed Mark)
                   

}}
  IRTX_pin = 13
  IRRX_pin = 12

  IRmodulation = 37_500         'Used for transmiting IR signal

  Threshold1 = 5_000            'This value in micro seconds represents the initial pulse
                                'width which starts the IR code sequence 

  Threshold2 = 10_000           'This value in micro seconds represents the maximum IR pulse
                                'width and MUST be less than the resolve value times 255.
                                'Note: Typically the maximum pulse length that I have seen is
                                'around 9000 us, however in some cases the threshold value
                                'needs to be less than 6000us
  
OBJ

PST           : "Parallax Serial Terminal"
IRF           : "IR.Functions_build_01_21_2011"


VAR

byte    DataBuffer[1000]         'Used to store the IRCode and IR Bitstream after decoding translation.



PUB CodeTest|num,Size,flag,offset,i,Bits

    PST.Start(19200)         '<-Start USB Serial for this demo

    outa[1..0]~~
    outa[1..0] := %01

    PST.Char(0)
    repeat
      PST.Char(1) 
      PST.str(string("Waiting to decode IR signal..."))
      IRF.start(IRRX_pin,Threshold1,Threshold2)       '<-Start IR Decoder

      repeat while IRF.IR_Ready<>1   '<-Wait here until IR received

      if IRF.GetBitCount == -1
         PST.Char(0)
         PST.str(string("Data Error - try decreasing Threshold2"))
         PST.Char(7)
         waitcnt(cnt+clkfreq)
         PST.Char(0)
                         'Note: The other reason could be that the bit count is set
                         '      lower than the received number of bits.  However this
                         '      is less likely than the threshold being set too high,
                         '      because internally the bitcount is set to 150
                         'Hint: If repeated presses yield bitcounts that share a common
                         '      factor, then it is likely that the threshold is too high.   
      else
         PST.Char(0)
         PST.Char(13)
         PST.Char(13)
'-----------------------------------------------------------

         PST.str(string("Bit Count for current IR code sequence:"))
         PST.Char(13)
         PST.dec(IRF.GetBitCount)  '<-Get number of IR Bits detected in code

         PST.Char(13)              '  Note: this function isn't necessary for
         PST.Char(13)              '        decoding, it just provides the 
                                   '        information to the user.  

         PST.str(string("Compressed IR Code sequence (includes timing data): - see DAT section of this program"))
         PST.Char(13)
         IRF.GetIRCode(@DataBuffer)'<-Get IR code ; Note: Code is a compressed
         PST.str(@DataBuffer)      '  representation of the time/on time off of
         PST.Char(13)              '  the RAW IR signal reduced to 1 byte pair
         PST.Char(13)              '  per bit.  The first BYTE is always the
                                   '  multiplier, while the last byte multiplied
                                   '  by the first byte represents the maximum
                                   '  timeout threshold in micro seconds.
{
      Example:
              23270926090E21260926090E210E210E210E2126090E210E8B
                  
              The first HEX byte $23 multiplied by the next HEX byte $27 equals
              $555 or 1365us <- remember the numbers are in HEX

              So the first pulse duration is 1365us ... the next $23 x $09 = $13B
              or 315us

              ...following this throughout the entire sequence represents the
              complete IR sequence, not represented in Bits, but the actual
              mark/space transition times.

              The last HEX byte $8B x $23 = $1301 or 4865us ... This value is the
              threshold set as the maximum pulse length signaling the end of IR
              transmission.

              Note: The first pulse should always be LOW while the last pulse should
              always be HIGH thus returning to the resting state "high" of the IR
              detector.    
}                                
'-----------------------------------------------------------    
         PST.str(string("Bit Pattern: Fixed Space/Manchester"))
         PST.Char(13)
         IRF.GetBitPattern(@DataBuffer,0,2) '<- Decodes binary bit pattern for Fixed Space
         PST.str(@DataBuffer)
         PST.Char(13)
         PST.Char(13)
      

'-----------------------------------------------------------
         PST.str(string("Bit Pattern: Fixed Mark/Manchester"))
         PST.Char(13)
         IRF.GetBitPattern(@DataBuffer,1,2) '<- Decodes binary bit pattern for Fixed mark
         PST.str(@DataBuffer)
         PST.Char(13)
'                                        Note: In both cases of GetBitPattern, if the
'                                        IR encoding is in Manchester, then both
'                                        functions will return the same bit pattern.


         if IRF.PatternCheck(@Pattern2,@DataBuffer)== 1   '<- Just check to see if received code matches
            PST.str(string(9,9,9,"Code matches!"))        ' ( See DAT section)
         else
            PST.str(string(9,9,9,"Wrong code! - see DAT section of this program"))

                                      '       Note: If you use PatternCheck it must be done
                                      '             AFTER the appriopriate GetBitPattern of
                                      '             fixed space/mark is done.             
           
         PST.Char(13)
         PST.Char(13)


          

'     For Example with some remotes I have:
'
'                                        fixed space    fixed mark 
'     SONY is typically fixed space     ..1.1.11..1.1  ............1
'     MAGNAVOX is typically fixed mark  .111111111111  .1.1.1.111.11
'     While a generic no-name is Manch  ...1..1111.11  ...1..1111.11

'-----------------------------------------------------------
''            Transmitter Section:

'         waitcnt(cnt+clkfreq*2)
'         outa[16..23]~~
'         IRF.SendCode(@Heater,IRTX_pin,1,20,IRmodulation)
'         outa[16..23]~

         waitcnt(cnt+clkfreq/4)


DAT

          
'Use the Bit pattern method below if you just want the Propeller to Decode your next
'IR remote project.  Note: you will need to use the pattern generated from your own remote
'using Mode0 or Mode1 from the GetBitPattern function depending on what the remote
'archetecture is... Fixed Space, Fixed Mark, or Manchester style coding 

Pattern1      byte ".11......111.1...1",0   '<- Just cut and paste the code from the PST
                                            '   Here.  If the bitstream is really long,
                                            '   you can wrap it around like the examples
                                            '   below... as long as you have a Zero at the
                                            '   end.
Pattern2      byte ".111....1.1.."
              byte ".1..1.....1.."
              byte "11111.11",0


              ''insane 114 bit IR code from an airconditioner unit
Pattern3      byte ".11...1..11.1..11.11..1..1.................1..1..1......."
              byte "11.1....................................1..1.....111..1.1",0
              


'Use the IRCode method below if you want the Propeller to Send valid IR code in your
'next IR remote project.

'Eject code for our DVR player ... grab your own remote and use the IR code generated from
'                                  this program and place it below.  Notice the method used
'                                  to wrap the data string around.
 
DVD_Eject     byte "32B6570D1F0D1F0D1F0D080D080D080D080D1F0D080D1F0D080D080D080D"
              byte "1E0D080D080D080D080D1E0D080D080D080D1E0D080D1F0D1F0D080D1F0D"
              byte "1F0D1E0D080D1F0DC8",0

Heater        byte "321C061B060A171B061B060A170A170A171B060A170A170A64",0

              

CON
{{
┌───────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                                     │                                                            
├───────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and  │
│associated documentation files (the "Software"), to deal in the Software without restriction,      │
│including without limitation the rights to use, copy, modify, merge, publish, distribute,          │
│sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is      │
│furnished to do so, subject to the following conditions:                                           │
│                                                                                                   │
│The above copyright notice and this permission notice shall be included in all copies or           │
│ substantial portions of the Software.                                                             │
│                                                                                                   │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT  │
│NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND             │
│NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,       │
│DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,                   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE        │
│SOFTWARE.                                                                                          │     
└───────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
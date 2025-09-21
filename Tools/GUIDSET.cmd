@echo off
cls
echo. Programmiere Vendor Settings
echo.
echo.

echo part 1
amidewinx64 /SM "Systec & Solutions GmbH"
rem pause
amidewinx64 /SP "WAVE 224"
rem pause
amidewinx64 /SV "V2023"
rem pause
amidewinx64 /SS "A07390"
rem pause
amidewinx64 /SU "A07390"
rem pause
amidewinx64 /SK "A07390"
rem pause

echo part 2
amidewinx64 /BM "Systec & Solutions GmbH"
rem pause
amidewinx64 /BP "WAVE 224"
rem pause
amidewinx64 /BV "V2023"
rem pause
amidewinx64 /BS "A07390"
rem pause
amidewinx64 /BT "A07390"
rem pause

echo part3
amidewinx64 /CM "Systec & Solutions GmbH"
rem pause
amidewinx64 /CT "WAVE 224"
rem pause
amidewinx64 /CV "V2023"
rem pause
amidewinx64 /CA "WAVE 224"
rem pause
amidewinx64 /CS "A07390"
rem pause
amidewinx64 /CA "WAVE 224"
rem pause
amidewinx64 /CO "OEM INFO"
rem pause

echo part4
amidewinx64 /OS 1 "Systec & Solutions GmbH HMI Device"
rem pause
amidewinx64 /SCO 1 "Systec & Solutions GmbH HMI Device"
rem pause

amidewinx64 /ALL A07390-all.txt
amidewinx64 /DMS A07390-dms.txt

echo folgende Werte wurden aus dem Barcode generiert
echo.
echo Seriennummer: A07390
echo Artikelnummer: W24AD903X1
echo Gerätetyp: WAVE 224
echo.
echo folgende Log Files wurden zum Programmiervorgang angelegt
echo A07390.all.txt
echo A07390.dms.txt
echo.
echo Alle Wert sind Programmiert
echo. 


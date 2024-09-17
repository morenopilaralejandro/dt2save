# Digital Tamers 2 cross-save script 
Linux bash script that allows save data transfer between Android and PC for the game Digital Tamers 2.

## Requirements
First, download [Android Backup Processor](https://sourceforge.net/projects/android-backup-processor/) and extract it.
<br><br>
Then, install ADB. 
```console
sudo apt install adb
```
Finally, enable USB debugging on Android.

## Execute script
```console
chmod +x dt2save.sh 
./dt2save.sh
```
## Options
-u
<br>upload save data from Android to PC

-d
<br>
download save data from PC to Android

-b DIRECTORY
<br>
backup Android save data to the specified directory

-B DIRECTORY
<br>
backup PC save data to the specified directory

-r FILE
<br>
restore the specified backup file to Android

-R FILE
<br>
restore the specified backup file to PC

-h: help.
<br>
display help and exit

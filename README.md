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
<br>
Upload save data from Android to PC.

-d
<br>
Download save data from PC to Android.

-b DIRECTORY
<br>
Backup Android save data to the specified directory.

-B DIRECTORY
<br>
Backup PC save data to the specified directory.

-r FILE
<br>
Restore the specified backup file to Android.

-R FILE
<br>
Restore the specified backup file to PC.

-h
<br>
Display help and exit.

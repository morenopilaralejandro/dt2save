#!/bin/bash
#variables
gameName="DigitalTamers02";
gamePackage="com.dragonrodgames.DigitalTamers02";
gamePrefix="";
saveDataName="DT2_save0";
pathAbpJar="/home/$USER/Games/digita2/";
pathRoaming="";
pathUserBackup="";

#methods
errorEcho() {
  echo "$@" 1>&2;
}

usage () {
    echo "Requirements:";
    echo "  Download and extract Android Backup Processor (https://sourceforge.net/projects/android-backup-processor/).";
    echo "  Install ADB (sudo apt install adb).";
    echo "  Enable USB debugging on Android.";
    echo "";
    echo "Options:";
    echo "  -u";
    echo "      upload save data from Android to PC";
    echo "";
    echo "  -d";
    echo "      download save data from PC to Android";
    echo "";
    echo "  -b DIRECTORY";
    echo "      backup Android save data to the specified directory";
    echo "";
    echo "  -B DIRECTORY";
    echo "      backup PC save data to the specified directory";
    echo "";
    echo "  -r FILE";
    echo "      restore the specified backup file to Android";
    echo "";
    echo "  -R FILE";
    echo "      restore the specified backup file to PC";
    echo "";
    echo "  -h: help.";
    echo "      display help and exit";
    exit;
}

checkArgs() {
    local OPTIND;
    #if argument number != 1 then show usage
    if [ $# -eq 0 ]; then
        usage;
        exit;
    fi
}

setGamePrefix() {
    #steam display name can affect this
    auxGamePrefix=$(protontricks -l | grep Digi | rev |cut -d' ' -f1 | rev);
    auxGamePrefix=$(echo $auxGamePrefix | sed 's/(//g');
    auxGamePrefix=$(echo $auxGamePrefix | sed 's/)//g');
    gamePrefix=$auxGamePrefix;
}

setPathRoaming() {
    pathRoaming="/home/$USER/.steam/steam/steamapps/compatdata/${gamePrefix}/pfx/drive_c/users/steamuser/AppData/Roaming/${gameName}/";
    mkdir -p ${pathRoaming}aux;
}

checkGamePrefix() {
    if [ -e /home/$USER/.steam/steam/steamapps/compatdata/${gamePrefix}/ ]; then
        echo "---Found game prefix: ${gamePrefix}";
        setPathRoaming;
    else
        errorEcho "---Error: couldn't find prefix for game ${gameName}";
        exit;
    fi
}

findPathAbpJar() {
    echo "---Searching abp.jar";
    pathAbpJar=$(find /home/$USER -name "abp.jar" 2> /dev/null | head -n1);
}

isValidPathAbpJar() {
    if [ ! -z "$pathAbpJar" ] && [ -e $pathAbpJar ]; then
        return;
    fi
    false;
}

setPathAbpJar() {
    #check aux txt file
    if [ -e ${pathRoaming}aux/pathAbpJar.txt ]; then
        pathAbpJar=$(cat ${pathRoaming}aux/pathAbpJar.txt);
        if ! isValidPathAbpJar; then
            findPathAbpJar;
        fi        
    else
        findPathAbpJar;
    fi
}

checkPathAbpJar() {
    #if path is not empty and file exists
    if isValidPathAbpJar; then
        echo "---Found abp.jar: ${pathAbpJar}";
        echo $pathAbpJar > ${pathRoaming}aux/pathAbpJar.txt;
    else    
        errorEcho "---Error: file abp.jar not found. Make sure abp.jar is under /home/${USER}";
        rm -rf ${pathRoaming}aux/pathAbpJar.txt;
    fi
}

checkPhoneConnected() {
    #The phone needs to be pluged to the pc with USB debugging enabled
    #adb shell pm list packages: get all installed packages.
    #Used for checking if phone is connected before proceeding 
    if adb shell pm list packages > /dev/null 2>&1 ; then
        echo "---Device connected";
    else
        errorEcho "---Error: device is not connected. Make sure USB debugging is on.";
        exit;
    fi
}

unpackAbToTar() {
    echo "---Converting backup.ab to backup.tar";
    java -jar ${pathAbpJar} unpack ${pathRoaming}aux/backup.ab ${pathRoaming}aux/backup.tar;
}

packTarToAb() {
    echo "---Converting backup.tar to backup.ab";
    java -jar ${pathAbpJar} pack ${pathRoaming}aux/backup.tar ${pathRoaming}aux/backup.ab;
}

extractTar() {
    echo "---Extracting backup.tar";
    tar -xf ${pathRoaming}aux/backup.tar -C ${pathRoaming}aux/;
}

compressTar() {
    echo "---Compressing backup.tar";
    cd ${pathRoaming}aux;
    find apps -type f | xargs -I {} tar rf backup.tar '{}' --format=ustar;
}


isValidAb() {
    backupFileSize=$(wc -c ${pathRoaming}aux/backup.ab | cut -d' ' -f1);
    if [ $backupFileSize -gt 0 ]; then
        return;
    fi
    false;
}

createAb() {
    adb backup ${gamePackage} -f ${pathRoaming}aux/backup.ab;
    if isValidAb; then
        unpackAbToTar;
        extractTar;
    else
        errorEcho "---Error: backup canceled";
    fi
}

restoreAb() {
    adb restore ${pathRoaming}aux/backup.ab;
}

copyToRoaming() {
    echo "---Copying save data to ${pathRoaming}";
    cp ${pathRoaming}aux/apps/${gamePackage}/f/${saveDataName}.sav ${pathRoaming};
}

copyToPackage() {
    echo "---Copying save data to ${gamePackage}";
    cp ${pathRoaming}${saveDataName}.sav ${pathRoaming}aux/apps/${gamePackage}/f/;
}

checkManifest() {
    if [ ! -e ${pathRoaming}aux/apps/${gamePackage}/_manifest ]; then
        echo "---Setting up save data transfer...";
        createAb;
    fi
}

isDirectory() {
    if [ -d "$@" ]; then
        return;
    fi
    false;
}

isFile() {
    if [ -f "$@" ]; then
        return;
    fi
    false;
}

saveUpload() {
    setGamePrefix;
    checkGamePrefix;
    setPathAbpJar;
    checkPathAbpJar;
    checkPhoneConnected;
    echo "---Uploading save data from Android to PC...";
    createAb;
    if isValidAb; then
        copyToRoaming;
        echo "---Upload completed";
    fi
}

saveDownload() {
    setGamePrefix;
    checkGamePrefix;
    setPathAbpJar;
    checkPathAbpJar;
    checkPhoneConnected;
    checkManifest;
    if isValidAb; then
        echo "---Downloading save data from PC to Android...";
        copyToPackage;
        compressTar;
        packTarToAb;
        echo "---Restoring backup";
        restoreAb;
        echo "---Wait for your device to finish";
    fi
}

backupAndroid() {
    setGamePrefix;
    checkGamePrefix;
    setPathAbpJar;
    checkPathAbpJar;
    checkPhoneConnected;
    if isDirectory "$OPTARG"; then
        echo "---Backing up Android save data...";
        createAb;
        if isValidAb; then
            backupName="dt2save-$(date +"%Y%m%d%H%M%S").tar";
            echo "---Saving to ${OPTARG%/}/${backupName}";
            tar -cf ${OPTARG%/}/${backupName} -C ${pathRoaming}aux/apps/${gamePackage}/f/ ${saveDataName}.sav
            echo "---Backup completed";
        fi
    else
        errorEcho "---Error: invalid directory $OPTARG";
    fi
}

backupComputer() {
    setGamePrefix;
    checkGamePrefix;
    if isDirectory "$OPTARG"; then
        echo "---Backing up PC save data...";
        backupName="dt2save-$(date +"%Y%m%d%H%M%S").tar";
        echo "---Saving to ${OPTARG%/}/${backupName}";
        tar -cf ${OPTARG%/}/${backupName} -C ${pathRoaming} ${saveDataName}.sav
        echo "---Backup completed";
    else
        errorEcho "---Error: invalid directory $OPTARG";
    fi
}

restoreBackupAndroid() {
    setGamePrefix;
    checkGamePrefix;
    setPathAbpJar;
    checkPathAbpJar;
    checkPhoneConnected;
    if isFile "$OPTARG"; then
        checkManifest;
        if isValidAb; then
            echo "---Restoring backup to Android...";
            echo "---Backup file: ${OPTARG}";
            tar -xf ${OPTARG} -C ${pathRoaming}aux/apps/${gamePackage}/f/
            compressTar;
            packTarToAb;
            echo "---Restoring backup";
            restoreAb;
            echo "---Wait for your device to finish";
        fi
    else
        errorEcho "---Error: invalid file $OPTARG";
    fi
}

restoreBackupComputer() {
    setGamePrefix;
    checkGamePrefix;
    if isFile "$OPTARG"; then
            echo "---Restoring backup to PC...";
            echo "---Backup file: ${OPTARG}";
            tar -xf ${OPTARG} -C ${pathRoaming}
            echo "---Backup restored";
    else
        errorEcho "---Error: invalid file $OPTARG";
    fi
}

handleFlags() {
    local OPTIND;
    while getopts "udb:B:r:R:h" flag; do
        case "${flag}" in
            u)  
                saveUpload;
                ;;
            d)  
                saveDownload;
                ;;
            b)  
                backupAndroid "$OPTARG";
                ;;
            B)  
                backupComputer "$OPTARG";
                ;;
            r)  
                restoreBackupAndroid "$OPTARG";
                ;;
            R)  
                restoreBackupComputer "$OPTARG";
                ;;
            h)  #help
                usage;
                ;;
            \?) #invalid option
                usage;
                ;;
            *) #invalid option
                usage;
                ;;
        esac
    done
}

main() {
    local OPTIND;
    checkArgs "$@";
    handleFlags "$@";
}

main "$@";

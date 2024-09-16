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
    echo "  Android Backup Processor.";
    echo "  adb.";
    echo "  Developer options enabled on the phone.";
    echo "Options:";
    echo "  -u: upload save data from android to pc.";
    echo "  -d: download save data from pc to android.";

    echo "  -h: help.";
    exit;
}

checkArgs() {
    local OPTIND;
    #if argument number != 1 then show usage
    if [ $# -ne 1 ]; then
       usage;
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
        errorEcho "---Error: prefix for game ${gameName} not found";
        exit;
    fi
}

setPathAbpJar() {
    #check aux txt file
    if [ -e ${pathRoaming}aux/pathAbpJar.txt ]; then
        pathAbpJar=$(cat ${pathRoaming}aux/pathAbpJar.txt);
    else
        pathAbpJar=$(find /home/$USER -name "abp.jar" 2> /dev/null | head -n1);
        echo $pathAbpJar > ${pathRoaming}aux/pathAbpJar.txt;
    fi
}

setPathUserBackup() {
    #check aux txt file
    if [ -e ${pathRoaming}aux/pathUserBackup.txt ]; then
        pathUserBackup=$(cat ${pathRoaming}aux/pathUserBackup.txt);
    else
        pathUserBackup="/home/$USER/Documents/";
    fi
}

checkPathAbpJar() {
    #if path is not empty and file exits
    if [ ! -z "$pathAbpJar" ] && [ -e $pathAbpJar ]; then
        echo "---Found abp.jar: ${pathAbpJar}";
    else
        errorEcho "---Error: file abp.jar not found. Make sure abp.jar is under /home/${USER}";
        rm -rf ${pathRoaming}aux/pathAbpJar.txt;
        exit;
    fi
}

checkPhoneConnected() {
    #The phone needs to be pluged to the pc with developer options enabled
    #adb shell pm list packages: get all installed packages.
    #Used for checking if phone is connected before proceeding 
    if adb shell pm list packages > /dev/null 2>&1 ; then
        echo "---Phone connected";
    else
        errorEcho "---Error: phone is not connected";
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
    find apps -type f | xargs -I {} tar rf backup.tar '{}' --format=ustar
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
    echo "---Moving save data to ${pathRoaming}";
    cp ${pathRoaming}aux/apps/${gamePackage}/f/${saveDataName}.sav ${pathRoaming};
}

copyToPackage() {
    echo "---Moving save data to ${gamePackage}";
    cp ${pathRoaming}${saveDataName}.sav ${pathRoaming}aux/apps/${gamePackage}/f/;
}

checkManifest() {
    if [ ! -e ${pathRoaming}aux/apps/${gamePackage}/_manifest ]; then
        echo "---Setting up data transfer...";
        createAb;
    fi
}

saveUpload() {
    setGamePrefix;
    checkGamePrefix;
    setPathAbpJar;
    checkPathAbpJar;
    checkPhoneConnected;
    echo "---Uploading save data from android to pc...";
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
        echo "---Downloading save data from pc to android...";
        copyToPackage;
        compressTar;
        packTarToAb;
        echo "---Restoring backup";
        restoreAb;
        echo "---Wait for phone to finish";
    fi
}

handleFlags() {
    local OPTIND;
    while getopts "udh" flag; do
        case "${flag}" in
            u)  
                saveUpload;
                ;;
            d)  
                saveDownload;
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

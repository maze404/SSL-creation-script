#!/bin/bash
## Script for making the creation of .key and .csr files easier
## Requires WSL 1/2 or Debian/Ubuntu
######################################################################################################################################################################
##                                                                                                                                                                  ##
## Author: Maze404                                                          			                                                                            ##
##                                                                                                                                                                  ##
## Description: A script which provides an easy way to create .key and .csr files and stores all certificate files and information in dedicated directories         ##
##                                                                                                                                                                  ##
######################################################################################################################################################################
## Global Variables:
work="\e[44;97m[WORK]\e[39;49;1m"
done="\e[1A\e[42;30m[DONE]\e[39;49;1m"
done0L="\e[42;30m[DONE]\e[39;49;1m"
error="\e[41;97;1m[ERROR]"
warning="\e[103;30;1m[WARNING]\e[39;49;1m"
text="\e[107;90m"
reset="\e[0m"
stretchToEol="\x1B[K"

isFirstStartup=true
sslFileDirectory=/home/$USER/SSL-Archive
domainList=/home/$USER/SSL-Archive/Domain-List
savePath=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

## Functions:
csrKeyCreation () {
echo -e "$warning$stretchToEol Please check, if the following is correct:$reset"
echo -e "$text$stretchToEol SSL INFORMATION FOR $selFqdn\n
------------------------------------------------------------\n
FQDN:                  $selFqdn\n
COUNTRY NAME:          $selCountry\n
STATE OR PROVINCE:     $selState\n
LOCALITY NAME:         $selLocality\n
COMPANY NAME:          $selCompany\n
ORGANISATIONAL UNIT:   $selOu\n
ADMINISTRATIVE E-MAIL: $selAdminEmail\n
------------------------------------------------------------\n$reset"
read -rp "Press [ENTER] to continue: "
echo -e "$text Please enter$reset" 
echo -e "$text [\e[36m1\e[39m] $text  for 2048 bits$reset"
echo -e "$text [\e[36m2\e[39m] $text  for 4096 bits$reset"
exec 2>/dev/tty 3>/dev/tty
read -rp "Selection: " bitselection
exec 2>/dev/null 3>/dev/null
if [ "$bitselection" = 1 ]
    then
        bit=2048
elif [ "$bitselection" = 2 ]
    then
        bit=4096
else
    echo -e "$error Wrong input, aborting...$reset"
    exit 1
fi

cd "$sslFileDirectory"/"$selectedFqdn" || exit
echo -e "$work Creating key file with" $bit "bits...$reset"
openssl genrsa -out "$selFqdn".key "$bit" 2>&1
echo -e "$done Creating key file with" $bit "bits...$reset"
echo -e "$work Creating csr file...$reset"
detail="/C=$selCountry/ST=$selState/L=$selLocality/O=$selCompany/OU=$selOu/CN=$selFqdn/emailAddress=$selAdminEmail"
openssl req -new -key "$selFqdn".key -sha256 -subj "$detail" -out "$selFqdn".csr 2>&1
echo -e "$done Creating csr file...$reset"
echo -e "$work Creating .crt, .pem and .CA.crt files...$reset"
echo -e "$warning Those files are empty and must be manually filled in after certificate creation/extension!$reset"
touch "$selFqdn".crt
touch "$selFqdn".CA.crt
touch "$selFqdn".pem
echo -e "$done The files are under $sslFileDirectory/$selectedFqdn $reset"
}
######################################################################################################################################################################
## Main script:
if [[ $isFirstStartup = true ]]
    then
        clear
        if ! openssl version >> /dev/null
            then
                echo -e "Please install OpenSSL:"
                sudo apt install -y openssl
        fi
        echo -e "$text$stretchToEol Would you like to change the default directory for SSL-Files?$reset"
        echo -e "$text$stretchToEol The default is /home/$USER/SSL-Archive.$reset"
        read -rp "[Y]es / [N]o: [N] " changeDefaultDir
        changeDefaultDir=${changeDefaultDir:-N}
        if [ "$changeDefaultDir" = Y ] || [ "$changeDefaultDir" = y ]
            then
                echo -e "$text$stretchToEol Please enter your new save path:$reset"
                read -rp "Path: " newSslFileDirectory
                sed -i "/sslFileDirectory=/c\sslFileDirectory=$newSslFileDirectory" "$savePath"/ssl-script.sh
                sslFileDirectory=$newSslFileDirectory
            elif [ "$changeDefaultDir" = N ] || [ "$changeDefaultDir" = n ]
                then
                    mkdir /home/"$USER"/SSL-Archive
            else
                echo -e "$error Wrong input, aborting...$reset"
        fi
        if grep -q "$savePath" ~/.bashrc
            then
                echo ""
            else
                echo -e "$text$stretchToEol Would you like to add the script to your .bashrc file to make it executeable anywhere?$reset"
                read -rp "[Y]es / [N]o: [Y] " confirmBashRC
                confirmBashRC=${confirmBashRC:-Y}
                if [ "$confirmBashRC" = Y ] || [ "$confirmBashRC" = y ]
                    then
                        echo 'ssl () {' >> ~/.bashrc
                        echo "    cd \"$savePath\" && ./ssl-script.sh" >> ~/.bashrc
                        echo '}' >>  ~/.bashrc
                        exec 2>/dev/tty 3>/dev/tty
                        echo -e "$done Please launch the script again by typing 'ssl' into the terminal$reset"
                        exec 2>/dev/null 3>/dev/null
                        exit 0
                fi
        fi
    touch "$sslFileDirectory"/Domain-List
    sudo sed 's/^isFirstStartup=/isFirstStartup=false/' "$savePath"/ssl-script.sh
fi
clear
cd "$savePath" || exit
echo -e "$text$stretchToEol┌─────────────────────────────────────────────────────────────┐$reset"
echo -e "$text$stretchToEol│ Please enter:                                               │$reset"
echo -e "$text$stretchToEol│  [\e[36m1\e[39m$text$stretchToEol] to add a domain to the list                            │$reset"
echo -e "$text$stretchToEol│  [\e[36m2\e[39m$text$stretchToEol] to search a certain domain                             │$reset"
echo -e "$text$stretchToEol│  [\e[36m3\e[39m$text$stretchToEol] to manually create the files                           │$reset"
echo -e "$text$stretchToEol└─────────────────────────────────────────────────────────────┘$reset"

exec 2>/dev/tty 3>/dev/tty
read -rp "Selection: " menu
exec 2>/dev/null 3>/dev/null

case $menu in
    1)
        echo -e "Please enter the FQDN:"
        read -rp "Input: " fqdn
        echo -e "Please enter the country name (2 letters, example: DE for Germany):"
        read -rp "Input: " country
        echo -e "Please enter the state or province:"
        read -rp "Input: " state
        echo -e "Please enter the city or locality:"
        read -rp "Input: " locality
        echo -e "Please enter the company name:"
        read -rp "Input: " company
        echo -e "Please enter the organisational unit (mostly e-commerce)"
        read -rp "Input: " ou
        echo -e "Please enter the administrative e-mail address for the domain:"
        read -rp "Input: " adminEmail
        mkdir "$fqdn"
        tee "$fqdn/$fqdn-ssl-info.txt" > /dev/null <<EOF
SSL INFORMATION FOR $fqdn
------------------------------------------------------------
FQDN:                  $fqdn
COUNTRY NAME:          $country
STATE OR PROVINCE:     $state
LOCALITY NAME:         $locality
COMPANY NAME:          $company
ORGANISATIONAL UNIT:   $ou
ADMINISTRATIVE E-MAIL: $adminEmail
------------------------------------------------------------
EOF
        echo "$fqdn" >> "$domainList"
        echo -e "$done0L"
    ;;
    2)
        clear
        echo -e "Please enter the domain you whish to search for:"
        read -rp "Domain: " domainSearch
        selectedFqdn=$(cat "$domainList" | grep "$domainSearch")
        echo -e "The full selected FQDN is called $selectedFqdn"
        certificateValidity=$(echo -ne '\n' | openssl s_client -connect "$selectedFqdn"0:443 -servername "$selectedFqdn" -showcerts | openssl x509 -inform pem -noout -text | grep "Not After" | sed -e "s/^            Not After : //" | sed -e "s/GMT$//")
        echo -e "Expiration date for the certificate for $selectedFqdn: $certificateValidity"
        echo -e ""
        echo -e "Would you like to create the .csr and .key file now?"
        exec 2>/dev/tty 3>/dev/tty
        read -rp "[Y]es / [N]o: [Y]" createConfirm
        exec 2>/dev/null 3>/dev/null
        createConfirm=${createConfirm:-Y} 
        if [ "$createConfirm" = Y ] || [ "$createConfirm" = y ]
            then
                selFqdn=$( { cat "$selectedFqdn/$selectedFqdn-ssl-info.txt" | grep -Pom 1 '\*FQDN.+' | cut -c 23-; } 2>&1)
                selCountry=$( { cat "$selectedFqdn/$selectedFqdn-ssl-info.txt" | grep -Pom 1 '\*COUNTRY NAME.+' | cut -c 23-; } 2>&1)
                selState=$( { cat "$selectedFqdn/$selectedFqdn-ssl-info.txt" | grep -Pom 1 '\*STATE OR PROVINCE.+' | cut -c 23-; } 2>&1)
                selLocality=$( { cat "$selectedFqdn/$selectedFqdn-ssl-info.txt" | grep -Pom 1 '\*LOCALITY NAME.+' | cut -c 23-; } 2>&1)
                selCompany=$( { cat "$selectedFqdn/$selectedFqdn-ssl-info.txt" | grep -Pom 1 '\*COMPANY NAME.+' | cut -c 23-; } 2>&1)
                selOu=$( { cat "$selectedFqdn/$selectedFqdn-ssl-info.txt" | grep -Pom 1 '\*ORGANISATIONAL UNIT.+' | cut -c 23-; } 2>&1)
                selAdminEmail=$( { cat "$selectedFqdn/$selectedFqdn-ssl-info.txt" | grep -Pom 1 '\*ADMINISTRATIVE E-MAIL.+' | cut -c 23-; } 2>&1)
                csrKeyCreation
        fi
    ;;
    3)
        clear
        echo -e "Please enter the FQDN:"
        read -rp "Input: " selFqdn
        echo -e "Please enter the country name (2 letters, example: DE for Germany):"
        read -rp "Input: " selCountry
        echo -e "Please enter the state or province:"
        read -rp "Input: " selState
        echo -e "Please enter the city or locality:"
        read -rp "Input: " selLocality
        echo -e "Please enter the company name:"
        read -rp "Input: " selCompany
        echo -e "Please enter the organisational unit (mostly e-commerce)"
        read -rp "Input: " selOu
        echo -e "Please enter the administrative e-mail address for the domain:"
        read -rp "Input: " selAdminEmail
        csrKeyCreation
    ;;
    *)
        echo -e "$error Wrong input, aborting...$reset"
        exit 1
    ;;
esac

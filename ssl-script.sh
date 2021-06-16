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
isFirstStartup=true
sslFileDirectory=/home/$USER/SSL-Archive
domainList=/home/$USER/SSL-Archive/Domain-List
savePath=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

## Functions:
csrKeyCreation () {
echo "Please check, if the following is correct:"
echo -e "SSL INFORMATION FOR $selFqdn\n
------------------------------------------------------------\n
FQDN:                  $selFqdn\n
COUNTRY NAME:          $selCountry\n
STATE OR PROVINCE:     $selState\n
LOCALITY NAME:         $selLocality\n
COMPANY NAME:          $selCompany\n
ORGANISATIONAL UNIT:   $selOu\n
ADMINISTRATIVE E-MAIL: $selAdminEmail\n
------------------------------------------------------------\n"
read -rp "Press [ENTER] to continue: "
echo -e "Please enter" 
echo -e "[\e[36m1\e[39m] for 2048 bits"
echo -e "[\e[36m2\e[39m] for 4096 bits"
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
    echo -e "$(tput bold)\e[91mWrong Input!\e[39m$(tput sgr0)"
    echo -e "$(tput bold)\e[91mAborting. \e[39m$(tput sgr0)"
fi

cd "$sslFileDirectory"/"$selectedFqdn" || exit
echo -e "Creating key file with" $bit "bits..."
openssl genrsa -out "$selFqdn".key "$bit"
echo -e "Creating csr file..."
detail="/C=$selCountry/ST=$selState/L=$selLocality/O=$selCompany/OU=$selOu/CN=$selFqdn/emailAddress=$selAdminEmail"
openssl req -new -key "$selFqdn".key -sha256 -subj "$detail" -out "$selFqdn".csr
echo -e "Creating .crt, .pem and .CA.crt files..."
echo -e "WARNING! Those files are empty and must be manually filled in after certificate creation/extension!"
touch "$selFqdn".crt
touch "$selFqdn".CA.crt
touch "$selFqdn".pem
echo -e "Done. The files are under $sslFileDirectory/$selectedFqdn"
}
######################################################################################################################################################################
## Main script:
if [[ $isFirstStartup = true ]]
    then
        if ! openssl version
            then
                echo -e "Please install OpenSSL:"
                sudo apt install -y openssl
        fi
        echo -e "Would you like to change the default directory for SSL-Files?"
        echo -e "The default is /home/$USER/SSL-Archive."
        read -rp "[Y]es / [N]o: [Y]" changeDefaultDir
        if [ "$changeDefaultDir" = Y ] || [ "$changeDefaultDir" = y ]
            then
                echo -e "Please enter your new save path:"
                read -rp "Path: " newSslFileDirectory
                sed -i "/sslFileDirectory=/c\sslFileDirectory=$newSslFileDirectory" "$savePath"/ssl-script.sh
                sslFileDirectory=$newSslFileDirectory
        fi
        if grep -q "$savePath" ~/.bashrc
            then
                echo ""
            else
                echo -e "Would you like to add the script to your .bashrc file to make it executeable anywhere?"
                read -rp "[Y]es | [N]o " confirmBashRC
                if [ "$confirmBashRC" = Y ] || [ "$confirmBashRC" = y ]
                    then
                        echo 'ssl () {' >> ~/.bashrc
                        echo "    cd \"$savePath\" && ./ssl.sh" >> ~/.bashrc
                        echo '}' >>  ~/.bashrc
                        exec 2>/dev/tty 3>/dev/tty
                        echo "Done. Please launch the script again by typing 'ssl' into the terminal"
                        exec 2>/dev/null 3>/dev/null
                        exit 0
                fi
        fi
    touch "$sslFileDirectory"/Domain-List
    sed -i "/isFirstStartup=/c\isFirstStartup=false" "$savePath"/ssl-script.sh
fi
clear
cd "$savePath" || exit
echo -e "┌─────────────────────────────────────────────────────────────┐"
echo -e "│ Please enter:                                               │"
echo -e "│  [\e[36m1\e[39m] to add a domain to the list                │"
echo -e "│  [\e[36m2\e[39m] to search a certain domain                 │"
echo -e "│  [\e[36m3\e[39m] to manually create the files               │"
echo -e "└─────────────────────────────────────────────────────────────┘"

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
        read -rp "[Y]es / [N]o: [Y]" createConfirm
        if [ "$createConfirm" = Y ] || [ "$createConfirm" = y ]
            then
                selFqdn=$( { cat "$fqdn/$fqdn-ssl-info.txt" | grep -Pom 1 '\*FQDN.+' | cut -c 23-; } 2>&1)
                selCountry=$( { cat "$fqdn/$fqdn-ssl-info.txt" | grep -Pom 1 '\*COUNTRY NAME.+' | cut -c 23-; } 2>&1)
                selState=$( { cat "$fqdn/$fqdn-ssl-info.txt" | grep -Pom 1 '\*STATE OR PROVINCE.+' | cut -c 23-; } 2>&1)
                selLocality=$( { cat "$fqdn/$fqdn-ssl-info.txt" | grep -Pom 1 '\*LOCALITY NAME.+' | cut -c 23-; } 2>&1)
                selCompany=$( { cat "$fqdn/$fqdn-ssl-info.txt" | grep -Pom 1 '\*COMPANY NAME.+' | cut -c 23-; } 2>&1)
                selOu=$( { cat "$fqdn/$fqdn-ssl-info.txt" | grep -Pom 1 '\*ORGANISATIONAL UNIT.+' | cut -c 23-; } 2>&1)
                selAdminEmail=$( { cat "$fqdn/$fqdn-ssl-info.txt" | grep -Pom 1 '\*ADMINISTRATIVE E-MAIL.+' | cut -c 23-; } 2>&1)
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
        echo -e "Wrong input, aborting..."
        exit 1
    ;;
esac

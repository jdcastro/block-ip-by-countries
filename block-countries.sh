#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# This script will block IP by country.
# ------------------------------------------------------------------------------
# @author:    Johnny A. De Castro <j@jdcastro.co>
# @license:   MIT License
# @version:   0.1
# Initial release: 2022-07-31
# ------------------------------------------------------------------------------


start(){
    check_root
    chech_ipset
    if $ISIPSET && $ISROOTUSER
    then
        selecttions "$1" "$2"
    fi

}

check_root(){
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root or try: sudo $0" 
        exit 1
    else 
        ISROOTUSER=true
    fi
}

chech_ipset() {
    if ! command -v ipset &> /dev/null
    then
        echo "*******************************************"
        echo "*         ipset could not be found        *"
        echo "*******************************************"
        echo "*           try installing ipset:         *"
        echo "*  On Debian base: apt install ipset -y   *"
        echo "*  On RedHat base: dnf install ipset -y   *"
        echo "*******************************************"
        exit 1
    else 
        ISIPSET=true
    fi    
}

selecttions(){
    case $1 in
        -h|--help)
            echo "Usage: $0 [OPTION]..."
            echo "Block IP address block's by countrie"
            echo "  -h, --help            show this help message and exit"
            echo "  -c, --country         country to block"
            echo "  -l, --list            list all ip blocked in a country"
            echo "  -r, --remove          remove all blocked ip in a country"
            exit 0
            ;;
        -c|--country)
            if [ -z "$2" ]
            then
                echo -e "Country name is required, for example: \n$0 -c ru"
                echo "you can see https://www.ipdeny.com/ipblocks/ for list of countries"
                exit 1
            fi
            COUNTRY=$2
            if ipset  list countrie-$COUNTRY | grep  "Name: countrie-$COUNTRY"; 
            then 
                ipset flush countrie-$COUNTRY
                # ipset destroy countrie-$COUNTRY; 
            else
                ipset create countrie-$COUNTRY hash:net
            fi
            for IP in $(wget --no-check-certificate -O - https://www.ipdeny.com/ipblocks/data/countries/$COUNTRY.zone)
            do
                ipset add countrie-$COUNTRY $IP
            done
            iptables -I INPUT   -m set --match-set countrie-$COUNTRY src -j DROP
            iptables -I FORWARD -m set --match-set countrie-$COUNTRY src -j DROP
            ;;
        -l|--list)
            if [ -z "$2" ]
            then
                echo -e "Country name is required, for example: \n$0 -l ru"
                echo "you can see https://www.ipdeny.com/ipblocks/ for list of countries"
                exit 1
            fi
            COUNTRY=$2
            ipset -L countrie-$COUNTRY
            exit 0
            ;;
        -r|--remove)
            if [ -z "$2" ]
            then
                echo -e "Country name is required, for example: \n$0 -r ru"
                echo "you can see https://www.ipdeny.com/ipblocks/ for list of countries"
                exit 1
            fi
            COUNTRY=$2
            ipset -X countrie-$COUNTRY
            exit 0
            ;;
        *)
            echo "Usage: $0 [OPTION]..."
            echo "Block countries by IP address"
            echo "try -h, --help, to get instructions"
            exit 0
            ;;
    esac
}
start "$1" "$2"
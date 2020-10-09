#!/bin/bash
# A menu driven shell script sample template
# https://bash.cyberciti.biz/guide/Menu_driven_scripts
## ----------------------------------
# Step #1: Define variables
# ----------------------------------
RED='\033[0;41;30m'
STD='\033[0;0;39m'

# ----------------------------------
# Step #2: User defined function
# ----------------------------------
pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

one(){
        echo "one() called"
        pause
}

# do something in two()
two(){
        echo "two() called"
        pause
}

three(){
        echo "three() called"
        pause
}

four(){
        echo "four() called"
        pause
}

five(){
        echo "five() called"
        pause
}

# function to display menus
show_menus() {
        clear
        echo "~~~~~~~~~~~~~~~~~~~~~"
        echo " M A I N - M E N U"
        echo "~~~~~~~~~~~~~~~~~~~~~"
        echo "1. Install WP Cloudflare Super Page Cache"
        echo "2. Install Autoptimize"
        echo "3. Install Flying Images"
        echo "4. Install Flying Scripts"
        echo "5. Install All"
        echo "6. Exit"
}
# read input from the keyboard and take a action
# invoke the one() when the user select 1 from the menu option.
# invoke the two() when the user select 2 from the menu option.
# Exit when user the user select 3 form the menu option.
read_options(){
        local choice
        read -p "Enter choice [ 1 - 6] " choice
        case $choice in
                1) one ;;
                2) two ;;
                3) three ;;
                4) four ;;
                5) five ;;
                6) exit 0;;
                *) echo -e "${RED}Error...${STD}" && sleep 2
        esac
}

# ----------------------------------------------
# Step #3: Trap CTRL+C, CTRL+Z and quit singles
# ----------------------------------------------
trap '' SIGINT SIGQUIT SIGTSTP

# -----------------------------------
# Step #4: Main logic - infinite loop
# ------------------------------------
while true
do

        show_menus
        read_options
done



  	#!/bin/bash
    
    if [[ $stack == cpanel ]]; then
 		screen -dmS cpanelinstall sh -c 'https://raw.githubusercontent.com/jcatello/bigscoots/master/bsi1-dedi.sh | bash'
  	fi

  	if [[ $stack == wpo ]]; then
  		screen -dmS wpoinstall sh -c 'curl -sL https://raw.githubusercontent.com/jcatello/bigscoots/master/bsi-nginx-dedi.sh | bash'
  	fi

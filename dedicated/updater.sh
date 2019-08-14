#!/bin/bash
######################################################
# cmupdate
# written by George Liu (eva2000) centminmod.com
######################################################
# variables
CM_INSTALLDIR='/bigscoots'
######################################################

fupdate() {
  if [[ -d "${CM_INSTALLDIR}/.git" ]]; then
#    if [[ "$(curl -sL https://github.com/centminmod/centminmod/raw/${branchname}/gitclean.txt)" = 'no' ]]; then
      cd "${CM_INSTALLDIR}"
      git stash
      git pull
    else
      rm -rf "${CM_INSTALLDIR}"
      cd /
      git clone https://github.com/jcatello/bigscoots
    fi
}
######################################################
fupdate

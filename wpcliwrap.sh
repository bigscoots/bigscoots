#!/bin/bash

/usr/local/bin/wp --allow-root "$@"
sleep 1
cowsay -nf "ghostbusters" If you ran me as root please check file ownership

#!/bin/bash

grep -v "FTP Passive" centminmod_123.09beta01.b063_081018-143346_wordpress_addvhost.log | grep -C2 "FTP mode"

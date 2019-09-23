#! /bin/bash

if [[ ! -f /root/.ssh/authorized_keys ]]; then

mkdir -p /root/.ssh
touch /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

fi

wponexus='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrhMe1Ld+wFXEhpXzjspZOHywCpp0DLw1Qx89oOofp1XGPoDf3G/1iT/OnrC+51hrNwope715EOab7Jd5fYTOSg08G0Tzxd44SSDpkC9OTdsQc0D2sFzWfM5LFdIFomwmT0hCzwhZkZqVNDWYPwOrtjpL+x1YGOs5+JE1WjE9cHSPvowL62P5T6Y56VQUIxtdy08SJX/IXazSzd8VWfbwCBsSPLccwk5+JbCmJXtvRTW37Nxao+oDuaT+vsbso6VnOB0PJusx0CgdyPH1+b4XfNOuaO/wAPvD6akGhkGbmjBxLxBrf1kpx7MEpaLmjPHiD0mKJgTf05weVAKygppTKhT4DE37349jbBFLLVDWrTOMeRLDQr3jYIGhwUSTA4z8+a1QM9pxb7UTN9afZ4Gn/mfqSSdw8meEYTnBSeyqF4XzeC0rN+n06uYiobdzXMB6CQ9+SbPwTovpvU/2oyz9/R1jk3oR+FzwvOUdbmxsUsXCR0pBA3BHiB+L/MKF1X68Ig1y8jyHVLzwQaLom8Xd43j8WjYZn+cegIqn8SWGNEBQmQ5Y48DI8+o4TNTE+qvsUitF1qQa3ct4nJThz5D/9MWMyuh4M7ul6Vwgd0NqrX29k3NlRY5+sAH7P83Ct6/+aTXjRtLVTY6gzlzJi4UzEiZJUacYVa4WNloLJFunacQ== root@wpo.wpo-nexus.bigscoots.com'
office01='ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAn+cOO+QgKiuntfsPmJ8NtUsGNmOlT3LKjRhR3Yk9paGYul/f+A0wP0YBp/ANpNPUeKO7TqTnyzL8PIpCUXOyJ5Nsoo2X3Bv2jERXj54qzX5BD8cDwLJ8ACIIy9O0tmG9vycAqE0JApEsgfeUN8NVe3uaVhdjfPZMgGhBZZvZavFFqdRkeDcLXhw+fuBQpN3inELYU2YVeR6XOYcavU0zFAC7zbhaS3x71xmXHfyVueJRsBUzrFu56Yag4XrcIopvoGy2SHX929SG34wa5tCtfpdkinxJpru/9fmKKJKMMEW49VS0cOC2dFjm67zR+RoTsyhG6QCLPIPwjDJry9JZ3bZ4YI74J+TXsjB7b1k33Vqcd2hIVJ3phhcWQiQ8sfoUMZQfWr6F1s1+Q2N+8G7l6rdMheLemzqH+ZKFC0QxhNei4qLFVDfVds7HnODn7V7kaG07ge0usN9P604vgVp33mtD0dsOzNAW21EBTjurDIu/akbYqUBBPPhDvlWotYylY9+o6rQyyVtrcBARr3mbAkZdrIpjLyOlXb/ZoLzl3b1ciBV+WmwaJwdYzQqiXDCz4W8zH4RwJFaBa6StPlF7Xau6g1Dnzd2UjtUmft+ciQNHzPqUnwG4V41kvqu3hhM8usGlSMGUa8wX1RWj/ZkpuMOeaamBzVbaIbn9UsKuBhk= rsa-key-20161116'
office02='ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAx/wguQjxQ/h3JD6Tit6hHvXZFszRnQQMMVOEIvn0WUxk1+O6VSKu1soc9E+gLg1PK8tUesgFyluRAjewyR8JTbBiP5ZCDddt2wyuBV8qEtJV7og96gzqABp28CY54f0ER8JBF7dtB1cjawliL0CquiJnBhWO4Q4VbBTr/EXZghPtWJKHGBwX7ziZKxcsSpJfrCbYbU1caUkOjkHSNdnKX6KhHK6pCaL8b27sDBwqZrv+YGfheQXnXjiEGW8/oJ8mSP6mawVlxFocGCZtfrjKsr5zDREalLmOAdXsFw/evID95tqyRZt4V5eirvtCA5P1N7+6oTDJ2XvCkjUtHSrzHXXZ5z6UkTJqCaqC3bRVbxVRkFWjxYqLBZe8YTBzwOoUXVhP2kYPxz97hKhblhHWpO5R1GtT0ragVdjeXxtLWgs2eTqmGQat4x4PxeEAUOjxeY48UBMRG50XCHkdVylZrgwaDBr1IV3lCZc8BtDJKT1QKygIZkHVQfaqfvtQ1oFB6Nx5SNzJ7mHvmIQvaj+tWSOTBdIny6DO2RhPCJBz3UNUDUuul9mw1j5Gsv0VvudFDz4DxOjGUlk519KoeNyRvBuDRwVb51HUGX/4lykHfaG7KMmy6V35JGEzna4Voy6VVQr2xp2eNYlbw15UcFfA1BXRWaPmYiNGeDXvWn8QZ/k= rsa-key-20170802'
office03='ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAjOtX/QuK+gv+yxQRvCRe3gFDvCR3qmjByRAbDq8I3FKBNLMUpDARMea8ISR/D/xgD1s30WWCXTtUQK9Qem0XSYSn9qdaKp30f7j5APfoL8bAect0i4XR/RpJBTbuH1Mt1WMaqKB5w8cuo7Rwo3dRE7iUZKlSjJFpofQ+hKAWFdnu82MgmetzbQtvR2Ta1ymLul2LK3bluy0tovyB4cWEFGFUwayK999tEvXJ3+T3PxEonVSUS2Ay3xfXJwK+yIigU/MQqf72bKlMRhGEuLnozlYwm5y97qJFKPIDSp4YN8ztmBeKLTBvQkSD32HctxKY4z2BzTev7Ip1Xhil6DDPY7Y/PoQwQ+xBP6jk6OpJud5P49lHIT16obkSW9L8fD5SHT+Ov7AJv0/cclY2VBbJBPKjCy5q+qeiVMSbGkAcRLp40UTTtWkFP6nmWjfPK1sytco5dy1GhoC6mwPrwLmq+mvMpa721NVpcw25/G7o7zXBXZ56i/7ImqlqwCa4/VNEioabhvM3zODLOfbqDXMeZVwIOAoshmAhGYLCm/+OdTi+J+D0+ub6k7EVze3h5/0c4rDYOib62Urp/G3ZUDSakLUj8KhyNLc5UaFbfQPD5ePiw2KQ9qO83Ikkt90oHjFQwW+vu8ribYgEsR/0qk8qTjFL8GYXRsRmqJaMyRFz18U= rsa-key-20170802'
office04='ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEA8Drkz4YtC2FOTYX3iBfkHcPTUoZm39ps3chvK/4jv5wdDtWPeVsPQ0/fmJDSCMqZ85ayuL0d6f7OhxJrhJvqE+AmVpx81O4BGSyjuWISTGg0AwMosNm4gEI8Tms4mP10iHA0nQL90OUYN3uFkp2a3/79bvYnJ2uHl2Sb50ygNOHnRGfds7FcembUCpGkitUqp+BRbRmGB1YFyT4NM+gvYhvdDyuZXgh37ReZpNKPLsqhBdpZOH57b708QUKltw0tLmbOD4e54i1mcyAmg60LZmVMJPfHUegUrb1SdCMCKuA+SKrzymdtCL38q4JmKbaNDc+F/evdfQhuh3fIrRcnMsY0PIf6CYFyVRidWafUCH3f0wTJYKwIOe8qIudEMULn8R1/6MmT4oQBy7NIe/UY7g+BzbXiuBXGgzEZIiyD8vCJym4XcCSL7heFR4Fe4mac1YjDQKoaV2reMbW6CcLGtIZyXnP2/xGWZxouQXr3OM/CAOX9fFxHIIj6OwabxugJu+uPmz+xty77U5YuRWiy73zWAftTZbMHfY187d6Q7KFVgxa3AWDZNYvKlv4vR3l2LOayNYG0Y6mxBkPGRfUnTXfxzYFSniieMPwCpxPyHRdAG68I1VLPd4dF7cZxu+UMJKSc1GfHew+ViResmExunCYCQGRVw3TO/Z+0a6MYWyE= dean'
office05='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGYqBDuXSS1yNjJWLilLFGTm/3+fxV7qz6JF1rSKEmNbW6wymmjIkBoVBzSxtQ5Dl3nZ7ELqAgHgAaFokrgJVootxYCY6dfH0JDc2fM5aCPo3fVzlrJqZA4TX7d0s6VcxQ1D1MDz75Rf8avLpvVkcrTWFO5gtNHbbhpG3LwU72EZdtZhevxT19XY4jotEc+iH6TSTlnGgoQlUzhbOkQ4o5SQZmdMCy4R0Zl3oyb0/VwOE89BLvHmnYOApRIsqS6lO/SI+Ifkez3tkzc8DBQcB0x8LGoKkbSJzx41fQAEPAP9WzNJ33hZSaxfKNTHY+D4qBfsxCkr0oNbESfoBENolKxwdG1c2TpJMS1Kx7sHHAAriS0HT72u4zz3cm5vyJm4Nh+KB+g2ECvE6qkGgHb6sZLUV0SH7JRUh6Zp8Wvy2nVM8GRtxSXdt5D/Vtp7cokd02g8l9bVBM3V3smn6mZyejR4wn6DKbQ2BTb4FgbA+CJoLIlZ+V0O+f1M9VnPrwTEX6AiW7own7Tp3YUQMJvSQcY+3lTgGOQY8J4yJTFokk8+H1UOzeFVtf6Wu/oSId39lqa2hvxdQsJ5NynIW1poMv8gX/R/UzPz5aWJq+XaRcSOANzjHsHoTcsMlS2cw0nivmDczkyV+mqYmQ664jBeBHVkEtmz80pC3iIvyWnMCO1Q== NathanLopez'
office06='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDA/foTZ8x3DuXczqI3e7S2gU3dhxVKey+bZrq5jYqJ8iS3iEniTgta9TjnzD5zWVLx0ESLdWeA+2v/fBC0q/vjBNsIEsb0DIjssuOiYHmjrCp2TJEJCUhmp7rI+2v471SZAtRoQJ5r6KWyzt1eSD550af08rd37m05VxdXAaJuKa8+zU3n+mZeS7Kg//N6jnvmhAgnAPoBIJ7nSmPozm0yuPXImU9FZ+BUyW9qJcwYQ0EcMhZ30Vncimg0jJYF8zjgIy3Sx13//NE3EnI20bIeuA+s4DhGrgZRMocQFALPzDtzMUxAbyhWsUstKtAbk/VGTbNc2JxpC9iTki9sfl/LujXmIX/Out+KnnP5gCgi4mGLivfEdydvQ0MVagZGNu9bGaphGt45p8cGU3g2UkNaUOfvLrBw6e2GJNdL6dAYsLAFH93dFWvZRAhaQzpwX14WUAi809yjy6Dp5bOBn+vPZCMhDArzKZNOEjiQxiRr8+o7oA4o6QejZFjIHpmf9a37HjKsKAjm0Ijf5/xj4918xYPIWwUPqLEFx8gOvcVCVbfM6pDw5K820fXiCTapfKasyHNJEyBHrFYAUI4WhJacd/jOwapXie/ieTue4ePykQm6wv96n2gkz0qphQwKrxdc2DXkBSpTqgWPxlqAmpLLCzFghA8RmXmvG0+Y7dcO2Q== prasulsurendran@Prasuls-MacBook.local'

if grep -q tim@localhost.localdomain ~/.ssh/authorized_keys; then

	sed -i '/tim@localhost.localdomain/d ; /Office 4 - BigScoots.com/d' ~/.ssh/authorized_keys
fi

if grep -q bassu@Thunderstorm ~/.ssh/authorized_keys; then

	sed -i '/bassu@Thunderstorm/d ; /Office 5 - BigScoots.com/d' ~/.ssh/authorized_keys
fi

# add

if ! grep -q "${wponexus}" ~/.ssh/authorized_keys; then

	echo "# WPO NEXUS - BigScoots.com" >> ~/.ssh/authorized_keys
	echo from=\"67.202.70.147\" "${wponexus}" >> ~/.ssh/authorized_keys
fi

if ! grep -q "${office01}" ~/.ssh/authorized_keys; then
	echo "# Office 1 - BigScoots.com" >> ~/.ssh/authorized_keys
	echo "${office01}" >> ~/.ssh/authorized_keys
fi

if ! grep -q "${office02}" ~/.ssh/authorized_keys; then
	echo "# Office 2 - BigScoots.com" >> ~/.ssh/authorized_keys
	echo "${office02}" >> ~/.ssh/authorized_keys
fi

if ! grep -q "${office03}" ~/.ssh/authorized_keys; then
	echo "# Office 3 - BigScoots.com" >> ~/.ssh/authorized_keys
	echo "${office03}" >> ~/.ssh/authorized_keys
fi

if ! grep -q "${office04}" ~/.ssh/authorized_keys; then
	echo "# Office 4 - BigScoots.com" >> ~/.ssh/authorized_keys
	echo "${office04}" >> ~/.ssh/authorized_keys
fi

 if ! grep -q "${office05}" ~/.ssh/authorized_keys; then
	echo "# Office 5 - BigScoots.com" >> ~/.ssh/authorized_keys
	echo "${office05}" >> ~/.ssh/authorized_keys
 fi

 if ! grep -q "${office06}" ~/.ssh/authorized_keys; then
	echo "# Office 6 - BigScoots.com" >> ~/.ssh/authorized_keys
	echo "${office06}" >> ~/.ssh/authorized_keys
 fi
 
if command -v csf >/dev/null 2>&1 ; then
 
 unset csfrb
 
  if ! grep -q 208.117.38.23 /etc/csf/csf.allow; then
	echo "208.117.38.23 # office4.bigscoots.com" >> /etc/csf/csf.allow
	csfrb=1
 fi
 
   if ! grep -q 69.162.134.47 /etc/csf/csf.allow; then
	echo "69.162.134.47 # office5.bigscoots.com" >> /etc/csf/csf.allow
	csfrb=1
 fi
 
   if ! grep -q 208.117.38.157 /etc/csf/csf.allow; then
	echo "208.117.38.157 # office3.bigscoots.com" >> /etc/csf/csf.allow
	csfrb=1
 fi
 
   if ! grep -q 50.31.114.76 /etc/csf/csf.allow; then
	echo "50.31.114.76 # office2.bigscoots.com" >> /etc/csf/csf.allow
	csfrb=1
 fi
 
   if ! grep -q 208.117.38.38 /etc/csf/csf.allow; then
	echo "208.117.38.38 # office.bigscoots.com" >> /etc/csf/csf.allow
	csfrb=1
 fi
 
   if ! grep -q 208.117.38.24 /etc/csf/csf.allow; then
	echo "208.117.38.24 # office6.bigscoots.com" >> /etc/csf/csf.allow
	csfrb=1
 fi

if [ "${csfrb}" == 1 ]; then
$(command -v csf) -ra
fi

fi

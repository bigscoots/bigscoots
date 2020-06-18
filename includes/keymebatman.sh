#!/bin/bash

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib64/ccache:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/root/bin"

if [[ ! -f /root/.ssh/authorized_keys ]]; then

mkdir -p /root/.ssh
touch /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

fi

wponexus='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrhMe1Ld+wFXEhpXzjspZOHywCpp0DLw1Qx89oOofp1XGPoDf3G/1iT/OnrC+51hrNwope715EOab7Jd5fYTOSg08G0Tzxd44SSDpkC9OTdsQc0D2sFzWfM5LFdIFomwmT0hCzwhZkZqVNDWYPwOrtjpL+x1YGOs5+JE1WjE9cHSPvowL62P5T6Y56VQUIxtdy08SJX/IXazSzd8VWfbwCBsSPLccwk5+JbCmJXtvRTW37Nxao+oDuaT+vsbso6VnOB0PJusx0CgdyPH1+b4XfNOuaO/wAPvD6akGhkGbmjBxLxBrf1kpx7MEpaLmjPHiD0mKJgTf05weVAKygppTKhT4DE37349jbBFLLVDWrTOMeRLDQr3jYIGhwUSTA4z8+a1QM9pxb7UTN9afZ4Gn/mfqSSdw8meEYTnBSeyqF4XzeC0rN+n06uYiobdzXMB6CQ9+SbPwTovpvU/2oyz9/R1jk3oR+FzwvOUdbmxsUsXCR0pBA3BHiB+L/MKF1X68Ig1y8jyHVLzwQaLom8Xd43j8WjYZn+cegIqn8SWGNEBQmQ5Y48DI8+o4TNTE+qvsUitF1qQa3ct4nJThz5D/9MWMyuh4M7ul6Vwgd0NqrX29k3NlRY5+sAH7P83Ct6/+aTXjRtLVTY6gzlzJi4UzEiZJUacYVa4WNloLJFunacQ== root@wpo.wpo-nexus.bigscoots.com'
office00='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC21mTrTpLljBUkLdFO0pOz3M26sI/fggu8d05LpnW8SJnu6lioIyU8BwqLo3z3PPVJxj66NQUpFGwwV0vExS8p8cB3oBQ3h2vRnyTpbv8gtAQl2+BUdxp4k2PMEP3zfHEyDj4ihubM5Mzxne+I+AxIoUy3884OKI4tJetCD2LL9MxcHFebTpQXqIX30oibDtQgnXeG1TSwl2octexpPdAYeYFoMwuWaK36bDJaZOYoiG/1OTPGfngPhcOS5R8Y5c+ixZXive7N+0FXuD6xdGigYvQ2VwfMhk+D4APNuTCCeOHBz11PyOVFLGzC0KDQTFHWbMr2kzHuNbGxv/PW4BhBKPQatLXal8xW8FAJjJi12RqLQTNCdRnUcKRcP4/0Iv+kyWhXlBJOyTVHSA0UPjm/Hel0hVDh/Cp8ih2Mtvud97wJAFKyRgreauDxC7J3WRbMTvwJNi6fdFOhoW8wproCsmZMHsc+DNH1yilf+w3BSbi226YiRCk3INyhGaUIGFCs22MC0XJa5VuejZEyxzum2cuyWfLhEL9ZHxyHC6wsGgU/VLHlknDyIOmZDKJB2xVdfpqcvHgvSKoKfMG3UXsVQXY0Yqz8KcPw2IRMUBumxXZCAExLPl4SKWStYRMVCyeNFQ+0Gp5twWNOotCjMHfozJXnIWco3Kd7CnS5SWlLNw== BigScoots Office 00'
office01='ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAn+cOO+QgKiuntfsPmJ8NtUsGNmOlT3LKjRhR3Yk9paGYul/f+A0wP0YBp/ANpNPUeKO7TqTnyzL8PIpCUXOyJ5Nsoo2X3Bv2jERXj54qzX5BD8cDwLJ8ACIIy9O0tmG9vycAqE0JApEsgfeUN8NVe3uaVhdjfPZMgGhBZZvZavFFqdRkeDcLXhw+fuBQpN3inELYU2YVeR6XOYcavU0zFAC7zbhaS3x71xmXHfyVueJRsBUzrFu56Yag4XrcIopvoGy2SHX929SG34wa5tCtfpdkinxJpru/9fmKKJKMMEW49VS0cOC2dFjm67zR+RoTsyhG6QCLPIPwjDJry9JZ3bZ4YI74J+TXsjB7b1k33Vqcd2hIVJ3phhcWQiQ8sfoUMZQfWr6F1s1+Q2N+8G7l6rdMheLemzqH+ZKFC0QxhNei4qLFVDfVds7HnODn7V7kaG07ge0usN9P604vgVp33mtD0dsOzNAW21EBTjurDIu/akbYqUBBPPhDvlWotYylY9+o6rQyyVtrcBARr3mbAkZdrIpjLyOlXb/ZoLzl3b1ciBV+WmwaJwdYzQqiXDCz4W8zH4RwJFaBa6StPlF7Xau6g1Dnzd2UjtUmft+ciQNHzPqUnwG4V41kvqu3hhM8usGlSMGUa8wX1RWj/ZkpuMOeaamBzVbaIbn9UsKuBhk= rsa-key-20161116'
office02='ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAjOtX/QuK+gv+yxQRvCRe3gFDvCR3qmjByRAbDq8I3FKBNLMUpDARMea8ISR/D/xgD1s30WWCXTtUQK9Qem0XSYSn9qdaKp30f7j5APfoL8bAect0i4XR/RpJBTbuH1Mt1WMaqKB5w8cuo7Rwo3dRE7iUZKlSjJFpofQ+hKAWFdnu82MgmetzbQtvR2Ta1ymLul2LK3bluy0tovyB4cWEFGFUwayK999tEvXJ3+T3PxEonVSUS2Ay3xfXJwK+yIigU/MQqf72bKlMRhGEuLnozlYwm5y97qJFKPIDSp4YN8ztmBeKLTBvQkSD32HctxKY4z2BzTev7Ip1Xhil6DDPY7Y/PoQwQ+xBP6jk6OpJud5P49lHIT16obkSW9L8fD5SHT+Ov7AJv0/cclY2VBbJBPKjCy5q+qeiVMSbGkAcRLp40UTTtWkFP6nmWjfPK1sytco5dy1GhoC6mwPrwLmq+mvMpa721NVpcw25/G7o7zXBXZ56i/7ImqlqwCa4/VNEioabhvM3zODLOfbqDXMeZVwIOAoshmAhGYLCm/+OdTi+J+D0+ub6k7EVze3h5/0c4rDYOib62Urp/G3ZUDSakLUj8KhyNLc5UaFbfQPD5ePiw2KQ9qO83Ikkt90oHjFQwW+vu8ribYgEsR/0qk8qTjFL8GYXRsRmqJaMyRFz18U= rsa-key-20170802'
office03='ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAsh2u0TtxQQ6eX4a+c/coweXrOOxEigTwVa+WIINv1ogiyGBwgpoN9h4lnZ7igxC0toq5k2xunJisiahvzLWjrrLRQNOcfZAEAg7yPwlobwIuQhTsIoHaPC0Ty2DBxwffm6OHKa2cUnZCebaNAEFasXJ5HtgCQ6IYLh9wT8FC3HwHo8lSfLqb6NQHpU9c4PZ7nO0AbCs5dIqcpRgkDkBLAWZpZpOs+8nnGVThyT9tv8RN+YPB/QQ6qgp8I+ixzq9MdLJpfEE6z+4okbpNbtDyFWMwIUi1ltMHVoGdv8hytRBcZcQsjKU8iZeM06IOGTYo8XnhrdTQEIwvSxm28YSXuw== rsa-key-20200213'
office04='ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEA8Drkz4YtC2FOTYX3iBfkHcPTUoZm39ps3chvK/4jv5wdDtWPeVsPQ0/fmJDSCMqZ85ayuL0d6f7OhxJrhJvqE+AmVpx81O4BGSyjuWISTGg0AwMosNm4gEI8Tms4mP10iHA0nQL90OUYN3uFkp2a3/79bvYnJ2uHl2Sb50ygNOHnRGfds7FcembUCpGkitUqp+BRbRmGB1YFyT4NM+gvYhvdDyuZXgh37ReZpNKPLsqhBdpZOH57b708QUKltw0tLmbOD4e54i1mcyAmg60LZmVMJPfHUegUrb1SdCMCKuA+SKrzymdtCL38q4JmKbaNDc+F/evdfQhuh3fIrRcnMsY0PIf6CYFyVRidWafUCH3f0wTJYKwIOe8qIudEMULn8R1/6MmT4oQBy7NIe/UY7g+BzbXiuBXGgzEZIiyD8vCJym4XcCSL7heFR4Fe4mac1YjDQKoaV2reMbW6CcLGtIZyXnP2/xGWZxouQXr3OM/CAOX9fFxHIIj6OwabxugJu+uPmz+xty77U5YuRWiy73zWAftTZbMHfY187d6Q7KFVgxa3AWDZNYvKlv4vR3l2LOayNYG0Y6mxBkPGRfUnTXfxzYFSniieMPwCpxPyHRdAG68I1VLPd4dF7cZxu+UMJKSc1GfHew+ViResmExunCYCQGRVw3TO/Z+0a6MYWyE= dean'
office05='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGYqBDuXSS1yNjJWLilLFGTm/3+fxV7qz6JF1rSKEmNbW6wymmjIkBoVBzSxtQ5Dl3nZ7ELqAgHgAaFokrgJVootxYCY6dfH0JDc2fM5aCPo3fVzlrJqZA4TX7d0s6VcxQ1D1MDz75Rf8avLpvVkcrTWFO5gtNHbbhpG3LwU72EZdtZhevxT19XY4jotEc+iH6TSTlnGgoQlUzhbOkQ4o5SQZmdMCy4R0Zl3oyb0/VwOE89BLvHmnYOApRIsqS6lO/SI+Ifkez3tkzc8DBQcB0x8LGoKkbSJzx41fQAEPAP9WzNJ33hZSaxfKNTHY+D4qBfsxCkr0oNbESfoBENolKxwdG1c2TpJMS1Kx7sHHAAriS0HT72u4zz3cm5vyJm4Nh+KB+g2ECvE6qkGgHb6sZLUV0SH7JRUh6Zp8Wvy2nVM8GRtxSXdt5D/Vtp7cokd02g8l9bVBM3V3smn6mZyejR4wn6DKbQ2BTb4FgbA+CJoLIlZ+V0O+f1M9VnPrwTEX6AiW7own7Tp3YUQMJvSQcY+3lTgGOQY8J4yJTFokk8+H1UOzeFVtf6Wu/oSId39lqa2hvxdQsJ5NynIW1poMv8gX/R/UzPz5aWJq+XaRcSOANzjHsHoTcsMlS2cw0nivmDczkyV+mqYmQ664jBeBHVkEtmz80pC3iIvyWnMCO1Q== NathanLopez'
office06='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDA/foTZ8x3DuXczqI3e7S2gU3dhxVKey+bZrq5jYqJ8iS3iEniTgta9TjnzD5zWVLx0ESLdWeA+2v/fBC0q/vjBNsIEsb0DIjssuOiYHmjrCp2TJEJCUhmp7rI+2v471SZAtRoQJ5r6KWyzt1eSD550af08rd37m05VxdXAaJuKa8+zU3n+mZeS7Kg//N6jnvmhAgnAPoBIJ7nSmPozm0yuPXImU9FZ+BUyW9qJcwYQ0EcMhZ30Vncimg0jJYF8zjgIy3Sx13//NE3EnI20bIeuA+s4DhGrgZRMocQFALPzDtzMUxAbyhWsUstKtAbk/VGTbNc2JxpC9iTki9sfl/LujXmIX/Out+KnnP5gCgi4mGLivfEdydvQ0MVagZGNu9bGaphGt45p8cGU3g2UkNaUOfvLrBw6e2GJNdL6dAYsLAFH93dFWvZRAhaQzpwX14WUAi809yjy6Dp5bOBn+vPZCMhDArzKZNOEjiQxiRr8+o7oA4o6QejZFjIHpmf9a37HjKsKAjm0Ijf5/xj4918xYPIWwUPqLEFx8gOvcVCVbfM6pDw5K820fXiCTapfKasyHNJEyBHrFYAUI4WhJacd/jOwapXie/ieTue4ePykQm6wv96n2gkz0qphQwKrxdc2DXkBSpTqgWPxlqAmpLLCzFghA8RmXmvG0+Y7dcO2Q== prasulsurendran@Prasuls-MacBook.local'
office07='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCsoQVmf5kaXDV2nmG6RT5NLJ0+k8TFsNPFhLNm4r8D0chIXWCLjkAbUVGt3+k9GlGT2OWafYtKBq92YFgaTPnxAWI844Ya8NHhExJqQlzi+TiqdUozZFTIUpVlN/9Fk6f207fGacnfDh6JAkCtCkH9Yh7mbByvY2SzmiktbFLgnRaorVqLui6JzpYjsbHqIhcZ+cYSn/pjlXGgRwupDhr0UJ1sv72qLBTuvRMjh0eaNui+dIxKdoVd59NRIryuikBMMIFxs5OHAund4Arp5+Pdi+IB9Bt92GPPl9GKzDv7rAVVq0gBAfeWj0lfLPSoh1jVuec+IVvixQGzDV1u0R/EkKr0s/dm6DNrLAWs8i6uIesDpVt+79QV1DG3Yfa+VNtouL75msRbXUHyhVQYG5EP40fjfdiwMcIz6cLxh8yG4b9TK4h6tWneELhcjOZ74HDhiwrfq7L+8ut3DEGQDz8kj1IJvcXKISIKi3iUn9aq1YOLEc7HF274ZvwpT3pw2I+QDMqcegTPF4Un+fk7u4VFr1qjkXHQ5pEqKtdHwX9ULkHWwCSxlETToJgz5X/DjmnHog2VwSU4AvE7AuIdip465ykBWgiE8zI8DbCjZLAY/9VZuyr2gJBU+XeQh/hQZBA4vAYCfA+VSbaXaEN68ULDZEiZFgKBHj5HvS+QH4t1tQ== root@office7.bigscoots.com'
office08='AAAAB3NzaC1yc2EAAAABJQAAAQEAshrS5qT6GvSkOF7FZKW7ByEuoycWDKnp7rsDOmmPgeSze1mMbPiNYgcub169sfWrZzPpOUnfhPJq7fQQbSect8G2H2M1v8mk8lVEBfhYHZ+COR0AnKAMHG6faP+i+tEFMjFvvg1+m0mbdMST0u3Js2oRswVwj+wIiZcg5VX9EaliWvYJ8uY7Ml40kMB97NoL/S6PUFQ4KEGo+5Y1YBCVVJir7pH3pLpFZVtDbNG9pJa2azEG0laKGKLCwEvZjrvIHa4YBFJYL0eyJeEeqS1b1VQNY1SdVeAfY9tjPa5vI2dO8lmhRWoy6cYS6yedmL5/I9C+QB2WUfzkFHQe+pCIhw== andy'


if grep -q tim@localhost.localdomain ~/.ssh/authorized_keys; then

	sed -i '/tim@localhost.localdomain/d ; /Office 4 - BigScoots.com/d' ~/.ssh/authorized_keys
fi

if grep -q bassu@Thunderstorm ~/.ssh/authorized_keys; then

	sed -i '/bassu@Thunderstorm/d ; /Office 5 - BigScoots.com/d' ~/.ssh/authorized_keys
fi

if grep -q h3JD6Tit6hHvXZFszRnQQMMVOEIvn0WUxk1+O6VSKu1soc9E+gLg1PK8tUesgFyluRAjewyR8JTbBiP5ZCDddt2wyuBV8qEtJV7og9 ~/.ssh/authorized_keys; then

	sed -i '/h3JD6Tit6hHvXZFszRnQQMMVOEIvn0WUxk1+O6VSKu1soc9E+gLg1PK8tUesgFyluRAjewyR8JTbBiP5ZCDddt2wyuBV8qEtJV7og9/d' ~/.ssh/authorized_keys
fi

# add

if ! grep -q "${wponexus}" ~/.ssh/authorized_keys; then

	echo "# WPO NEXUS - BigScoots.com" >> ~/.ssh/authorized_keys
	echo from=\"67.202.70.147\" "${wponexus}" >> ~/.ssh/authorized_keys
fi

if ! grep -q "${office00}" ~/.ssh/authorized_keys; then
	echo "# Office 00 - BigScoots.com" >> ~/.ssh/authorized_keys
	echo "${office00}" >> ~/.ssh/authorized_keys
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

 if ! grep -q "${office07}" ~/.ssh/authorized_keys; then
	echo "# Office 7 - BigScoots.com" >> ~/.ssh/authorized_keys
	echo "${office07}" >> ~/.ssh/authorized_keys
 fi

  if ! grep -q "${office08}" ~/.ssh/authorized_keys; then
	echo "# Office 8 - BigScoots.com" >> ~/.ssh/authorized_keys
	echo "${office08}" >> ~/.ssh/authorized_keys
 fi
 
if command -v csf >/dev/null 2>&1 ; then
 
 unset csfrb
 
   if ! grep -q 67.202.70.147 /etc/csf/csf.allow; then
	echo "67.202.70.147 # WPO NEXUS - BigScoots.com" >> /etc/csf/csf.allow
	csfrb=1
 fi
 
   if ! grep -q 50.31.98.10 /etc/csf/csf.allow; then
	echo "50.31.98.10 # Monitor - BigScoots.com" >> /etc/csf/csf.allow
	csfrb=1
 fi
 
   if ! grep -q 208.117.38.27 /etc/csf/csf.allow; then
	echo "208.117.38.27 # office00.bigscoots.com" >> /etc/csf/csf.allow
	csfrb=1
 fi
 
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

    if ! grep -q 50.31.30.56 /etc/csf/csf.allow; then
	echo "50.31.30.56 # office7.bigscoots.com" >> /etc/csf/csf.allow
	csfrb=1
 fi

     if ! grep -q 50.31.119.27 /etc/csf/csf.allow; then
	echo "50.31.119.27 # office08.bigscoots.com" >> /etc/csf/csf.allow
	csfrb=1
 fi

 
if [ "${csfrb}" == 1 ]; then
$(command -v csf) -ra
fi

fi

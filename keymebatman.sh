#!/bin/bash

for i in $(vzlist | grep -v CTID | awk '{print $1}') ; do  

if [[ ! -f /vz/root/"$i"/root/.ssh/authorized_keys ]]; then

mkdir -p /vz/root/"$i"/root/.ssh
touch /vz/root/"$i"/root/.ssh/authorized_keys
chmod 700 /vz/root/"$i"/root/.ssh/authorized_keys
chmod 600 /vz/root/"$i"/root/.ssh/authorized_keys

fi

# echo "# WPO NEXUS - BigScoots.com" >> /vz/root/"$i"/root/.ssh/authorized_keys
# echo from=\"67.202.70.147\" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrhMe1Ld+wFXEhpXzjspZOHywCpp0DLw1Qx89oOofp1XGPoDf3G/1iT/OnrC+51hrNwope715EOab7Jd5fYTOSg08G0Tzxd44SSDpkC9OTdsQc0D2sFzWfM5LFdIFomwmT0hCzwhZkZqVNDWYPwOrtjpL+x1YGOs5+JE1WjE9cHSPvowL62P5T6Y56VQUIxtdy08SJX/IXazSzd8VWfbwCBsSPLccwk5+JbCmJXtvRTW37Nxao+oDuaT+vsbso6VnOB0PJusx0CgdyPH1+b4XfNOuaO/wAPvD6akGhkGbmjBxLxBrf1kpx7MEpaLmjPHiD0mKJgTf05weVAKygppTKhT4DE37349jbBFLLVDWrTOMeRLDQr3jYIGhwUSTA4z8+a1QM9pxb7UTN9afZ4Gn/mfqSSdw8meEYTnBSeyqF4XzeC0rN+n06uYiobdzXMB6CQ9+SbPwTovpvU/2oyz9/R1jk3oR+FzwvOUdbmxsUsXCR0pBA3BHiB+L/MKF1X68Ig1y8jyHVLzwQaLom8Xd43j8WjYZn+cegIqn8SWGNEBQmQ5Y48DI8+o4TNTE+qvsUitF1qQa3ct4nJThz5D/9MWMyuh4M7ul6Vwgd0NqrX29k3NlRY5+sAH7P83Ct6/+aTXjRtLVTY6gzlzJi4UzEiZJUacYVa4WNloLJFunacQ== root@wpo.wpo-nexus.bigscoots.com >> /vz/root/"$i"/root/.ssh/authorized_keys

# echo "# Office 1 - BigScoots.com" >> /vz/root/"$i"/root/.ssh/authorized_keys
# echo ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAn+cOO+QgKiuntfsPmJ8NtUsGNmOlT3LKjRhR3Yk9paGYul/f+A0wP0YBp/ANpNPUeKO7TqTnyzL8PIpCUXOyJ5Nsoo2X3Bv2jERXj54qzX5BD8cDwLJ8ACIIy9O0tmG9vycAqE0JApEsgfeUN8NVe3uaVhdjfPZMgGhBZZvZavFFqdRkeDcLXhw+fuBQpN3inELYU2YVeR6XOYcavU0zFAC7zbhaS3x71xmXHfyVueJRsBUzrFu56Yag4XrcIopvoGy2SHX929SG34wa5tCtfpdkinxJpru/9fmKKJKMMEW49VS0cOC2dFjm67zR+RoTsyhG6QCLPIPwjDJry9JZ3bZ4YI74J+TXsjB7b1k33Vqcd2hIVJ3phhcWQiQ8sfoUMZQfWr6F1s1+Q2N+8G7l6rdMheLemzqH+ZKFC0QxhNei4qLFVDfVds7HnODn7V7kaG07ge0usN9P604vgVp33mtD0dsOzNAW21EBTjurDIu/akbYqUBBPPhDvlWotYylY9+o6rQyyVtrcBARr3mbAkZdrIpjLyOlXb/ZoLzl3b1ciBV+WmwaJwdYzQqiXDCz4W8zH4RwJFaBa6StPlF7Xau6g1Dnzd2UjtUmft+ciQNHzPqUnwG4V41kvqu3hhM8usGlSMGUa8wX1RWj/ZkpuMOeaamBzVbaIbn9UsKuBhk= rsa-key-20161116 >> /vz/root/"$i"/root/.ssh/authorized_keys

# echo "# Office 2 - BigScoots.com" >> /vz/root/"$i"/root/.ssh/authorized_keys
# echo ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAx/wguQjxQ/h3JD6Tit6hHvXZFszRnQQMMVOEIvn0WUxk1+O6VSKu1soc9E+gLg1PK8tUesgFyluRAjewyR8JTbBiP5ZCDddt2wyuBV8qEtJV7og96gzqABp28CY54f0ER8JBF7dtB1cjawliL0CquiJnBhWO4Q4VbBTr/EXZghPtWJKHGBwX7ziZKxcsSpJfrCbYbU1caUkOjkHSNdnKX6KhHK6pCaL8b27sDBwqZrv+YGfheQXnXjiEGW8/oJ8mSP6mawVlxFocGCZtfrjKsr5zDREalLmOAdXsFw/evID95tqyRZt4V5eirvtCA5P1N7+6oTDJ2XvCkjUtHSrzHXXZ5z6UkTJqCaqC3bRVbxVRkFWjxYqLBZe8YTBzwOoUXVhP2kYPxz97hKhblhHWpO5R1GtT0ragVdjeXxtLWgs2eTqmGQat4x4PxeEAUOjxeY48UBMRG50XCHkdVylZrgwaDBr1IV3lCZc8BtDJKT1QKygIZkHVQfaqfvtQ1oFB6Nx5SNzJ7mHvmIQvaj+tWSOTBdIny6DO2RhPCJBz3UNUDUuul9mw1j5Gsv0VvudFDz4DxOjGUlk519KoeNyRvBuDRwVb51HUGX/4lykHfaG7KMmy6V35JGEzna4Voy6VVQr2xp2eNYlbw15UcFfA1BXRWaPmYiNGeDXvWn8QZ/k= rsa-key-20170802 >> /vz/root/"$i"/root/.ssh/authorized_keys

# echo "# Office 3 - BigScoots.com" >> /vz/root/"$i"/root/.ssh/authorized_keys
# echo ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAjOtX/QuK+gv+yxQRvCRe3gFDvCR3qmjByRAbDq8I3FKBNLMUpDARMea8ISR/D/xgD1s30WWCXTtUQK9Qem0XSYSn9qdaKp30f7j5APfoL8bAect0i4XR/RpJBTbuH1Mt1WMaqKB5w8cuo7Rwo3dRE7iUZKlSjJFpofQ+hKAWFdnu82MgmetzbQtvR2Ta1ymLul2LK3bluy0tovyB4cWEFGFUwayK999tEvXJ3+T3PxEonVSUS2Ay3xfXJwK+yIigU/MQqf72bKlMRhGEuLnozlYwm5y97qJFKPIDSp4YN8ztmBeKLTBvQkSD32HctxKY4z2BzTev7Ip1Xhil6DDPY7Y/PoQwQ+xBP6jk6OpJud5P49lHIT16obkSW9L8fD5SHT+Ov7AJv0/cclY2VBbJBPKjCy5q+qeiVMSbGkAcRLp40UTTtWkFP6nmWjfPK1sytco5dy1GhoC6mwPrwLmq+mvMpa721NVpcw25/G7o7zXBXZ56i/7ImqlqwCa4/VNEioabhvM3zODLOfbqDXMeZVwIOAoshmAhGYLCm/+OdTi+J+D0+ub6k7EVze3h5/0c4rDYOib62Urp/G3ZUDSakLUj8KhyNLc5UaFbfQPD5ePiw2KQ9qO83Ikkt90oHjFQwW+vu8ribYgEsR/0qk8qTjFL8GYXRsRmqJaMyRFz18U= rsa-key-20170802 >> /vz/root/"$i"/root/.ssh/authorized_keys

# echo "# Office 4 - BigScoots.com" >> /vz/root/"$i"/root/.ssh/authorized_keys
# echo ssh-dss AAAAB3NzaC1kc3MAAACBAIYT7sboqZESdMYMCTti3TU7YxFTKlBTsYW0cpB+KnGSRN3pWBg7UuGqagtsA8Kjy7x0UC4n+xBT4qplIsfnO0xGAtYoQfC24R4CRgxzVK78SUx9SaBWEzC4SAhq8GF4rizCVQyAtUjTe7YYGliAVtQ+VhnsOopobJ7QTq9OPwbjAAAAFQDuwQe/Czor8p1a67LKvb4xdpBdmwAAAIAbE8p5D/7G7epAFi/c6SIAgQSi4HccXfVu2jGqJwhW3fr1kGsfigDmsu83vSDbnb++GU1ZfuhtrjDyHGReSR3A8nTrLhNWQWrCh9qiEqk+y1SsRksEAo+OAMkj1HyagU5oV5wBAYHS3uqp6irY8gBV7tOdRTeGT1LChT+Sx++BWQAAAIBHa1gvHIrWC03bmLAc52yMFlWSy9mRrdcUQ0qB9dnThSN7ReRHM7Bo1kbK8BrFXpNl5yLXCjLLwrCPe1e71z5gMRwCept8PPjFyX4BNlRYtj1Ox2LiePTHgMCnSYeyL1KRwEWhKRsYA2K8pdpoMs1KKwIB1c08jkegt1mqtpezZw== tim@localhost.localdomain >> /vz/root/"$i"/root/.ssh/authorized_keys

echo "# Office 5 - BigScoots.com" >> /vz/root/"$i"/root/.ssh/authorized_keys
echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhD+XoZMHAXrpcR8MBtR7SGCe4Ii5G/PIKhKt/0RviOmF8yLJ3k8/ePmhA00QFM0DIRycgu0EatAYbzbrv9opJq8BMIaP2mpIbIrHZHwsIUKmoXCTcTu9ogOAp1Ke6pBIDYWA68dT62qRs05GJ9eRFRWBz6ymRKLlsEYFUS90nb3cH97cd+ILZv3qEGGC0nyPeoXVcX5MlmIU/S74ldNvvi0yo1UEH9/sKcc25wzKWQ0dzzGp5lpex4075NlrhlrMWysfe05XKKNYuDf3A7FSwMsgsFl5fVRbHCwqq3U1pb0RoNcWuzV5L33bLgpE57+RY403vVL3BMgbMNQfJ4io5 bassu@Thunderstorm >> /vz/root/"$i"/root/.ssh/authorized_keys

done

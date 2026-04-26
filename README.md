# mstack
A Proxmox LXC Container made from Debian with Sonarr Radarr and SabNZBD 

LXC's are easier to deal with than docker... I just donmt want to juggle 4 different LXCs to get downloading going at the home lab... 


So Essentially this is a script. It will ask you for an LXC number and an IP address. From there it will create a debian LXC and Install the latest versions of SabNZBD Sonarr and Radarr.


Download this repo by goig into the /opt directory.


cd  /opt

and 

git pull https://github.com/sleeker/mstack.git

make the bootstrap executable 

chmod 777 bootstrap.sh


and ./bootstrap.sh


It will ask you for a lxcID and an IP address and away it goes. 


Update all packages by typing update.



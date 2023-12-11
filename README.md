# Script d'installation ruTorrent / Nginx Pour Debian 10/11

* Français, English
* Nécessite Debian 10/11 (64 bits) & un serveur fraîchement installé

* Inclus VsFTPd (ftp & ftps sur le port 21), Fail2ban (avec conf nginx, ftp & ssh)

Tiré du tutoriel de mondedie.fr
[Aide, support & plus si affinités à la même adresse !](http://mondedie.fr/)

**Auteur :** Ex_Rat

Merci aux contributeurs: Sophie, Spectre, Hardware, Zarev, SirGato, MiguelSam, Hierra, mog54

## Installation:
Multilingue automatique
```
# su -  ou  sudo su -

apt-get update && apt-get upgrade -y
apt-get install git lsb-release -y

cd /tmp
git clone https://github.com/lafouine022/rutorrent-bonobox
cd rutorrent-bonobox
# Français
chmod a+x bonobox.sh && ./bonobox.sh --fr
```
![caps1](https://raw.github.com/exrat/rutorrent-bonobox/master/files/caps_script01.png)

**Vous pouvez aussi forcer la langue de votre choix:**
```
# English
chmod a+x bonobox.sh && ./bonobox.sh --en
```

Pour gérer vos utilisateurs ultérieurement, il vous suffit de relancer le script

![caps2](https://raw.github.com/exrat/rutorrent-bonobox/master/files/caps_script02.png)

### Disclaimer
Ce script est proposé à des fins d'expérimentation uniquement, le téléchargement d’oeuvre copyrightées est illégal.

Merci de vous conformer à la législation en vigueur en fonction de vos pays respectifs en faisant vos tests sur des fichiers libres de droits.

### License
This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-nc-sa/4.0/)


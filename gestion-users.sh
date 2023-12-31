#!/bin/bash

################################################
# lancement gestion des utilisateurs ruTorrent #
################################################


# contrôle installation
if [ ! -f "$RUTORRENT"/"$HISTOLOG".log ]; then
	"$CMDECHO" ""; set "220"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"
	set "222"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"; "$CMDECHO" ""
	exit 1
fi

# message d'accueil
"$CMDCLEAR"
"$CMDECHO" ""; set "224"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"; "$CMDECHO" ""
# shellcheck source=/dev/null
. "$INCLUDES"/logo.sh

# mise en garde
"$CMDECHO" ""; set "226"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"
set "228"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"
set "230"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"
"$CMDECHO" ""; set "232"; FONCTXT "$1"; "$CMDECHO" -n -e "${CGREEN}$TXT1 ${CEND}"
read -r VALIDE

if FONCNO "$VALIDE"; then
	"$CMDECHO" ""; set "210"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
	"$CMDECHO" -e "${CBLUE}                          Ex_Rat - http://mondedie.fr${CEND}"; "$CMDECHO" ""
	exit 1
fi

if FONCYES "$VALIDE"; then
	# boucle ajout/suppression utilisateur
	while :; do
		# menu gestion multi-utilisateurs
		"$CMDECHO" ""; set "234"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
		set "236" "248"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" # Ajout utilisateur 1 = 236
		set "238" "309"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" # Suspendre utilisateur 5 = 244
		set "240" "311"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" # Rétablir utilisateur 6 = 246
		set "242" "254"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" # Edit password 2 = 238
		set "244" "256"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" # Supprimer utilisateur 3 = 240
		set "246" "296"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" # Débug 4 = 242
		set "310" "258"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" # Sortie 7 = 310
		"$CMDECHO" -e "\e[38;5;201mEasyBOX by FOUINI\e[0m"
		set "312" "313"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" # Plex = 50
		set "314" "315"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" # OpenVPN = 51
		set "260"; FONCTXT "$1"; "$CMDECHO" -n -e "${CBLUE}$TXT1 ${CEND}"
		read -r OPTION

		case $OPTION in
			1) # ajout utilisateur
				FONCUSER # demande nom user
				"$CMDECHO" ""
				FONCPASS # demande mot de passe

				# récupération 5% root sur /home/user si présent
				FONCFSUSER "$USER"

				# variable passe nginx
				PASSNGINX=${USERPWD}

				# ajout utilisateur
				"$CMDUSERADD" -M -s /bin/bash "$USER"

				# création mot de passe utilisateur
				"$CMDECHO" "${USER}:${USERPWD}" | "$CMDCHPASSWD"

				# anti-bug /home/user déjà existant
				"$CMDMKDIR" -p /home/"$USER"
				"$CMDCHOWN" -R "$USER":"$USER" /home/"$USER"

				# variable utilisateur majuscule
				USERMAJ=$("$CMDECHO" "$USER" | "$CMDTR" "[:lower:]" "[:upper:]")

				# récupération ip serveur
				FONCIP
				"$CMDSU" "$USER" -c ""$CMDMKDIR" -p ~/watch ~/torrents ~/.session ~/.backup-session"

				# calcul port
				FONCPORT

				# configuration .rtorrent.rc
				FONCTORRENTRC "$USER" "$PORT" "$RUTORRENT"

				# configuration user rutorrent.conf
				"$CMDSED" -i '$d' "$NGINXENABLE"/rutorrent.conf
				FONCRTCONF "$USERMAJ"  "$PORT" "$USER"

				# configuration script backup .session (retro-compatible)
				if [ -f "$SCRIPT"/backup-session.sh ]; then
					FONCBAKSESSION
				fi

				# config.php
				"$CMDMKDIR" "$RUCONFUSER"/"$USER"
				FONCPHPCONF "$USER" "$PORT" "$USERMAJ"

				# plugins.ini
				"$CMDCP" -f "$FILES"/rutorrent/plugins.ini "$RUCONFUSER"/"$USER"/plugins.ini

				# chroot user supplémentaire
				"$CMDCAT" <<- EOF >> /etc/ssh/sshd_config
					Match User $USER
					ChrootDirectory /home/$USER
				EOF

				FONCSERVICE restart ssh

				# permissions
				"$CMDCHOWN" -R "$WDATA" "$RUTORRENT"
				"$CMDCHOWN" -R "$USER":"$USER" /home/"$USER"
				"$CMDCHOWN" root:"$USER" /home/"$USER"
				"$CMDCHMOD" 755 /home/"$USER"

				# script rtorrent
				FONCSCRIPTRT "$USER"

				# htpasswd
				FONCHTPASSWD "$USER"

				# lancement user
				FONCSERVICE start "$USER"-rtorrent

				# log users
				"$CMDECHO" "userlog">> "$RUTORRENT"/"$HISTOLOG".log
				"$CMDSED" -i "s/userlog/$USER:$PORT/g;" "$RUTORRENT"/"$HISTOLOG".log
				FONCSERVICE restart nginx
				"$CMDECHO" ""; set "218"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"; "$CMDECHO" ""
				set "182"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1${CEND}"
				set "184"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND}"
				set "186"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND} ${CYELLOW}${PASSNGINX}${CEND}"
				set "188"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1${CEND}"; "$CMDECHO" ""
			;;
			
			2) # suspendre utilisateur
				"$CMDECHO" ""; set "214"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1 ${CEND}"
				read -r USER

				# variable email (rétro compatible)
				TESTMAIL=$("$CMDSED" -n "1 p" "$RUTORRENT"/"$HISTOLOG".log)
				if [[ "$TESTMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]*$ ]]; then
					EMAIL="$TESTMAIL"
				else
					EMAIL=contact@exemple.com
				fi

				# récupération ip serveur
				FONCIP

				# variable utilisateur majuscule
				USERMAJ=$("$CMDECHO" "$USER" | "$CMDTR" "[:lower:]" "[:upper:]")

				"$CMDECHO" ""; set "262"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"; "$CMDECHO" ""
				"$CMDUPDATERC" "$USER"-rtorrent remove

				# contrôle présence utilitaire
				if [ ! -f "$NGINXBASE"/aide/contact.html ]; then
					cd /tmp || exit
					"$CMDWGET" http://www.bonobox.net/script/contact.tar.gz
					"$CMDTAR" xzfv contact.tar.gz
					"$CMDCP" -f /tmp/contact/contact.html "$NGINXBASE"/aide/contact.html
					"$CMDCP" -f /tmp/contact/style/style.css "$NGINXBASE"/aide/style/style.css
				fi

				# page support
				"$CMDCP" -f "$NGINXBASE"/aide/contact.html "$NGINXBASE"/"$USER".html
				"$CMDSED" -i "s/@USER@/$USER/g;" "$NGINXBASE"/"$USER".html
				"$CMDCHOWN" -R "$WDATA" "$NGINXBASE"/"$USER".html

				# stop user
				FONCSERVICE stop "$USER"-rtorrent
				if [ -f "/etc/irssi.conf" ]; then
					FONCSERVICE stop "$USER"-irssi
				fi
				"$CMDPKILL" -u "$USER"
				"$CMDMV" /home/"$USER"/.rtorrent.rc /home/"$USER"/.rtorrent.rc.bak
				"$CMDUSERMOD" -L "$USER"
				##########################################################################
				NGINX_CONFIG="$NGINXENABLE"/rutorrent.conf
                USER_TO_BLOCK="$USER"
				#Save config nginx
                cp "$NGINX_CONFIG" "$NGINX_CONFIG.bak"

                # Ajouter les lignes pour bloquer un utilisateur spécifique
				sed -i "/location \/rutorrent {/a \    if (\$remote_user = \"$USER_TO_BLOCK\") {\n        return 302 /$USER_TO_BLOCK.html;\n    }" "$NGINX_CONFIG"
				    
				# Redémarrer Nginx pour appliquer les changements
				nginx -t
                if [ $? -eq 0 ]; then
                # Redémarrer Nginx pour appliquer les changements
                sudo service nginx restart
                echo -e "\e[92mSuccess! L'utilisateur $USER_TO_BLOCK a plus accès a RuTorrent! NGINX a été redémarré.\e[0m"
                else
                echo -e "\e[91mErreur: La syntaxe NGINX est incorrecte! Veuillez vérifier la configuration avant de redémarrer Nginx. Un backup est présent ici $NGINX_CONFIG.bak\e[0m"
                exit 1
                fi
				##########################################################################

				"$CMDECHO" ""; set "264" "268"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND} ${CBLUE}$TXT2${CEND}"
			;;

			3) # rétablir utilisateur
				"$CMDECHO" ""; set "214"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1${CEND}"
				read -r USER
				"$CMDECHO" ""; set "270"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"; "$CMDECHO" ""

				"$CMDMV" /home/"$USER"/.rtorrent.rc.bak /home/"$USER"/.rtorrent.rc
				# remove ancien script pour mise à jour init.d
				"$CMDUPDATERC" "$USER"-rtorrent remove

				# script rtorrent
				FONCSCRIPTRT "$USER"

				# start user
				"$CMDRM" /home/"$USER"/.session/rtorrent.lock >/dev/null 2>&1
				FONCSERVICE start "$USER"-rtorrent
				if [ -f "/etc/irssi.conf" ]; then
					FONCSERVICE start "$USER"-irssi
				fi
				"$CMDUSERMOD" -U "$USER"

				# seedbox service normal
				"$CMDRM" "$NGINXBASE"/"$USER".html
				
				#######################################################################  
                NGINX_CONFIG="$NGINXENABLE"/rutorrent.conf
                USER_TO_BLOCK="$USER"
                #Save config nginx
                cp "$NGINX_CONFIG" "$NGINX_CONFIG.bak"

				sed -i "/if (\$remote_user = \"$USER_TO_BLOCK\") {/,/}/d" "$NGINX_CONFIG"
				# Redémarrer Nginx pour appliquer les changements
				nginx -t
                if [ $? -eq 0 ]; then
                # Redémarrer Nginx pour appliquer les changements
                sudo service nginx restart
                echo -e "\e[92mSuccess! L'utilisateur $USER_TO_BLOCK a de nouveau accès a RuTorrent! NGINX a été redémarré.\e[0m"
                else
                echo -e "\e[91mErreur: La syntaxe NGINX est incorrecte! Veuillez vérifier la configuration avant de redémarrer Nginx. Un backup est présent ici $NGINX_CONFIG.bak\e[0m"
                exit 1
                fi
				##########################################################################

				"$CMDECHO" ""; set "264" "272"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND} ${CBLUE}$TXT2${CEND}"
			;;

			4) # modification mot de passe utilisateur
				"$CMDECHO" ""; set "214"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1 ${CEND}"
				read -r USER
				"$CMDECHO" ""; FONCPASS

				"$CMDECHO" ""; set "276"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"; "$CMDECHO" ""

				# variable passe nginx
				PASSNGINX=${USERPWD}

				# modification du mot de passe
				"$CMDECHO" "${USER}:${USERPWD}" | "$CMDCHPASSWD"

				# htpasswd
				FONCHTPASSWD "$USER"

				"$CMDECHO" ""; set "278" "280"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND} ${CBLUE}$TXT2${CEND}"
				"$CMDECHO"
				set "182"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1${CEND}"
				set "184"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND}"
				set "186"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND} ${CYELLOW}${PASSNGINX}${CEND}"
				set "188"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1${CEND}"; "$CMDECHO" ""
			;;

			5) # suppression utilisateur
				"$CMDECHO" ""; set "214"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1 ${CEND}"
				read -r USER
				"$CMDECHO" ""; set "282" "284"; FONCTXT "$1" "$2"; "$CMDECHO" -n -e "${CGREEN}$TXT1${CEND} ${CYELLOW}$USER${CEND} ${CGREEN}$TXT2 ${CEND}"
				read -r SUPPR

				if FONCNO "$SUPPR"; then
					"$CMDECHO"
				else
					set "286"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"; "$CMDECHO" ""

					# variable utilisateur majuscule
					USERMAJ=$("$CMDECHO" "$USER" | "$CMDTR" "[:lower:]" "[:upper:]")

					# stop utilisateur
					FONCSERVICE stop "$USER"-rtorrent

                    # stop irssi retro-compatible
					if [ -f "/etc/init.d/"$USER"-irssi" ]; then
						FONCSERVICE stop "$USER"-irssi
					fi

					# arrêt user
					"$CMDPKILL" -u "$USER"

					# suppression script irssi retro-compatible
					if [ -f "/etc/init.d/"$USER"-irssi" ]; then
						"$CMDRM" /etc/init.d/"$USER"-irssi
						"$CMDUPDATERC" "$USER"-irssi remove
					fi

					"$CMDRM" /etc/init.d/"$USER"-rtorrent
					"$CMDUPDATERC" "$USER"-rtorrent remove

					# suppression configuration rutorrent
					"$CMDRM" -R "${RUCONFUSER:?}"/"$USER"
					"$CMDRM" -R "${RUTORRENT:?}"/share/users/"$USER"

					# suppression mot de passe
					"$CMDSED" -i "/^$USER/d" "$NGINXPASS"/rutorrent_passwd
					"$CMDRM" "$NGINXPASS"/rutorrent_passwd_"$USER"

					# suppression nginx
					"$CMDSED" -i '/location \/'"$USERMAJ"'/,/}/d' "$NGINXENABLE"/rutorrent.conf
					FONCSERVICE restart nginx

					# suppression backup .session
					"$CMDSED" -i "/FONCBACKUP $USER/d" "$SCRIPT"/backup-session.sh

					# suppression utilisateur
					"$CMDDELUSER" "$USER" --remove-home
					cd "$BONOBOX"
					"$CMDECHO" ""; set "264" "288"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND} ${CBLUE}$TXT2${CEND}"
				fi
			;;
			
			6) # debug
				"$CMDCHMOD" a+x "$FILES"/scripts/check-rtorrent.sh
				"$CMDBASH" "$FILES"/scripts/check-rtorrent.sh
			;;
			
			7) # sortir gestion utilisateurs
				"$CMDECHO" ""; set "290"; FONCTXT "$1"; "$CMDECHO" -n -e "${CGREEN}$TXT1 ${CEND}"
				read -r REBOOT

				if FONCNO "$REBOOT"; then
					FONCSERVICE restart nginx &> /dev/null
					"$CMDECHO" ""; set "200"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"
					"$CMDECHO" ""; set "210"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
					"$CMDECHO" -e "${CBLUE}                          Ex_Rat - http://mondedie.fr${CEND}"; "$CMDECHO" ""
					exit 1
				fi

				if FONCYES "$REBOOT"; then
					"$CMDECHO" ""; set "210"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
					"$CMDECHO" -e "${CBLUE}                          Ex_Rat - http://mondedie.fr${CEND}"; "$CMDECHO" ""
					"$CMDSYSTEMCTL" reboot
				fi
				break
			;;
			
			50)
				"$CMDAPTGET" install apt-transport-https -y
				"$CMDECHO" "deb https://downloads.plex.tv/repo/deb/ public main" > /etc/apt/sources.list.d/plexmediaserver.list
				"$CMDWGET" -q https://downloads.plex.tv/plex-keys/PlexSign.key -O - | "$CMDAPTKEY" add -
				# voir en dessous pour utiliser FONCSERVICE avec systemctl à la place de "$CMDSERVICE"
				"$CMDAPTITUDE" update && "$CMDAPTITUDE" install -y plexmediaserver && "$CMDSERVICE" plexmediaserver start
				#ajout icon de plex
				if [ ! -d "$RUPLUGINS"/linkplex ];then
					"$CMDGIT" clone --progress https://github.com/xavier84/linkplex "$RUPLUGINS"/linkplex
					"$CMDCHOWN" -R "$WDATA" "$RUPLUGINS"/linkplex

				fi
			;;
			
			51)
				"$CMDWGET" https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
				"$CMDCHMOD" +x openvpn-install.sh && ./openvpn-install.sh
			;;

			*) # fail
				set "292"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"
			;;
		esac
	done
fi

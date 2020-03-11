#!/bin/bash

set -e

# base from https://github.com/Fmstrat/samba-domain/

# Set variables
DOMAIN=${DOMAIN:-SAMDOM.LOCAL}
DOMAINPASS=${DOMAINPASS:-youshouldsetapassword}
JOIN=${JOIN:-false}
JOINSITE=${JOINSITE:-NONE}
NOCOMPLEXITY=${NOCOMPLEXITY:-false}
INSECURELDAP=${INSECURELDAP:-false}
DNSFORWARDER=${DNSFORWARDER:-NONE}
HOSTIP=${HOSTIP:-NONE}

LDOMAIN=${DOMAIN,,}
UDOMAIN=${DOMAIN^^}
URDOMAIN=${UDOMAIN%%.*}

# Set host ip option
if [[ "$HOSTIP" != "NONE" ]]; then
	HOSTIP_OPTION="--host-ip=$HOSTIP"
else
	HOSTIP_OPTION=""
fi

# Set up samba

# If the finished file isn't there, this is brand new, we're not just moving to a new container
if [[ ! -f /usr/local/samba/external/smb.conf ]]; then
	#mv /usr/local/samba/smb.conf /etc/samba/smb.conf.orig
	if [[ ${JOIN,,} == "true" ]]; then
		if [[ ${JOINSITE} == "NONE" ]]; then
			/usr/local/samba/bin/samba-tool domain join ${LDOMAIN} DC -U"${URDOMAIN}\administrator" --password="${DOMAINPASS}" --dns-backend=SAMBA_INTERNAL
		else
			/usr/local/samba/bin/samba-tool domain join ${LDOMAIN} DC -U"${URDOMAIN}\administrator" --password="${DOMAINPASS}" --dns-backend=SAMBA_INTERNAL --site=${JOINSITE}
		fi
	else
		/usr/local/samba/bin/samba-tool domain provision --use-rfc2307 --domain=${URDOMAIN} --realm=${UDOMAIN} --server-role=dc --dns-backend=SAMBA_INTERNAL --adminpass=${DOMAINPASS} ${HOSTIP_OPTION}
		if [[ ${NOCOMPLEXITY,,} == "true" ]]; then
			/usr/local/samba/bin/samba-tool domain passwordsettings set --complexity=off
			/usr/local/samba/bin/samba-tool domain passwordsettings set --history-length=0
			/usr/local/samba/bin/samba-tool domain passwordsettings set --min-pwd-age=0
			/usr/local/samba/bin/samba-tool domain passwordsettings set --max-pwd-age=0
		fi
	fi
	sed -i "/\[global\]/a \
		wins support = yes\\n\
		log level = 3\\n\
		load printers = no\\n\
		printing = bsd\\n\
		printcap name = /dev/null\\n\
		#server services = s3fs, rpc, nbt, wrepl, ldap, cldap, kdc, drepl, winbindd, ntp_signd, kcc, dnsupdate, dns\
		" /usr/local/samba/etc/smb.conf

	if [[ $DNSFORWARDER != "NONE" ]]; then
		sed -i "/\[global\]/a \
			\\\tdns forwarder = ${DNSFORWARDER}\
			" /usr/local/samba/etc/smb.conf
	fi

	if [[ ${INSECURELDAP,,} == "true" ]]; then
		sed -i "/\[global\]/a \
			\\\tldap server require strong auth = no\
			" /usr/local/samba/etc/smb.conf
	fi
	sed -i -e "/dns forwarder = 127.0.0.11/d" /usr/local/samba/etc/smb.conf

	# Once we are set up, we'll make a file so that we know to use it if we ever spin this up again
	cp /usr/local/samba/etc/smb.conf /usr/local/samba/external/smb.conf
else
	cp /usr/local/samba/external/smb.conf /usr/local/samba/etc/smb.conf
fi

mv /etc/krb5.conf /etc/krb5.conf.orig
cp /usr/local/samba/private/krb5.conf /etc/krb5.conf

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- /usr/local/samba/sbin/samba -i -M prefork "$@"
fi

# Assume that user wants to run their own process,
# for example a `bash` shell to explore this image
exec "$@"

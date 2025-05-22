#!/bin/sh
if [ $(grep -ci $USERNAME /etc/shadow) -eq 0 ]; then
    useradd -r -G lpadmin -M $USERNAME

    # add password
    echo $USERNAME:$PASSWORD | chpasswd

    # add tzdata
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata
fi

# restore default cups config in case user does not have any
if [ ! -f /etc/cups/cupsd.conf ]; then
    cp -p /etc/cups.default/cupsd.conf    /etc/cups/
    cp -p /etc/cups.default/printers.conf /etc/cups/
    #cp -rpn /etc/cups.default/* /etc/cups/
fi

if [ -d /etc/cups.default/ppd ]; then
  mkdir -p /etc/cups/ppd
  cp -rp /etc/cups.default/ppd/* /etc/cups/ppd/
fi

# Inicia o tail dos logs em background
tail -F /var/log/cups/access_log /var/log/cups/error_log &

# Inicia o CUPS em foreground
/usr/sbin/cupsd -f &
CUPSD_PID=$!

# Espera o CUPS morrer ou o tail encerrar
wait $CUPSD_PID
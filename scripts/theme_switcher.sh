#!/bin/bash
# theme switcher
if [ $# -eq 0 ]
then
echo "Script to switch EVE themes."
echo "example, ./theme_switcher.sh <argument>"
echo "List of avilable arguments:"
echo "   default  - default theme"
echo "   adminlte - adminLTE theme"
exit 0
elif [ $# -eq 1 ]
then

case "$1" in

'default') echo "Default theme applyed"
	cat /opt/unetlab/scripts/theme_switcher/default.txt > /opt/unetlab/html/.htaccess
  ;;

'adminlte') echo "AdminLTE theme applyed"
	 cat /opt/unetlab/scripts/theme_switcher/adminlte.txt > /opt/unetlab/html/.htaccess
  ;;

*) echo "Unexpected argument! Write command without arguments to list all."
   exit 0
   ;;

esac

exit 0
elif [ $# -gt 1 ]
then
echo "Too match arguments! Exit"
exit 0
fi

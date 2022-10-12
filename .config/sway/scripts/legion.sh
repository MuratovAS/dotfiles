#!/bin/sh

case $1 in

  c)
  if [ `cat /sys/devices/system/cpu/cpufreq/boost` = "0" ]
  then 
  	R=1;echo "CPU boost turn on";
  else 
  	R=0;echo "CPU boost turn off"; 
  fi
  su -c "echo $R > /sys/devices/system/cpu/cpufreq/boost" && echo "Success"
  ;;

  s)
  if [ `cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode` = "0" ]
  then 
    R=1;echo "Save battery turn on";
  else
    R=0;echo "Save battery turn off"; 
  fi
  su -c "echo $R > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode" && echo "Success"
  ;;

  *)
    echo "Unknown Command"
  ;;
esac

sleep 5
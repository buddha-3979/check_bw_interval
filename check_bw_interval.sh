#!/bin/bash

read -p"Nhap BW(Mbps): " BW_read
count=1
while [ $count -ge 1 ]
do
printf "Chon chieu (1 hoac 2):\n1.Incoming\n2.Outgoing\n"
read chieu
if [ $chieu != 1 ] && [ $chieu != 2 ]
then
   echo "Nhap sai, moi nhap lai"
else
   let count=count-1
   if [[ $chieu == 1 ]]
   then direction="incoming"
   else direction="outgoing"
   fi
echo "****Nhap moc thoi gian dau:"
i=1
while [ $i -ge 1 ]
do 
read -p"Nhap ngay (YYYY-MM-DD): " day1
check=`echo $day1 | awk -F"[-]" '{
if( NF == 3 && $1 >= 0 && $2 >= 1 && $2 <= 12 && $3 >= 1 && $3 <= 31){
    print "OK"
  }
}'
`
if [[ $check == OK ]]
then
  let i=i-1
else
  echo "Sai Format"
fi
done
while [ $i -lt 1 ]
do
read -p"Nhap thoi gian (HH:MM) : " time1
check2=`echo $time1 | awk -F"[:]" '{
if( NF == 2 && $1 >= 0 && $1 <= 24 && $2 >= 0 && $2 <= 60){
    print "OK"
  }
}'  
`
if [[ $check2 == OK ]]
then
  let i=i+1
else
  echo "Sai Format"
fi
done
sleep 1
echo "****Nhap moc thoi gian cuoi:"
while [ $i -ge 1 ]
do
read -p"Nhap ngay (YYYY-MM-DD): " day2
check3=`echo $day2 | awk -F"[-]" '{
if( NF == 3 && $1 >= 0 && $2 >= 1 && $2 <= 12 && $3 >= 1 && $3 <= 31){
    print "OK"
  }
}'
`
if [[ $check3 == OK ]]
then
  let i=i-1
else
  echo "Sai Format"
fi
done
while [ $i -lt 1 ]
do
read -p"Nhap thoi gian (HH:MM) : " time2
check4=`echo $time2 | awk -F"[:]" '{
if( NF == 2 && $1 >= 0 && $1 <= 24 && $2 >= 0 && $2 <= 60){
    print "OK"
  }
}'  
`
if [[ $check2 == OK ]]
then
  let i=i+1
else
  echo "Sai Format"
fi
done



timestamp_up=`TZ=MST date +%Y-%m-%dT%H:%M -d "$day2 $time2 UTC"`
timestamp_down=`TZ=MST date +%Y-%m-%dT%H:%M -d "$day1 $time1 UTC"`

ceilometer sample-list -m network."$direction".bytes.rate -q "timestamp>$timestamp_down;timestamp<$timestamp_up"  > BW_VM

index=0
bc=0
i=0
while read line ; do
    MYARRAY[$index]="$line"
    index=$(($index+1))
done < BW_VM
for i in "${MYARRAY[@]}";
do
BW=`echo $i | awk '{print $8}'`
BW_M=$(echo "scale=5; $BW*8/1000000" | bc -l)
VM=`echo $i | awk '{print $2}' | cut -c 19-54`
TS=`echo $i | awk '{print $12}'`

#if [ $(bc <<< "$BW_read <= $BW") -eq 1 ]
if ((` bc <<< "$BW_M>=$BW_read" `));
then
VM_name=` nova show $VM | awk 'NR==24 {print $4}' `
node=` nova show $VM | awk 'NR==6 {print $4}' `
id=` nova show $VM | awk 'NR==20 {print $4}' `
echo $node $id $VM_name  $BW_M  Mb/s $TS
fi
#rm BW_VM
done
rm BW_VM
fi
done

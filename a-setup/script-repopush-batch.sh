#!/bin/bash 
#script-repopush-batch.sh

n=44900
dst=origin3

batchsize=100

errcnt=0
while true
do
    echo
    if [ $n -le 50 ]; then 
        echo "  escape pushing at ~$n"
        break
    fi

    pushcmd="git push origin3 master~$n:refs/heads/master"
    echo "$pushcmd"
    sleep 1

    retrycnt=0
    startsec=`date +%s`
    while true
    do
        $pushcmd
        if [ $? -eq 0 ]; then 
            finishsec=`date +%s`
            echo "  ok pushed ~$n in $(($finishsec - $startsec))"
            break;
        else
            retrycnt=$(($retrycnt + 1))
            errcnt=$(($errcnt +1))
            echo "  failed $retrycnt pushing ~$n retry..."
            if [ $retrycnt -gt 10 ] ; then 
                break
            fi
            sleep 10
        fi
    done

    if [ $retrycnt -gt 10 ] ; then 
            echo "  failed $retrycnt pushing ~$n escaping..."
            break
    fi
    n=$(($n - $batchsize))
done

echo pushed till $n
if [ $errcnt -ne 0 ]; then 
    echo pushed with error count $errcnt
fi



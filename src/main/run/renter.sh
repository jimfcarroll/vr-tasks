#!/bin/sh

usage()
{
    echo "usage: renter.sh -n \"Full Name\" -a MM/DD/YYYY -d MM/DD/YYYY -u (email url) -r rent-as-int -p 1|2 -na x -nc y"
    exit 1
}

substitute()
{
    PWD="`pwd`"
    cd "$WORKING/unzipped/word"

    KEY=$1
    VAL="$2"

    mv document.xml tmp.xml
    sed -e "s/{{$KEY}}/$VAL/g" tmp.xml > document.xml
    rm tmp.xml

    cd "$PWD"
}

TMPEXT=`date +%s`
WORKING="/tmp/working.$TMPEXT"

DOCDIR="/home/jim/WindowsDisk/Documents/Real Estate/Arrowhead Lake Getaway"
TEMPLATE1="Rental Contract - ONE PAYMENT TEMPLATE.docx"
TEMPLATE2="Rental Contract - TEMPLATE.docx"

RENTERNAME=
ARRIVAL=
DEPARTURE=
URL=
RENT=
SECURITY="500"
CLEANING="150"
PAYMENTS=
NUMADULTS=
NUMCHILDREN=

while [ $# -gt 0 ]; do
    case $1 in
    "-n")
        RENTERNAME=$2
        shift
        shift
        ;;
     "-a")
        ARRIVAL=$2
        shift
        shift
        ;;
     "-d")
        DEPARTURE=$2
        shift
        shift
        ;;
      "-r")
        RENT=$2
        shift
        shift
        ;;
     "-p")
        PAYMENTS=$2
        shift
        shift
        ;;
     "-u")
        URL=$2
        shift
        shift
        ;;
     "-na")
        NUMADULTS=$2
        shift
        shift
        ;;
     "-nc")
        NUMCHILDREN=$2
        shift
        shift
        ;;
     *)
        usage
        ;;
    esac
done

if [ "$RENTERNAME" = "" ]; then
    echo "You must supply the -n option."
    usage
fi

if [ "$ARRIVAL" = "" ]; then
    echo "You must supply the -a option."
    usage
fi

if [ "$DEPARTURE" = "" ]; then
    echo "You must supply the -d option."
    usage
fi

if [ "$RENT" = "" ]; then
    echo "You must supply the -r option."
    usage
fi

if [ "$URL" = "" ]; then
    echo "You must supply the -u option."
    usage
fi

if [ "$NUMADULTS" = "" ]; then
    echo "You must supply the -na option."
    usage
fi

if [ "$NUMCHILDREN" = "" ]; then
    echo "You must supply the -nc option."
    usage
fi

if [ "$PAYMENTS" != "1" -a "$PAYMENTS" != "2" ]; then
    echo "You must supply the -p option and it must be 1 or 2."
    usage
fi

FIRSTRENTPAYMENT=
if [ "$PAYMENTS" = "2" ]; then
    TEMPLATE="$DOCDIR/$TEMPLATE2"
    FIRSTRENTPAYMENT=`expr $RENT / 2`
else
    TEMPLATE="$DOCDIR/$TEMPLATE1"
fi

if [ ! -f "$TEMPLATE" ]; then
    echo "Cannot find the template file \"$TEMPLATE\""
    exit 1
fi

OUTDOC="`date --date="$ARRIVAL" +%Y%m%d` - $RENTERNAME - Rental Contract.docx"

mkdir "$WORKING"
cp "$TEMPLATE" "$WORKING/tmp.docx"

CWD=`pwd`

cd "$WORKING"
mkdir unzipped
cd unzipped
unzip ../tmp.docx > /dev/null

cd "$CWD"

substitute "securityPayment" "$SECURITY.00"

if [ "$FIRSTRENTPAYMENT" != "" ]; then
    substitute "firstRentPayment" "$FIRSTRENTPAYMENT.00"
    FIRSTPAYMENT=`expr $FIRSTRENTPAYMENT + $SECURITY`
    substitute "firstPayment" "$FIRSTPAYMENT.00"

    LASTRENTPAYMENT=`expr $RENT - $FIRSTRENTPAYMENT`
    substitute lastRentPayment "$LASTRENTPAYMENT.00"
    LASTPAYMENT=`expr $LASTRENTPAYMENT + $CLEANING`
    substitute lastPayment "$LASTPAYMENT.00"
fi

DATE=`date +"%B %d, %Y"`
substitute date "$DATE"
substitute renterName "$RENTERNAME"

DATE=`date --date="$ARRIVAL" +"%B %d, %Y"`
substitute fullArrivalDate "$DATE"

DATE=`date --date="$DEPARTURE" +"%B %d, %Y"`
substitute fullDepartureDate "$DATE"

substitute numAdults "$NUMADULTS"
substitute numChildren "$NUMCHILDREN"

substitute rentPayment "$RENT.00"
substitute cleaningFee "$CLEANING.00"

FULLPAYMENT=`expr $RENT + $SECURITY + $CLEANING`
substitute fullPayment "$FULLPAYMENT.00"

cd "$WORKING/unzipped"

jar -cvfM "$DOCDIR/$OUTDOC" * > /dev/null

cd "$CWD"

rm -rf $WORKING

groovy -cp ./vr-tasks-1.0.0.jar task.groovy -a $ARRIVAL -n "$RENTERNAME" -u "$URL" -p $PAYMENTS

gnome-open "$DOCDIR/$OUTDOC"

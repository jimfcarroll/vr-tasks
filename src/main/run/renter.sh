#!/bin/sh

##############################################################
## set the following variables accordingly
GROOVY=/home/jim/utils/groovy-2.2.1/bin/groovy
OPENDOC_COMMAND=xdg-open

DOCDIR="/home/jim/Documents/Real Estate/Arrowhead Lake Getaway"
TEMPLATE1="Rental Contract - ONE PAYMENT TEMPLATE.docx"
TEMPLATE2="Rental Contract - TEMPLATE.docx"
JARFILE="./vr-tasks-1.0.0.jar"

WORKING="/tmp/working.`date +%s`"

SECURITY="500"
CLEANING="150"
##############################################################

RENTERNAME=
ARRIVAL=
DEPARTURE=
URL=
RENT=
PAYMENTS=
NUMADULTS=
NUMCHILDREN=

usage()
{
    echo "usage: renter.sh -n \"Full Name\" -a MM/DD/YYYY -d MM/DD/YYYY -u (email url) -r rent-as-int -p 1|2 -na x -nc y"
    echo "       -n: Renter's full name in quotes."
    echo "       -a: Arrival Date MM/DD/YYYY."
    echo "       -d: Departure Date MM/DD/YYYY."
    echo "       -u: URL to the gmail email for this renter."
    echo "       -r: Rental amount as an integer (no decimals)."
    echo "       -p: The number of payments. Either 1 or 2."
    echo "       -na: The number of adults."
    echo "       -nc: The number of children."
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

# set up the working directory
mkdir -p "$WORKING"

# copy the appropriate template into the working dir
cp "$TEMPLATE" "$WORKING/tmp.docx"

# store off the current directory so we can get back here
CWD=`pwd`

# go into the working directory and create a subdirectory for unzipping the docuemtn
cd "$WORKING"
mkdir unzipped

# unzip the document into the new subdirectory
cd unzipped
unzip ../tmp.docx > /dev/null

# go back to were we started
cd "$CWD"

########################################################
# Do the subsititutions. The key's are expected to appear in the 
# document with double curly braces around them. For example,
# the first key 'securityPayment' appears in the document as
# {{securityPayment}}.

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
########################################################

# Rewrite the document by zipping back up the modified parts
# into the final
cd "$WORKING/unzipped"
jar -cvfM "$DOCDIR/$OUTDOC" * > /dev/null

# go back to where we started
cd "$CWD"

rm -rf $WORKING

$GROOVY -cp $JARFILE task.groovy -a $ARRIVAL -n "$RENTERNAME" -u "$URL" -p $PAYMENTS

$OPENDOC_COMMAND "$DOCDIR/$OUTDOC"

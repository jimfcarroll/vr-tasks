import java.text.SimpleDateFormat

import com.jiminger.vr.tasks.Task
import com.jiminger.vr.tasks.VrTasksUtils;

def long ONE_DAY_MILLIS = 24L * 60L * 60L * 1000L
def long ONE_WEEK_MILLIS = (7L * ONE_DAY_MILLIS)
def long TWO_WEEKS_MILLIS = (14L * ONE_DAY_MILLIS)
def long THIRTY_DAYS_MILLIS = (30L * ONE_DAY_MILLIS)

def cli = new CliBuilder(usage: 'groovy -cp [..] task.groovy [options]')

def SimpleDateFormat dateFormat = new SimpleDateFormat("MM/dd/yyyy")

cli.with {
   n longOpt: 'name', args:1, 'required - The quoted first and last name of the renter. E.g. "John Smith" (including the quotes)'
   a longOpt: 'arrival', args:1, 'required - The date of arrival in the form MM/dd/YYYY'
   u longOpt: 'url', args:1, 'required - The url to the email thread.'
   p longOpt: 'payments', args:1, 'The default behavior is to set the payment to 2 if the time between today and the' +
   ' arrival date is more than 2 wk + 30 days. Otherwise it assumes 1 payment. You can' +
   ' use this option to override this default.'
   d longOpt: 'dryrun', args:0, """Just calculate and print out the tasks, don't actually insert them into the task list."""
}

def groovy.util.OptionAccessor options = cli.parse(args)

def usage(String errmessage, def cli)
{
   println errmessage
   cli.usage()
   System.exit(1)
}

String name = options.n ?: null
if (name == null) usage("you must supply the '-n,--name' option", cli)

String arrivalStr = options.a ?: null
if (arrivalStr == null) usage("you must supply the '-a,--arrival' option", cli)

String url = options.u ?: null
if (url == null) usage("you must supply the '-u,--url' option", cli)

Date arrivalDate = dateFormat.parse(arrivalStr)

Date wkBeforeArrival = new Date(arrivalDate.getTime() - ONE_WEEK_MILLIS)
Date thirtyDaysBeforeArrival = new Date(arrivalDate.getTime() - THIRTY_DAYS_MILLIS)

long now = System.currentTimeMillis()

// if we are within a week of arrival, you'll need to do this by hand.
if (now > wkBeforeArrival.getTime())
{
   println "Cannot use this program when we are within a week of arrival. Sorry."
   System.exit(1)
}

Date twoWeeksFromToday = new Date(now + TWO_WEEKS_MILLIS)

// is the 30 days prior to arrival mark within 2 weeks?
boolean thirtyDaysPriorToArrivalIsWithin2Weeks = twoWeeksFromToday > thirtyDaysBeforeArrival

int defaultNumPayments = thirtyDaysPriorToArrivalIsWithin2Weeks ? 1 : 2
String numPaymentStr = options.p ?:  null
int numPayment = numPaymentStr == null ? defaultNumPayments : numPaymentStr.toInteger()

if (numPayment < 1 || numPayment > 2) usage("The number of payments must be either 1 or 2")

tasks = []

long finalPaymentDate = numPayment == 1 ? (now + ONE_WEEK_MILLIS) : thirtyDaysBeforeArrival.getTime()

String arrivalString = "Arrival " + (new SimpleDateFormat("MMM dd").format(arrivalDate)) + "\n\n"

// First payment task
String notes = numPayment == 1 ? "Full payment due + vehicle info\n\n" : "1st payment due\n\n"
notes = arrivalString + notes
notes += url
tasks.add(new Task(name + " 1st payment", now + ONE_WEEK_MILLIS, notes))

// car registration ... with final payment but at least one week prior to arrival
long registrationReminderDue = Math.min(wkBeforeArrival.getTime(), finalPaymentDate)
tasks.add(new Task(name + " register vehicles", now + ONE_WEEK_MILLIS, arrivalString + "reister vehicles\n\n" + url))

// final payment due
if (numPayment == 2)
{
   tasks.add(new Task(name + " final payment + vehicle info", finalPaymentDate, arrivalString + "final payment + vehicle info\n\n" + url))
}

// welcome package
tasks.add(new Task(name + " 1wk, welcome", wkBeforeArrival.getTime(), arrivalString + "send welcome package\n\n" + url))

// security deposit refund
tasks.add(new Task(name + " security deposit return", arrivalDate.getTime() + TWO_WEEKS_MILLIS, arrivalString + "security deposit refund\n\n" + url))

println tasks

if (!options.d)
   VrTasksUtils.insertTasks(tasks);



ahigs_fos
=========

(AHIGS Festival of Speech -- a public speaking competition between NSW
independent girls schools)


DESCRIPTION


Calculate scores and produce reports in a complex, multi-event competition,
where there are many entrants, many events, and each event pays points for
first, second, ... fifth, and participation.

It is fairly configurable, so may be of interest to other people, but it _is_
geared towards the needs of a particular competition.

The idea is that results are recorded in text files, and this program reads the
results and produces a report (HTML, PDF ... haven't decided) showing the
current point standings and how the points were accumulated.  Points are all
calculated by the computer; the results can be trusted as long as the results
were recorded correctly, which can be verified.

Some of the text in this file will be specific to my purpose.



OVERVIEW


When given a hand-completed slip that says

   Event: Current Affairs
   Results:
     1. Frensham
     2. Danebank
     3. PLC Sydney
     4. Loreto Kirribilli
     5. Loreto Normanhurst
   (details of other participants)

I record the following in a file (results.yaml):

   - Section: Current Affairs
     Places: 1. Frensham  2. Danebank  3. PLCS  4. Kirribilli  5. Normanhurst
     Nonparticipants:
      - StVincents
      - SCEGGS
      - Roseville

and run a program -- ahigs_fos.rb -- that reads all input files and generates a
complete report of all results (including points obtained) and a points list for
all schools.

[1] There could be one file for each event or, more likely, there might be
"debating-results.events" and "other-results.yaml".  The contents may need to be
more structured than this but they should be simple and human-readable (for
double-checking).



REPORTING


The report should be completely comprehensive so that it can be scrutinised.  It
would contain:
 * A complete description of the configuration: what events are being tracked,
   and how many points are awarded for position numbers 1-5 and participation.
 * Each event: who came first, second, etc., who participated, and how many
   points they got for doing so.
 * Each school: what achievements they have made, and what points they got for
   each one, and of course the total points.
 * An overall point score, listing all schools in descending order of points.
 * A list of outstanding events.

The report could be generated in text AND html AND (perhaps) PDF.  When a report
is generated, two copies are made, for example:
  Dropbox/AHIGS/report.txt
  Dropbox/AHIGS/reports/2011-08-30/report-1432.txt

In this way, it's easy to examine the current report, and all previous reports
can be examined as well.

When the report is being generated, a lot of information is printed to STDOUT
and/or a log file, so that I can clearly see:
 * what files are being read
 * what events are being calculated
 * error messages for mistyped events or schools



CONFIGURATION


To configure this, there are three things to consider:
 * The code lives in its project directory, backed up to github.
 * The live data lives in the data directory, backed up to Dropbox [2].
 * The reports are generated in (potentially) a third directory, probably not
   backed up anywhere.

The code is run from a terminal window (or perhaps a very simple GUI), so it
should read a very simple configuration file, telling it where the data
directory is.

Inside the data directory, the configuration is year-specific, so it could look
for a file like 2011.conf.  This would contain:
 * A list of events, how many places are awarded points, and what those points
   are. [3]
   * It must be known how many points the event pays for participating.
 * A list of schools participating.

Also in the data directory, of course, are the "events" files.  These can be
read in any order, but the report should use the configured event list to
determine the output order.

[2] Of course the Dropbox part is entirely up to the user. Given that network
access probably isn't available on the day, backing up to a USB key is probably
a better idea.

[3] Debating may be more complicated; I don't remember.  If so, some
debating-specific knowledge could be coded or configured.



DATA ENTRY


The data is simply text files.  They should be periodically backed up as a guard
against accidental overwriting.  BUT... there is always the handwritten
submissions to check against.  Nonetheless, some backup is a good idea.  It
could be automatic by the reporting program; it could be manual or semiautomatic
using a separate command; it could use a local git repository or it could just
make a timestamped copy of event files to a backup directory.

The reports generated will contain enough information to check the data entry
and recreate any damaged ".event" files.



EXAMPLE OF CONFIGURATION


(Deleted; see actual configuration files.)

  
OTHER STUFF


Debating is a multi-round competition and will need its own code.


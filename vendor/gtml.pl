#!/usr/bin/perl
#
# Program:      gtml
#
# Version:      3.5.3 (See NEWS file for revision history)
#
# Description:  gtml is a program to manage groups of HTML files with
#               similar properties.
#
# Authors:      versions 1.0 to 2.3
#                   Gihan Perera (gihan@pobox.com), First Step Communications
#               versions 3.0 to current version
#                   Bruno Beaufils (beaufils@lifl.fr)
#               (see CREDITS file for complete list of contributors)
#
# Documentation and updates for this program are available at:
#
#     http://www.lifl.fr/~beaufils/gtml
#
# Copying and Distribution:
#
# Copyright (C) 1996-1999 Gihan Perera
# Copyright (C) 1999 Bruno Beaufils
#
# This program is free software; you can redistribute it and/or  modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.  
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details. 
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA  02111-1307  USA 
#
# ----------------------------------------------------------------------------
#
# Development comment:
#
# $Id: gtml,v 1.36 1999/09/12 23:42:15 beaufils Exp $
#
# Here comes lists of global variables with their utility. 
# 
# Firstly comes variables which may not be changed by gtml or its user:
#
# @configurationFiles gtml default configuration file list
# @extProject         project file suffix list
# @extSource          gtml source file suffix list
#
# Then comes variables which may be modified by gtml user:
#
# $argsep             argument separator
# $beSilent           to produce processing info output or not
# $compression        to produce compressed output or not
# $debug              print debug informations when developping or not
# $delim1             opening macro delimiter
# $delim2             closing macro delimiter
# $entities           to convert HTML entities or not 
# $extTarget          output file suffix       
# $generateMakefiles  generate Makefiles or process files (MAKE_GEN)
# $literal            to not interpret GTML command or to do
# $makefileName       name of the makefile to generate (MAKE_GEN)
# $mstamp             string containing format of file timestamp
# $outputDir          directory where files will be created
# $stamp              string containing format of basic timestamp
# %characters         hash table of characters and their translation
# %defines            hash table of macro and their definitions
# %fileAliases        hash table of file alias and their real names
# @fileToProcess      table of files to process within project file
# @pfile              list of file names of the pages structure
# @plevel             list of file level of the pages structure
# @ptitle             list of file title of the pages structure
#
# Finally comes variables which may be modified only by gtml itself:
#
# $current            index in @supress of the current ignoring state
# $exitStatus         gtml exit status
# $filenum            file handler of read file, must be >= 5
# $ifLevel            depth of current if-command
# $hierarchyRead      has a hierarchy command been read
# $nbError            number of processing errors
# %dependencies       hash table of dependencies for each file (MAKE_GEN)
# @extensions         list of all output extensions used (MAKE_GEN)
# @lines              list of ouput lines stored when compressing is asked
# @outputFiles        list of all generated files (MAKE_GEN)
# @suppress           list of line-ignoring state coming from if/ifdef
#
# ----------------------------------------------------------------------------

# ============================================================================

@extProject = (".gtp");
@extSource  = (".gtm", ".gtml");
$extTarget  = ".html";
@configurationFiles = (".gtmlrc", "gtml.conf");
@extensions = ($extTarget);

$delim1 = "<<";
$delim2 = ">>";
$argsep = ',';

$entities = 0;
$literal = 0;
$beSilent = 0;
$compression = 0;
$generateMakefiles = 0;
$makefileName = "GNUmakefile";

@suppress = (0);
$current = 0;
$ifLevel = 0;

$exitStatus = 0;
$initialFilenum = 5;
$filenum = $initialFilenum;
$nbError = 0;
$debug = 0;

# ----------------------------------------------------------------------------
# Process the command line for informative opions.

foreach $i ( @ARGV )
{
    #
    # Show help message.
    #
    if ( $i =~ /^-h/ || $i =~ /^--help/ )
    {
        &ShowHelp();
        exit(0);
    }
    #
    # Show version
    #
    elsif ( $i =~ /^--version/ )
    {
        &ShowVersion();
        exit(0);
    }
    #
    # Do not output informations during process time.
    #
    elsif ( $i =~ /^--silent/ )
    {
        $i =~ s/^--silent//;
        $beSilent = 1;
    }
}

# ----------------------------------------------------------------------------
# Add all environment variables as defined macros.

foreach $key ( keys %ENV )
{
    &Define($key, $ENV{$key});
}

# ----------------------------------------------------------------------------
# Parse default configuration project file if present.

foreach $i ( @configurationFiles )
{
    my $confFile = $ENV{"HOME"} . "/" . $i;
    &ProcessProjectFile($confFile) if ( -r $confFile );
}

foreach $i ( @configurationFiles )
{
    &ProcessProjectFile($i) if ( -r $i );
}

# ----------------------------------------------------------------------------
# Process the command line.

foreach $i ( @ARGV )
{
    #
    # Define a macro.
    #
    if ( $i =~ /^-D/ )
    {
        $i =~ s/^-D//;
        ($key, $value) = split(/=/, $i, 2);
        &Define($key, $value);
    }
    #
    # Generate a makefile.
    #
    elsif ( $i =~ /^-M/ )
    {
        if ( $i =~ /^-M([^- \t]+)/ )
        {
            $makefileName = $1;
        }
        $generateMakefiles = 1;
    }
    #
    # Specify which file to process in the next project file.
    #
    elsif ( $i =~ /^-F/  )
    {
        $i =~ s/^-F//;
        push(@fileToProcess, $i);
    }
    #
    # Process files.
    #
    else
    {
        if ( &isProjectFile($i) )
        {
            &ProcessProjectFile($i, 1);
        }
        elsif ( &isSourceFile($i) )
        {
            &ProcessSourceFile($i, "");
        }
        else
        {
            &Warning("Skipping `$i' (unknown file type)");
        }
    }
}

if ($generateMakefiles)
{
    &GenerateMakefile();
}

&Notice("\n$nbError errors occured during process.\n") if ( $nbError != 0);
exit($exitStatus);

# ============================================================================

# ----------------------------------------------------------------------------
# Add a macro in the definition list.
 
sub Define
{
    local ($key, $value) = @_;

    #
    # Special macros.
    #
    if (    $key eq "__PERL__"
         || $key eq "__SYSTEM__"
         || $key eq "__NEWLINE__"
         || $key eq "__TAB__")
    {
        &Warning("system macros unmodifiable `$key'");
        return
    }
    @includePath = split(/:/, $value) if ( $key eq "INCLUDE_PATH" );
    $outputDir   = $value             if ( $key eq "OUTPUT_DIR" );
    $delim1      = $value             if ( $key eq "OPEN_DELIMITER" );
    $delim2      = $value             if ( $key eq "CLOSE_DELIMITER" );
    $argsep      = $value             if ( $key eq "ARGUMENT_SEPARATOR" );
    $extTarget   = $value             if ( $key eq "EXTENSION" );
    push(@extensions, $value)         if ( $key eq "EXTENSION" );
    $debug       = 1                  if ( $key eq "DEBUG" );
    &SetTimestamps()                  if ( $key eq "LANGUAGE" );

    $value = "(((BLANK)))" if ( $value eq "");
    $defines{"$key"} = $value;
}

# ----------------------------------------------------------------------------
# Add a file alias in the hash table of filename aliases.

sub DefineFilename
{
    local ($key, $value) = @_;
    if ( $value =~ /^\// )
    {
        &Error("no absolute file references allowed: $value");
        return;
    }
    $fileAliases{"$key"} = $value;
    &Define($key, $value);
}

# ----------------------------------------------------------------------------
# Define the value of each filename aliases as macros.

sub SetFileReferences
{
    foreach $key ( keys(%fileAliases) ) 
    {
        if ( &GetValue("ROOT_PATH") eq "(((BLANK)))" )
        {
            $value = $fileAliases{$key};
        }
        else
        {
            $value = &GetValue("ROOT_PATH") . $fileAliases{$key};
        }
        $value = &ChangeExtension($value);
        &Define($key, $value);
    }
}

# ----------------------------------------------------------------------------
# Get the value of a specified macro.

sub GetValue
{
    local ($key) = @_;
    return $defines{"$key"};
}

# ----------------------------------------------------------------------------
# Remove a specified macro from the list of macros.

sub Undefine
{
    local ($key) = @_;
    delete($defines{ $key });
    delete($characters{$key});
}

# ----------------------------------------------------------------------------
# Mark up a given definition in order to outline argument of a definition.

sub Markup
{
    local ($key, $value) = @_;
    my (@args, $arg, $pos, $len);
    local ($start, $oldvalue);

    if ( $key =~ /(.+)\((.+)\)/ )
    {
        #
        # Tag has parens: MACRO(x,y) ....x....y....
        #
        $key = $1;
        $arg = $2;
        @args = split($argsep, $arg);
        $start = 0;
        #
        # Verify if key is not yet defined, if yes find last argument.
        #
        $oldvalue = &GetValue($key);
        if ( ! $oldvalue eq "" )
        {
            my $s = substr($oldvalue, rindex($oldvalue, "(((MARKER"));
            if ( $s =~ /^\(\(\(MARKER([0-9])+\)\)\).*$/ )
            {
                $start = $1 + 1;
            }
        }
        #
        # Markup argument
        #
        for ($i = 0; $i <= $#args; $i++) 
        {
            $pos = index($value, $args[$i]);
            $len = length($args[$i]);
            
            while ($pos >= 0 && $len > 0) 
            {
                $j = $i + $start;
                substr($value, $pos, $len) = "(((MARKER$j)))";
                $pos = index($value, $args[$i]);
                $len = length($args[$i]);
            }
        }
    }
    return ($key, $value);
}

# ----------------------------------------------------------------------------
# Substitute all macros in the current line.

sub Substitute
{
    local (@args) = ();
    local ($key, $value, $arg);
    local ($ii);
    #
    # HTML entities may be converted.
    #
    if ($entities == 1)
    {
        #
        # The default case: substitute '<', '&', and '>'.
        #
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
    }
    #
    # User-defined characters has to be converted.
    #
    foreach $car ( keys %characters )
    {
        $ii = index($_, $car);
        while ( $ii != ($[-1) )
        {
            substr($_, $ii, length($car)) = $characters{$car};
            $ii = index($_, $car);
        }
    }
    #
    # Macros has to be replaced by their values. 
    # __NEWLINE__ and __TAB__ are substitute after all others.
    #
    $special = $delim1."__NEWLINE__".$delim2;
    $ii = index($_, $special);
    while ( $ii != ($[-1) )
    {
        substr($_, $ii, length($special)) = "__NEWLINE__";
        $ii = index($_, $special);
    }
    $special = $delim1."__TAB__".$delim2;
    $ii = index($_, $special);
    while ( $ii != ($[-1) )
    {
        substr($_, $ii, length($special)) = "__TAB__";
        $ii = index($_, $special);
    }

    $l1 = length($delim1);
    $l2 = length($delim2);

    my $more = 1;

    while ($more)
    {
        $p2 = index($_, $delim2);
        $p1 = rindex($_, $delim1, $p2);
        if ( $p2 >= $l1 )
        {
            $key = substr($_, $p1+$l1, $p2-$p1-$l2);
            if ( $key =~ /^[^ \t]+[ \t]*\(.*\)$/ )
            {
                #
                # Tag contains a keyword and arguments.
                #
                ($key, $arg) = split(/\(/, $key, 2);
                $arg =~ s/\)$//g;
                @args = &SplitArgs($arg);
            }
            if ( $key eq "__PERL__" )
            {
                $value = eval($args[0]);
            }
            elsif ( $key eq "__SYSTEM__" )
            {
                $value = qx{$args[0]};
            }
            else
            {
                $value = $defines{$key};
                for ($i = 0; $i <= $#args; $i++)
                {
                    #
                    # Argument substitution.
                    #
                    $marker = "(((MARKER$i)))";
                    $q = index($value, $marker);
                    while ($q >= 0)
                    {
                        #
                        # Substitution template contains a replacement marker.
                        #
                        $l = length($marker);
                        substr($value, $q, $l) = $args[$i];
                        $q = index($value, $marker);
                    }
                }
            }
            #
            # Make some verifications.
            #
            if ( $value eq "" 
                 && ! ($key eq "__PERL__" || $key eq "__SYSTEM__") )
            {
                &Warning("undefined name `$key'");
            }
            if ( $value =~ /\(\(\(MARKER([0-9])+\)\)\)/ )
            {
                &Error("missing argument $1");
            }
            #
            # Straightforward substitution.
            #
            $value = "" if ( $value eq "(((BLANK)))" );
            substr($_, $p1, $p2-$p1+$l2) = $value;
        }
        else
        {
            $value = "" if ( $value eq "(((BLANK)))" );
            $more = 0;
        }
    }
    s/__NEWLINE__/\n/g;
    s/__TAB__/\t/g;
}

# ----------------------------------------------------------------------------
# Split a string containing arguments into an array of argument and returns
# this array. Take care of quoted arguments, in order to allow the use of
# argument separator in argument.

sub SplitArgs
{
    local ($in) = @_;
    local (@temp) = split($argsep, $in);
    local (@args) = ();
    local ($_);

    while ($#temp >= 0) 
    {
        $_ = shift(@temp);
        if (/^"/) #"
        {
            #
            # Start of "quoted arg" detected, look for end, and add argument.
            #
            while ( ! /(^"[^"]*")/ ) #"
            {
                $_ .= $argsep . shift(@temp);
            }
            s/^"([^"]*)"/$1/; #"
            push(@args, $_);
        }
        elsif (/^'/) #'
        {
            #
            # Start of 'quoted arg' detected, look for end, and add argument.
            #
            while (! /(^'[^']*')/) #'
            { 
                $_ .= $argsep . shift(@temp);
            }
            s/^'([^']*)'/$1/; #'
            push(@args, $_);
        }
        else 
        { 
            push(@args, $_);
        }
    }
    return @args;
}

# ----------------------------------------------------------------------------
# Return 1 if given filename may be a project file, 0 else.

sub isProjectFile
{
    local ($filename) = @_;

    foreach $ext ( @extProject )
    {
        return 1 if ( $filename =~ /$ext$/i );
    }
    return 0;
}

# ----------------------------------------------------------------------------
# Return 1 if given filename may be a source file, 0 else.

sub isSourceFile
{
    local ($filename) = @_;

    foreach $ext ( @extSource )
    {
        return 1 if ( $filename =~ /$ext$/i );
    }
    return 0;
}

# ----------------------------------------------------------------------------
# Return the given source filename with extension changed according to
# $extTartget. 

sub ChangeExtension
{
    local ($file) = @_;

    foreach $ext (@extSource)
    {
        $file =~ s/\.$ext$// if ( $file =~ /\.$ext/ );
        $file =~ s/$ext$/$extTarget/ if ( $file =~ /$ext$/i );
    }

    return $file;
}

# ----------------------------------------------------------------------------
# Get the pathname of a given file.
# Always ends with a `/' if non-null.

sub GetPathname
{
    local ($name) = @_;
    
    $name =~ s/\\/\//g;   # "\" -> "/"
    $n = rindex($name, "/");
    if ( $n > $[-1 )
    {
        $name = substr($name, 0, $n+1);
    }
    else
    {
        $name = ""; # DEBUG ./
    }
    
    return $name;
}

# ----------------------------------------------------------------------------
# Get the basename of a given output file.

sub GetOutputBasename
{
    local ($name) = @_;
    
    $name =~ s/\\/\//g;   # "\" -> "/"
    $n = rindex($name, "/");
    $baseName = substr($name, $n+1);
    $baseName =~ s/$extTarget$//;
    
    return $baseName;
}

# ----------------------------------------------------------------------------
# Returns a list of all source files under the `.' directory.

sub AllSourceFiles
{
    my @files = ();
    my @dirs = (".");

    my $dir = pop(@dirs);

    while ( $dir )
    {
        opendir(DIR, $dir) || die("Can't open $dir");

        if ( $dir eq "." )
        {
            $dir = "";
        }
        else
        {
            $dir .= "/";
        }

        my $file;
        foreach $file ( grep(!/\.$/, readdir(DIR)) ) # from <niemans@acm.org>
        {
            if ( &isSourceFile($file) == 1 )
            {
                push(@files, "$dir$file");
            }
            elsif ( -d "$dir$file" )
            {
                push(@dirs, "$dir$file");
            }
        }
        $dir = pop(@dirs);
    }
    return @files;
}

# ----------------------------------------------------------------------------
# Get the path to the root directory of the project from a given a file name.
# Always end with a `/' if non-null.

sub GetPathToRoot
{
    local ($name) = @_;

    local ($basename) = $name;
    $basename =~ s/\\/\//g;     # "\" -> "/"
    $n = rindex($basename, "/");
    $basename = substr($basename, $n+1) if ( $n != $[-1 );

    local ($pathToRoot) = $name;
    $pathToRoot =~ s/$basename//g;
    $pathToRoot =~ s/[^\/\.]+\//\.\.\//g;

# DEBUG ./    $pathToRoot = "./" if ( $pathToRoot eq "" );
    return $pathToRoot;
}

# ----------------------------------------------------------------------------
# Returns the complete name of a file which may be stored anywhere in the
# @includePath.

sub ResolveIncludeFile
{
    local ($name) = @_;

    $file = &GetValue("PATHNAME") . $name;
    $file =~ s/\/\//\//g;
    $file = $name if ( &GetValue("PATHNAME") eq "(((BLANK)))" );
    if ( -r $file )
    {
        return $file;
    }
    elsif ( -r $name )
    {
        return $name;
    }

    foreach $dir (@includePath)
    {   
        $file = $dir . "/" . $name;
        $file =~ s/\/\//\//g;
        return $file if ( -r $file );
    }
    &Error("no include file `$name' in `" . &GetValue("INCLUDE_PATH") . "'");
    return "";
}

# ----------------------------------------------------------------------------
# Print the gtml version on the standard ouptut.

sub ShowHelp
{
    print (
"Usage: gtml [OPTIONS...] file...

OPTIONS:
   -M[:file]             Do not produce ouput files but generate a makefile 
                         ready to create them with gtml. If no <file> is
                         given the generated file will be called `GNUmakefile'.
   -Dmacro[=definition]  Define constant <macro> eventually defined
                         by <definition>.
   -Ffile                Do not process all files in the next project,
                         but <file>.
   --silent              Do not produce any output informations during file
                         processing.
   -h, --help            Show this help message.
   --version             Show gtml current version.

NOTES:
   Before processing command line arguments, gtml try to process project files
   `\${HOME}/.gtmlrc', `\${HOME}/gtml.conf', `./.gtmlrc' and `./gtml.conf' in
   this order, allowing one to add/modify default behavior of gtml.

   Exit status is 1 if errors have been encountered, and 0 if all was OK.

Report bugs to <beaufils\@lifl.fr>.
");
}

# ----------------------------------------------------------------------------
# Print the gtml version on the standard ouptut.

sub ShowVersion
{
    print (
"GTML version 3.5.3,
Copyright (C) 1996-1999 Gihan Perera
Copyright (C) 1999 Bruno Beaufils

GTML comes with ABSOLUTELY NO WARRANTY;
This is free software, and you are welcome to redristribute it
under the conditions defined in the GNU General Public License;
See the README or COPYING file for details.

CVS " . '$Id: gtml,v 1.36 1999/09/12 23:42:15 beaufils Exp $' . "
"); #'
}

# ----------------------------------------------------------------------------
# Print a given message, as is, on the standard output if allowed.

sub Notice
{
    local ($message) = @_;

    print($message) if ( $beSilent == 0 );
}

# ----------------------------------------------------------------------------
# Print a debug information.

sub Debug
{
    local ($message) = @_;

    print("########### " . $message) if ( $debug == 1 );
}

# ----------------------------------------------------------------------------
# Notice a given warning.

sub Warning
{
    local ($message) = @_;
    &Notice("    !!! Warning: lines $.: $message.\n") if ( ! ($. eq "") );
    &Notice("    !!! Warning: $message.\n") if ( ($. eq "") );
}

# ----------------------------------------------------------------------------
# Notice a given error.
sub Error
{
    local ($message) = @_;
    
    &Notice("    *** Error: line $.: $message.\n") if ( ! ($. eq "") );
    &Notice("    *** Error: $message.\n") if ( $. eq "" );
    $exitStatus |= 2;
    $nbError += 1;
}

# ----------------------------------------------------------------------------
# Split a given time into the following global printable values:
#
#   $sec        Seconds, 00 - 59
#   $min        Minutes, 00 - 59
#   $hour       Hours, 00 - 23
#   $wday       Day of the week, Sunday - Saturday
#   $shortwday  First three letters of month name, Sun - Sat
#   $mday       Day of the month, 1 - 31
#   $mdayth     Day of the month with particuliar extension, 1st - 31th
#   $mon        Month number, 1 - 12
#   $monthname  Full month name, January - December
#   $shortmon   First three letters of month name, Jan - Dec
#   $year       Full year (e.g. 1996)
#   $syear      Last two digits of year (e.g. 96)

sub SplitTime
{
    ($sec, $min, $hour, $mday, $mon, $syear, $wday, $yday, $isdst) = @_;

    #
    # Month and Weekdays are defined differently in each language.
    #
    if ( &GetValue("LANGUAGE") eq "fr" )
    {
        @Month = ( "Janvier", "F�vrier", "Mars",
                   "Avril", "Mai", "Juin", 
                   "Juillet", "Ao�t", "Septembre", 
                   "Octobre", "Novembre", "D�cembre" );
        @WeekDay = ( "Dimanche", "Lundi", "Mardi",
                     "Mercredi", "Jeudi", "Vendredi", "Samedi" );
        $mdayth = $mday;
        $mdayth = "1er" if ($mday == 1);
    }
    # "no" thanks to Helmers, Jens Bloch <Jens.Bloch.Helmers@dnv.com>
    elsif ( &GetValue("LANGUAGE") eq "no" )
    {
        @Month = ( "januar", "februar", "mars", 
                   "april", "mai", "juni",
                   "juli", "august", "september", 
                   "oktober", "november", "desember" );
        @WeekDay = ( "S�ndag", "Mandag", "Tirsdag",
                     "Onsdag", "Torsdag", "Fredag", "L�rdag" );
        $mdayth = $mday . ".";
    }
    # "se" thanks to magog, <magog@swipnet.se>
    elsif ( &GetValue("LANGUAGE") eq "se" )
    {
        @Month = ( "januari", "februari", "mars", 
                   "april", "maj", "juni",
                   "juli", "augusti", "september", 
                   "oktober", "november", "december" );
        @WeekDay = ( "S�ndag", "M�ndag", "Tisdag","Onsdag",
                     "Torsdag", "Fredag", "L�rdag" );
        $mdayth = $mday; # XXX: Not verified
    }
    # "it" thanks to Pioppo, <pioppo@4net.it>
    elsif ( &GetValue("LANGUAGE") eq "it" )
    {
        @Month = ( "Gennaio", "Febbraio", "Marzo", 
                   "Aprile", "Maggio", "Giugno",
                   "Luglio", "Agosto", "Settembre", 
                   "Ottobre", "Novembre", "Dicembre" );
        @WeekDay = ( "Domenica", "Luned�", "Marted�", "Mercoled�", 
                     "Gioved�", "Venerd�", "Sabato" );
        $mdayth = $mday;
    }
    # "nl" thanks to Gert-Jan Brink <gertjan@code4u.com>
    elsif ( &GetValue("LANGUAGE") eq "nl" )
    {
        @Month = ( "januari", "februari", "maart", 
                   "april", "mei", "juni",
                   "juli", "augustus", "september", 
                   "oktober", "november", "december" );
        @WeekDay = ( "zondag", "maandag", "dinsdag", "woensdag",
                     "donderdag", "vrijdag", "zaterdag" );
        $mdayth = $mday;
    }    
    # "de" thanks to Uwe Arzt <uwe.arzt@robots.de>
    elsif ( &GetValue("LANGUAGE") eq "de" )
    {
        @Month = ( "Januar", "Februar", "M�rz", 
                   "April", "Mai", "Juni",
                   "Juli", "August", "September", 
                   "Oktober", "November", "Dezember" );
        @WeekDay = ( "Sonntag", "Montag", "Dienstag",
                     "Mittwoch", "Donnerstag", "Freitag", "Samstag" );
        $mdayth = $mday;
    }
    # "ie" thanks to Ken Guest <kengu@credo.ie>
    elsif ( &GetValue("LANGUAGE") eq "ie" )
    {
        @Month = ( "En�ir", "Feabhra", "M�rta", 
                   "Bealtaine", "Aibre�n", "Meitheamh",
                   "L�il", "L�nasa", "M�an Fomhair", 
                   "Deireadh Fomhair", "Samhain", "M� na Nollaig" );
        @WeekDay = ( "Domhnach", "Luan", "M�irt",
                     "C�adaoin", "D�ardaoin", "Aoine", "Satharn" );
        $mdayth = $mday . ".";
    }
    # default is english.
    else 
    {
        @Month = ( "January", "February", "March", 
                   "April", "May", "June",
                   "July", "August", "September", 
                   "October", "November", "December" );
        @WeekDay = ( "Sunday", "Monday", "Tuesday",
                     "Wednesday", "Thursday", "Friday", "Saturday" );
        $mdayth = $mday . "th";
        # from <agre3@ironbark.bendigo.latrobe.edu.au>
        $mdayth = $mday . "st" if ($mday == 1 || $mday == 21 || $mday == 31);
        $mdayth = $mday . "nd" if ($mday == 2 || $mday == 22);
        $mdayth = $mday . "rd" if ($mday == 3 || $mday == 23);
    }
        
    $sec  = sprintf("%02d", $sec);
    $min  = sprintf("%02d", $min);
    $hour = sprintf("%02d", $hour);

    $wday = $WeekDay[$wday]; # from <agre3@ironbark.bendigo.latrobe.edu.au>
    $shortwday = substr($wday, 0, 3);

    $monthname = $Month[$mon];
    $shortmon  = substr($monthname, 0, 3);

    $year = $syear + 1900;
    $syear = substr($year, -2, 2);
    $mon++;                     # Because it starts from 0
}

# ----------------------------------------------------------------------------
# Returns a printable time/date string based on a given format string.
#
# The format string is passed in the variable $stamp, and the following
# substitutions are made in it:
#
#   $ss         -> seconds
#   $mm         -> minutes
#   $hh         -> hour
#   $Ddd        -> Short weekday name (Sun - Sat)
#   $Day        -> full weekday name
#   $dd         -> day of the month
#   $ddth       -> day of the month with th extension
#   $MM         -> month number (1 - 12)
#   $Mmm        -> short month name (Jan - Dec)
#   $Month      -> full month name
#   $yyyy       -> full year (e.g. 1996)
#   $yy         -> short year (e.g. 96)
#
# Make sure you call "SplitTime" first to initialise time global variables,
# i.e time to format. 

sub FormatTimestamp
{
    local ($stamp) = @_;

    $stamp =~ s/\$ss/$sec/g;
    $stamp =~ s/\$mm/$min/g;
    $stamp =~ s/\$hh/$hour/g;
    $stamp =~ s/\$Ddd/$shortwday/g;
    $stamp =~ s/\$Day/$wday/g;
    $stamp =~ s/\$ddth/$mdayth/g;
    $stamp =~ s/\$dd/$mday/g;
    $stamp =~ s/\$MM/$mon/g;
    $stamp =~ s/\$Month/$monthname/g;
    $stamp =~ s/\$Mmm/$shortmon/g;
    $stamp =~ s/\$yyyy/$year/g;
    $stamp =~ s/\$yy/$syear/g;

    return $stamp;
}

# ----------------------------------------------------------------------------
# Defines eventual timestamps macros.

sub SetTimestamps
{
    local($name) = @_;
    if ( ! $stamp eq "" )
    {
        &SplitTime(localtime);
        &Define("TIMESTAMP", &FormatTimestamp($stamp));
    }       
    if ( ! $mstamp eq ""  && ! $name eq "" )
    {
        &SplitTime(localtime((stat($name))[9]));
        &Define("MTIMESTAMP", &FormatTimestamp($mstamp));
    }
}

# ----------------------------------------------------------------------------
# Read a source line into a given file. Source lines may be written on
# multiple lines via `\' character at the end.

sub ReadLine
{
    local ($file) = @_;
    local ($line);
    #
    # Read a line from input file.
    #
    $_ = <$file>;
    while ( /\\\n$/ )
    {
        #
        # We are on multilines, so remove last `\'.
        #
        s/\\\n$//g;
        #
        # Read a new line from input file.
        #
        $_ .= <$file>;
    }
    return $_ ;
}

# ----------------------------------------------------------------------------
# What to do with a given project file. If second argument is 0 then source
# files will not be processed (i.e. means the routine is called for an
# included project file).

sub ProcessProjectFile
{
    local ($name, $process) = @_;
    local ($file);
    local ($STREAM);
    local ($hierarchyRead) = 0;

    if ( $process )
    {
        &Notice("=== Project file $name ===\n");
        $STREAM = 3;
    }
    else
    {
        &Notice ("--- Included project file $name ---\n");
        $STREAM = 4;
    }

    open($STREAM, $name);

    while ( &ReadLine($STREAM) )
    {
        #
        # Skip blank and comment lines.
        #
        next if ( /^\/\// );
        next if ( /^[ \t]*$/ );
        #
        # Next parse the if(def)/elsif/else/endif to decide if we want to
        # suppress any lines. 
        #
        if ( /^if/ || /^elsif/ )
        {
            chop;
            if ( /^if/ )
            {
                $ifLevel += 1;
                $wasIf = 1;
            }
            else
            {
                s/^els//g;
                $wasIf = 0;
            }
            next if ( $wasIf && $suppress[$current]);
            &Substitute();
            if ( /^ifdef/ || /^ifndef/ )
            {
                ( $dummy, $var ) = split(/[ \t]+/, $_);
                $supp = ( &GetValue($var) eq "" );
                $supp = ! $supp if ( /^ifndef/ );
            }
            else
            {
                ( $dummy, $var, $comp, $value ) = split(/[ \t]+/, $_, 4);
                if ( $comp eq "==" )
                {
                    $supp = ! ( $var eq $value );
                }
                elsif ( $comp eq "!=" )
                {
                    $supp = ( $var eq $value );
                }
                else
                {
                    &Error("unknown comparator $comp");
                    $supp = 1;
                }
            }
            if ( $wasIf )
            {
                push(@suppress, $supp);
                $current = $ifLevel if ( ! $suppress[$current] );
            }
            else
            {
                $suppress[$ifLevel] = $supp;
            }
            next;
        }
        elsif ( /^else/ )
        {
            $suppress[$ifLevel] = ! $suppress[$ifLevel];
            next;
        }
        elsif ( /^endif/ )
        {
            if ( $ifLevel == 0 )
            {
                &Error("unmatched endif");
            }
            else
            {
                pop(@suppress);
                $current -= 1 if ( $current == $ifLevel );
                $ifLevel -= 1;
            }
            next;
        }
        #
        # Skip lines if current ignoring state says so.
        #
        next if ( $suppress[$current] );
        #
        # Characters translation can be defined here.
        #
        if ( /^definechar[ \t]/ )
        {
            chop;
            ( $dummy, $key, $value ) = split( /[ \t]+/, $_, 3 );
            $characters{$key} = $value;
        }
        #
        # Macros can be defined here.
        #
        elsif ( /^define[ \t]/ )
        {
            chop;
            ( $dummy, $key, $value ) = split( /[ \t]+/, $_, 3 );
            if ( $key =~ /(.+)\((.+)\)/ )
            {
                &Undefine($1);
            }
            ( $key, $value ) = &Markup($key, $value);
            &Define($key, $value);
        }
        elsif ( /^newdefine[ \t]/ )
        {
            chop;
            ( $dummy, $key, $value ) = split( /[ \t]+/, $_, 3 );
            if ( ! &GetValue($key) eq "" ) 
            {
                next;
            }
            ( $key, $value ) = &Markup($key, $value);
            &Define($key, $value);
        }
        elsif ( /^define\!/ )
        {
            chop;
            &Substitute();
            ( $dummy, $key, $value ) = split( /[ \t]+/, $_, 3 );
            if ( $key =~ /(.+)\((.+)\)/ )
            {
                &Undefine($1);
            }
            ( $key, $value ) = &Markup($key, $value);
            &Define($key, $value);
        }
        elsif ( /^newdefine!/ )
        {
            chop;
            &Substitute();
            ( $dummy, $key, $value ) = split( /[ \t]+/, $_, 3 );
            if ( ! &GetValue($key) eq "" ) 
            {
                next;
            }
            ( $key, $value ) = &Markup($key, $value);
            &Define($key, $value);
        }
        elsif ( /^define\+/ )
        {
            chop;
            ( $dummy, $key, $value ) = split( /[ \t]+/, $_, 3 );
            ( $key, $value ) = &Markup($key, $value);
            &Define($key, &GetValue($key) . $value);
        }
        elsif ( /^undef[ \t]/ )
        {
            chop;
            ( $dummy, $key ) = split ( /[ \t]+/, $_);
            &Undefine($key);
        }
        #
        # Saving bandwidth file compression eliminates anything not necessary
        # for correct display of content on the client browser.
        #
        elsif ( /^compress/ )
        {
            chop;
            ( $dummy, $switch ) = split(/[ \t]+/, $_);

            if ( $switch =~ /^ON$/i )
            {
                $compression = 1;
            }
            elsif ( $switch =~ /^OFF$/i )
            {
                $compression = 0;
            }
            else
            {
                &Error("expecting compress as `ON' or `OFF'");
            }
        }
        #
        # Timestamp format can be defined here.
        #
        elsif ( /^timestamp[ \t]/ )
        {
            chop;
            ( $dummy, $stamp ) = split(/[ \t]/, $_, 2);
        }
        elsif ( /^mtimestamp[ \t]/ )
        {
            chop;
            ( $dummy, $mstamp ) = split(/[ \t]/, $_, 2);
        }
        #
        # Filenames aliases can be defined here.
        #
        elsif ( /^filename[ \t]/ )
        {
            chop;
            &Substitute();
            ( $dummy, $key, $value ) = split(/[ \t]+/, $_, 3);
            &DefineFilename($key, $value);
        }
        #
        # Included files.
        #
        elsif ( /^include[ \t]/ )
        {
            chop;
            &Substitute();
            s/^include[ \t]*"//;
            s/".*$//; #"
            $file = $_;
            $file = &ResolveIncludeFile($file);
            $dependencies{$name} .= "$file ";
            &ProcessProjectFile($file, 0);
        }
        #
        # They can ask for all source files here.
        #
        elsif ( /^allsource/ )
        {
            foreach $file ( &AllSourceFiles() )
            {
                &ProcessSourceFile($file, $name);
            }
        }
        #
        # They can ask for hierarchy files process.
        #
        elsif ( /^hierarchy/ )
        {
            for ( $ii = 0; $ii <= $#pfile; $ii += 1)
            {
                &SetLinks();
                &ProcessSourceFile($pfile[$ii], $name, " ($plevel[$ii])");
            }
            $hierarchyRead = 1;
        }
        #
        # Everything else must be a source file name.
        #
        else
        {
            chop;
            &Substitute();
            s/\s+/ /g;
            ( $file, $level, $title ) = split(/\s/, $_, 3);

            $file = $fileAliases{$file} if ( defined($fileAliases{$file}) );
            
            if ( $file =~ /^\// )
            {
                &Error("no absolute file references allowed: $file");
                next;
            }
            
            if ( &isSourceFile($file) )
            {
                if ( $level eq "" )
                {
                    &ProcessSourceFile($file, $name);
                }
                else
                {
                    $lkey = "__TOC_" . $level . "__";
                    if ( ! defined($defines{$lkey}) )
                    {
                        &Define($lkey, "<ul>(((MARKER0)))</ul>");
                    }
                    $lkey = "__TOC_" . $level . "_ITEM__";
                    if ( ! defined($defines{$lkey}) )
                    {
                        &Define($lkey, "<li><a href=\"(((MARKER0)))\">(((MARKER1)))</a>");
                    }
                    push(@pfile, $file);
                    push(@plevel, $level);
                    push(@ptitle, $title);
                }
            }
            else
            {
                &Warning("Skipping `$_' (unknown file type)");
            }
        }
    }

    #
    # Process files with links to others.
    #
    if ( ! $hierarchyRead )
    {
        for ( $ii = 0; $ii <= $#pfile; $ii += 1)
        {
            &SetLinks();
            &ProcessSourceFile($pfile[$ii], $name, " ($plevel[$ii])");
        }
    }
    #
    # Clean up a bit.
    #
    if ($process)
    {
        undef(@fileToProcess);
        undef(@pfile);
        undef(@plevel);
        undef(@ptitle);
    }

    close $STREAM;
}

# ----------------------------------------------------------------------------
# Add macros used for link to other pages for files with links to others.

sub SetLinks
{
    #
    # Be sure that there is nothing defined.
    #
    &Undefine("TITLE_CURRENT");
    &Undefine("TITLE_UP");
    &Undefine("TITLE_NEXT");
    &Undefine("TITLE_PREV");
    &Undefine("LINK_UP");
    &Undefine("LINK_NEXT");
    &Undefine("LINK_PREV");    
    #
    # All links are relative to the root directory.
    #
    local ($pathToRoot) = &GetPathToRoot($pfile[$ii]);

    &Define("TITLE_CURRENT", $ptitle[$ii]);

    #
    # Go up one level.
    #
    my $up_file;

    $i = $ii - 1;
    while ($i >= 0 && $plevel[$i] >= $plevel[$ii])
    {
        --$i;
    }

    if ($i >= 0 && $plevel[$i] < $plevel[$ii])
    {
        if ( $pfile[$i] =~ /^\// )
        {
            &Define("LINK_UP", &ChangeExtension("$pfile[$i]"));
        }
        else
        {
            &Define("LINK_UP", &ChangeExtension("$pathToRoot$pfile[$i]"));
        }
        &Define("TITLE_UP", $ptitle[$i]);
        $up_file = $pfile[$i];
    }
    else
    {
        &Undefine("LINK_UP");
        &Undefine("TITLE_UP");
    }

    #
    # Previous document.
    #
    $i = $ii - 1;

    if ($i >= 0 && $pfile[$i] && $pfile[$i] ne $up_file)
    {
        if ( $pfile[$i] =~ /^\// )
        {
            &Define("LINK_PREV", &ChangeExtension("$pfile[$i]"));
        }
        else
        {
            &Define("LINK_PREV", &ChangeExtension("$pathToRoot$pfile[$i]"));
        }
        &Define("TITLE_PREV", $ptitle[$i]);
    }
    else
    {
        &Undefine("LINK_PREV");
        &Undefine("TITLE_PREV");
    }

    #
    # Next document.
    #
    $i = $ii + 1;

    if ($pfile[$i])
    {
        if ( $pfile[$i] =~ /^\// )
        {
            &Define("LINK_NEXT", &ChangeExtension("$pfile[$i]"));
        }
        else
        {
            &Define("LINK_NEXT", &ChangeExtension("$pathToRoot$pfile[$i]"));
        }
        &Define("TITLE_NEXT", $ptitle[$i]);
    }
    else
    {
        &Undefine("LINK_NEXT");
        &Undefine("TITLE_NEXT");
    }
}

# ----------------------------------------------------------------------------
# Generate a complete SiteMap using predefined macros __TOC_x__, and
# __TOC_x_ITEM__. Almost all ideas and code comes from <Uwe.Arzt@t-mobil.de>,
# and <marquet@lifl.fr>.
 
sub GenSiteMap
{
    $levelold = 0;
    $_ = "";
    for ( $xx = 0; $xx <= $#pfile; ++$xx )
    {
        $f = $pfile[$xx];
        $f = &ChangeExtension($f);
        if($levelold < $plevel[$xx])
        {
            $_ .= (" " x (($plevel[$xx]-1) * 2)) 
                . $delim1."__TOC_".$plevel[$xx]."__(\'"
                . $delim1."__NEWLINE__".$delim2;
            $_ .= (" " x (($plevel[$xx]-1) * 2 + 2))
                . $delim1."__TOC_".$plevel[$xx]
                . "_ITEM__(\'".$f."\'".$argsep."\'".$ptitle[$xx]."\')"
                . $delim2.$delim1."__NEWLINE__".$delim2;
        }
        if($levelold == $plevel[$xx]) 
        {
            $_ .= (" " x (($plevel[$xx]-1) * 2 + 2))
                . $delim1."__TOC_".$plevel[$xx]
                . "_ITEM__(\'".$f."\'".$argsep."\'".$ptitle[$xx]."\')"
                . $delim2.$delim1."__NEWLINE__".$delim2;
        }
        if ($levelold > $plevel[$xx]) 
        {
            $_ .= (" " x ($plevel[$xx] * 2))
                . "\')".$delim2.$delim1."__NEWLINE__".$delim2;
            $_ .= (" " x (($plevel[$xx]-1) * 2 + 2))
                . $delim1."__TOC_".$plevel[$xx]
                . "_ITEM__(\'".$f."\'".$argsep."\'".$ptitle[$xx]."\')"
                . $delim2.$delim1."__NEWLINE__".$delim2;
        }
        $levelold = $plevel[$xx];
    }
    for($xx = $levelold; $xx > 0; --$xx) 
    {
        $_ .= (" " x (($plevel[$xx]-2) * 2)) 
            . "\')".$delim2.$delim1."__NEWLINE__".$delim2;
    }
    &Substitute();
}

# ----------------------------------------------------------------------------
# Returns the output name of a given source filename.

sub ResolveOutputName
{
    local ($file) = @_;

    $file = &ChangeExtension($file);

    $file = "$outputDir/$file" if ( $outputDir ne "" && $file !~ /^\// );

    #
    # Make sure the directory exists for the output file.
    #
    $n = 0;
    while ( $n != ($[-1) )
    {
        $n = index($file, "/", $n);

        $n = 1 if ( $n == 0 );

        if ( $n != ($[-1) )
        {
            $dir = substr($file, 0, $n);
            mkdir($dir, 0755) if ( ! -d $dir ); # from <magog@swipnet.se>
            ++$n;
        }
    }

    return $file;
}

# ----------------------------------------------------------------------------
# Return 1 if a given string is a member of a given list 0 else.

sub Member
{
    local ($elt, @list) = @_;

    foreach $val (@list)
    {
        return 1 if ( $val eq $elt );
    }
    return 0;
}

# ----------------------------------------------------------------------------
# What to do with a given source file. The level of the page in the document
# may be given.

sub ProcessSourceFile
{
    local ($name, $parent, $level) = @_;
    local ($oname);
    @lines = ();

    %saveDefines = %defines;
    %saveCharacters = %characters;

    #
    # Process source files only if asked.
    #
    if ( defined(@fileToProcess) && ! (&Member($name, @fileToProcess)) )
    {
        return;
    }

    &Notice("--- $name$level ---\n");

    if ( ! -r $name )
    {
        &Error("`$name' unreadable");
    }
    else
    {
        $oname = &ResolveOutputName($name);
        &Define("ROOT_PATH", &GetPathToRoot($name));
        &Define("BASENAME", &GetOutputBasename($oname));
        &Define("FILENAME", "$baseName$extTarget");
        &Define("PATHNAME", &GetPathname($name));
        if ( $name eq $oname )
        {
            &Error("source `$name' same as target `$oname'");
        }
        else
        {
            $dependencies{$oname} .= "$parent $name";
            push(@outputFiles, $oname);
            #
            # if FAST_GENERATION process files only if newer than output.
            #
            if ( !defined($defines{"FAST_GENERATION"}) 
                 || ((stat($name))[9] > (stat($oname))[9]))
            {
                &SetFileReferences();
                &SetTimestamps($name);
                open(OUTFILE, ">$oname") if (!$generateMakefiles);
                &ProcessLines($name);
                close OUTFILE if (!$generateMakefiles);
            } 
            else 
            { 
                &Warning("output more recent than input, nothing done");
            }
        }
    }
    %defines = %saveDefines;
    %characters = %saveCharacters;
}

# ----------------------------------------------------------------------------
# Compresses all lines, removing all thing not necessary for a browser.

sub CompressLines
{
    local ($_) = join(' ', @lines);

    @lines = ();

    #
    # Translate tabs and linefeed into spaces.
    #
    tr/\t\n/ /;

    #
    # Discard all comments.
    #
    $del1 = '<!--';             $len1 = length( $del1 );
    $del2 = '-->';              $len2 = length( $del2 );

    while (1)
    {
        $p1 = index($_, $del1);
        $p2 = index($_, $del2);

        if ( $p1 >= 0 && $p2 >= 0 && $p2 > $p1 )
        {
            substr($_, $p1, $p2-$p1+$len2) = '';
        }
        else 
        {
            last;
        }
    }

    # 
    # Squeeze all multiple spaces. Terminate the compressed sequence by \n
    #
    tr/ / /s;
    if ( substr($_, length($_), 1) eq ' ' ) 
    { 
        chop;
    }
    return $_ . "\n";
}

# ----------------------------------------------------------------------------
# Process lines of a source file.

sub ProcessLines
{
    local ($iname) = @_;
    local ($INFILE) = $filenum++;

    if ( ! -r $iname )
    {
        &Error("`$iname' unreadable");
        return;
    }

    open($INFILE, $iname);

    while ( &ReadLine($INFILE) )
    {
        #
        # Allow GTML commands inside HTML comments.
        #
        if ( /<!-- ###/ )
        {
            s/<!-- ##//;
            s/|-->.*$//;
            s/\s*-->.*$//;
        }
        #
        # Parse '#literal' command because if literal processing is ON,
        # we simply print the line and continue to the next line.
        #
        if ( /^#literal/ )
        {
            chop;
            ( $dummy, $switch ) = split(/[ \t]+/, $_);
            if ( $switch =~ /^ON$/i )
            {
                $literal = 1;
            }
            elsif ( $switch =~ /^OFF$/i )
            {
                $literal = 0;
            }
            else
            {
                &Error("expecting \#literal as `ON' or `OFF'");
            }
            next;
        }
        if ( $literal )
        {
            if ( $compression ) 
            { 
                print(OUTFILE &CompressLines);
            }
            &Substitute();
            print(OUTFILE $_);
            next;
        }
        #
        # Next parse the if(def)/elsif/else/endif to decide if we want to
        # suppress any lines. 
        #
        if ( /^#if/ || /^#elsif/ )
        {
            chop;
            if ( /^#if/ )
            {
                $ifLevel += 1;
                $wasIf = 1;
            }
            else
            {
                s/^#els/#/g;
                $wasIf = 0;
            }
            next if ( $wasIf && $suppress[$current]);
            &Substitute();
            if ( /^#ifdef/ || /^#ifndef/ )
            {
                ( $dummy, $var ) = split(/[ \t]+/, $_);
                $supp = ( &GetValue($var) eq "" );
                $supp = ! $supp if ( /^#ifndef/ );
            }
            else
            {
                ( $dummy, $var, $comp, $value ) = split(/[ \t]+/, $_, 4);
                if ( $comp eq "==" )
                {
                    $supp = ! ( $var eq $value );
                }
                elsif ( $comp eq "!=" )
                {
                    $supp = ( $var eq $value );
                }
                else
                {
                    &Error("unknown comparator `$comp'");
                    $supp = 1;
                }
            }
            if ( $wasIf )
            {
                push(@suppress, $supp);
                $current = $ifLevel if ( ! $suppress[$current] );
            }
            else
            {
                $suppress[$ifLevel] = $supp;
            }
            next;
        }
        elsif ( /^#else/ )
        {
            $suppress[$ifLevel] = ! $suppress[$ifLevel];
            next;
        }
        elsif ( /^#endif/ )
        {
            if ( $ifLevel == 0 )
            {
                &Error("unmatched \#endif");
            }
            else
            {
                pop(@suppress);
                $current -= 1 if ( $current == $ifLevel );
                $ifLevel -= 1;
            }
            next;
        }
        #
        # Skip lines if current ignoring state says so.
        #
        next if ( $suppress[$current] );
        #
        # Now do others commands.
        #
        if ( /^#entities/ )
        {
            chop;
            ( $dummy, $switch ) = split(/[ \t]+/, $_);
            
            if ( $switch =~ /^ON$/i )
            {
                $entities = 1;
            }
            elsif ( $switch =~ /^OFF$/i )
            {
                $entities = 0;
            }
            else
            {
                &Error("expecting \#entities as `ON' or `OFF'");
            }
            next;
        }
        #
        # Included files.
        #
        elsif ( /^#include/ )
        {
            chop;
            if ( $compression ) 
            { 
                print(OUTFILE &CompressLines);
            }

            &Substitute();
            s/^#include[ \t]*"//;
            s/".*$//; #"
            $file = $_;
            $file = &ResolveIncludeFile($file);
            $dependencies{$iname} .= "$file ";
            if ( $file ne "" )
            {
# TODO #                &Notice("    --- $file\n");
                &ProcessLines($file);
            }
            next;
        }
        #
        # Characters translation can be defined here.
        #
        if ( /^#definechar[ \t]/ )
        {
            chop;
            ( $dummy, $key, $value ) = split( /[ \t]+/, $_, 3 );
            $characters{$key} = $value;
        }
        #
        # Macros can be defined here.
        #
        elsif ( /^#define[ \t]/ )
        {
            chop;
            ( $dummy, $key, $value ) = split( /[ \t]+/, $_, 3 );
            if ( $key =~ /(.+)\((.+)\)/ )
            {
                &Undefine($1);
            }
            ( $key, $value ) = &Markup($key, $value);
            &Define($key, $value);
        }
        elsif ( /^#newdefine[ \t]/ )
        {
            chop;
            ( $dummy, $key, $value ) = split( /[ \t]+/, $_, 3 );
            if ( ! &GetValue($key) eq "" ) 
            {
                next;
            }
            ( $key, $value ) = &Markup($key, $value);
            &Define($key, $value);
        }
        elsif ( /^#define\!/ )
        {
            chop;
            &Substitute();
            ( $dummy, $key, $value ) = split( /[ \t]+/, $_, 3 );
            if ( $key =~ /(.+)\((.+)\)/ )
            {
                &Undefine($1);
            }
            ( $key, $value ) = &Markup($key, $value);
            &Define($key, $value);
        }
        elsif ( /^#newdefine!/ )
        {
            chop;
            &Substitute();
            ( $dummy, $key, $value ) = split( /[ \t]+/, $_, 3 );
            if ( ! &GetValue($key) eq "" ) 
            {
                next;
            }
            ( $key, $value ) = &Markup($key, $value);
            &Define($key, $value);
        }
        elsif ( /^#define\+/ )
        {
            chop;
            ( $dummy, $key, $value ) = split( /[ \t]+/, $_, 3 );
            ( $key, $value ) = &Markup($key, $value);
            &Define($key, &GetValue($key) . $value);
        }
        elsif ( /^#undef[ \t]/ )
        {
            chop;
            ( $dummy, $key ) = split ( /[ \t]+/, $_);
            &Undefine($key);
        }
        #
        # Saving bandwidth file compression eliminates anything not necessary
        # for correct display of content on the client browser.
        #
        elsif ( /^#compress/ )
        {
            chop;
            ( $dummy, $switch ) = split(/[ \t]+/, $_);

            if ( $switch =~ /^ON$/i )
            {
                $compression = 1;
            }
            elsif ( $switch =~ /^OFF$/i )
            {
                print(OUTFILE &CompressLines) if ( $compression );
                $compression = 0;
            }
            else
            {
                &Error("expecting \#compress as `ON' or `OFF'");
            }
        }
        #
        # Table of contents can be used here.
        #
        elsif ( /^#toc/ || /^#sitemap/ )
        {
            &GenSiteMap();
            if ( $compression )
            {
                push(@lines, $_);
            }
            else
            {
                print(OUTFILE $_);
            }       
        }
        #
        # Timestamp format can be defined here.
        #
        elsif ( /^#timestamp[ \t]/ )
        {
            chop;
            ( $dummy, $stamp ) = split(/[ \t]/, $_, 2);
            &SetTimestamps( $iname );
        }
        elsif ( /^#mtimestamp[ \t]/ )
        {
            chop;
            ( $dummy, $mstamp ) = split(/[ \t]/, $_, 2);
            &SetTimestamps( $iname );
        }
        #
        # Normal lines.
        #
        elsif ( ! /^#/ )
        {
            &Substitute();
            if ( $compression )
            {
                push(@lines, $_);
            }
            else
            {
                print(OUTFILE $_);
            }
        }
    }
    if ( $compression )
    {
        print(OUTFILE &CompressLines);  
    }
    close $INFILE;
    $filenum--;
}

# ----------------------------------------------------------------------------
# Generate a makefile from dependencies.

sub GenerateMakefile
{
    open(OUTFILE, ">$makefileName");
    #
    # makefile basics.
    #
    print(OUTFILE "# GTML generated makefile, usable with GNU make.\n");
    print(OUTFILE "\n");
    print(OUTFILE "GTML = gtml\n");
    print(OUTFILE "RM   = rm\n");
    print(OUTFILE "\n");
    print(OUTFILE ".SUFFIXES: " 
          . join(' ', @extProject) 
          . ' ' 
          . join(' ', @extSource) 
          . ' ' 
          . join(' ', @extensions));
    print(OUTFILE "\n");
    print(OUTFILE ".PHONY: clean\n");
    print(OUTFILE "\n");
    #
    # Generated files list.
    #
    print(OUTFILE "##############\n");
    print(OUTFILE "# Files list #\n");
    print(OUTFILE "##############\n");
    print(OUTFILE "\n");
    print (OUTFILE "OUTPUT_FILES = \\\n");
    for ($i = 0; $i < $#outputFiles; $i++)
    {
        print(OUTFILE "\t$outputFiles[$i] \\\n");
    }
    print(OUTFILE "\t$outputFiles[$#outputFiles]\n");
    print(OUTFILE "\n");
    #
    # Rules.
    #
    print(OUTFILE "#####################\n");
    print(OUTFILE "# Processsing rules #\n");
    print(OUTFILE "#####################\n");
    print(OUTFILE "\n");
    print(OUTFILE "all: \$(OUTPUT_FILES)\n");
    print(OUTFILE "\n");
    print(OUTFILE "clean:\n");
    print(OUTFILE "\t-\$(RM) \$(OUTPUT_FILES)\n");
    print(OUTFILE "\t-\$(RM) *~\n");
    print(OUTFILE "\n");
    $outputDir .= "/" if ( ! ($outputDir eq "") );
    $outputDir =~ s/\/\//\//g;
    foreach $ext ( @extSource )
    {
        foreach $ext2 ( @extensions )
        {
            print(OUTFILE "$outputDir\%$ext2: \%$ext\n");
            print(OUTFILE "\t\$(GTML) -F\$< \$(word 1, \$(word 2, \$^) \$<)\n");
            print(OUTFILE "\n");
        }
    }
    #
    # Dependencies.
    #
    print(OUTFILE "#####################\n");
    print(OUTFILE "# File dependencies #\n");
    print(OUTFILE "#####################\n");
    print(OUTFILE "\n");
    foreach $file ( keys(%dependencies) )
    {
        $dependencies{$file} =~ s/^ //;
        print(OUTFILE "$file: $dependencies{$file}\n");
        if ( ! &Member($file, @outputFiles) )
        {
            print(OUTFILE "\ttouch \$\@\n");
        }
        elsif ( ! ($file =~ /$extTarget$/) )
        {
            print(OUTFILE "\t\$(GTML) -F\$(word 2, \$^) \$(word 1, \$^)\n");
        }
    }
    print(OUTFILE "\n");
    print(OUTFILE "# End of makefile.\n");
    close(OUTFILE);
}

# ----------------------------------------------------------------------------
# Well you may ask why sometimes I add some stupid comments like #' or #", the
# answer is simple: I use emacs, and color syntaxing with font-lock-mode and
# when it does not find matching, i.e closing, " or ' it color the text as
# string until a closing one, which is really not pleasant. Giving it what it
# looks for is the simplest trick I found to correct that.
# -Bruno
# ----------------------------------------------------------------------------
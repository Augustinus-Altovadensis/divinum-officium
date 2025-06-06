#!/usr/bin/perl
use utf8;

# Name : Laszlo Kiss
# Date : 01-25-08
# horas common files to reconcile tempora & sancti also for missa
# use warnings;
# use strict;
use FindBin qw($Bin);
use lib "$Bin/..";
use horas::Scripting qw(dispatch_script_function parse_script_arguments);
use DivinumOfficium::Date qw(getweek leapyear geteaster get_sday nextday day_of_week monthday);
use DivinumOfficium::Directorium qw(get_kalendar get_transfer get_tempora transfered );

sub error {
	my $t = shift;
	our $error .= "= $t =<br>";
}

#*** checkfile($lang, $filename)
# substitutes English if no $lang item, Latin if no English
# if $lang contains dash, the part before the last dash is taken as a fallback recursively (till something exists)
sub checkfile {
	my $lang = shift;
	my $file = shift;
	our $datafolder;
	
	if (-e "$datafolder/$lang/$file") {
		return "$datafolder/$lang/$file";
	} elsif ($lang =~ /-/) {
		my $temp = $lang;
		$temp =~ s/-[^-]+$//;
		return checkfile($temp, $file);
	} elsif ($lang =~ /english/i) {
		return "$datafolder/Latin/$file";
	} elsif (-e "$datafolder/English/$file") {
		return "$datafolder/English/$file";
	} else {
		return "$datafolder/Latin/$file";
	}
}

sub occurrence {
	my($day, $month, $year, $version, $tomorrow) = @_;  # sort out occurence for the day or the next day in case of $tomorrow

	# globals readonly
	our($testmode, $hora, $missa, $caller, $datafolder, $lang2);
	
	# globals set/mod here
	our($winner, $rank, $commemoratio, $comrank, $commune, $communetype);
	our($tname, $sname, $sanctoraloffice);
	our(@trank, @srank, @commemoentries);
	our(%tempora, %saint);
	our($initia, $scriptura, $laudesonly, $commemorated, $seasonalflag);
	our $transfervigil = '';
	our($vespera, $cvespera);
	our($tvesp, $svesp, $dayofweek);
	our($C10);
	our(@dayname, @tomorrowname);
	
	# locals only
	my $trank = '';
	my $srank = '';
	my $transfer;
	
	# Get the respective strings for Sanctoral office and Transfers
	my $sday = '';
	my $tday = '';
	my $sfile = '';
	my $tfile = '';
	my $weekname = '';
	my $BMVSabbato = 0;
	
	if($tomorrow) {
		$sday = nextday($month, $day, $year);
		$tomorrowname[0] = $weekname = getweek($day, $month, $year, 1);
		$dayofweek = (day_of_week($day, $month, $year) + 1) % 7;	# 0 = Sunday, 1 = Monday, etc.
	} else {
		$sday = get_sday($month, $day, $year); # get office string mm-dd for Sanctoral office
		$weekname = $dayname[0];
		$dayofweek = day_of_week($day, $month, $year);	# 0 = Sunday, 1 = Mpnday, etc.
	}
	
	my @officename = ($weekname, '', '');
	
  my $transfertemp = get_tempora($version, $sday)
    ;    # look for permanent Transfers assigned to the day of the year (as of 2023-5-22 only 12-12n in Newcal version)

  if ($transfertemp && $transfertemp !~ /tempora/i) {
    $transfertemp = subdirname('Sancti', $version) . "$transfertemp";    # add path to Sancti folder if necessary
  } elsif ($transfertemp && $version =~ /monastic/i) {
    $transfertemp =~ s/TemporaM?/TemporaM/;    # modify path to Monastic Tempora folder if necessary
  } elsif ($transfertemp && $version =~ /Cistercien/i) {
    $transfertemp =~ s/Tempora(?:Cist)?/TemporaCist/;    # modify path to Cistercian Tempora folder if necessary
  }

  my $transfers =
    get_transfer($year, $version, $sday);      # get annual transfers if applicable depending on the day of Easter
  my @transfers = split("~", $transfers);
	
	foreach $transfer (@transfers) {
		if ($transfer) {
			if ($transfer !~ /tempora/i) {
				$transfer = subdirname('Sancti', $version) . "$transfer"; }	# add path to Sancti folder if necessary
			elsif ($version =~ /monastic/i) {
				$transfer =~ s/TemporaM?/TemporaM/; 	# modify path to Monastic Tempora folder if necessary
      }
      elsif ($version =~ /Cistercien/i) {
        $transfer =~ s/Tempora(?:Cist)?/TemporaCist/;   # modify path to Cistercian Tempora folder if necessary
			}
		}
	}
	
	# handle the case of a transferred vigil which does not have its own file "mm-ddv"
	if ($transfers[0] =~ /v$/ && !(-e "$datafolder/Latin/$transfers[0].txt")) {
		unless (leapyear($year) && $transfers[0] =~ /02-23v/) {
			$transfervigil = shift @transfers;
			$transfervigil =~ s/v$/\.txt/;
		}
		$transfer = '';
	} else {
		$transfer = shift @transfers;
	}
	
	if ($testmode =~ /(Saint|Common)/i) {
		$tfile = 'none';
	} else {
		#handle Temporal
		
		if ($weekname) {			# outside Nativity tide in January where we do not have any Temporal yet
			$tday = subdirname('Tempora', $version) . "$weekname" . (($weekname !~ /Nat/i) ? "-$dayofweek" : "");
			my $t = get_tempora($version, $tday);		# look for permanent Transfers assigned to the Temporal, most prominently the Ferias in the Octaves of S. Joseph, Corpus Christi, Ssmi Cordis
			$tfile = $t || $tday;
		}
		
		if ($transfertemp && $transfertemp =~ /tempora/i && !transfered($transfertemp, $year, $version)) {
			$tfile = $transfertemp; # in case a Temporal office has been transfered by means of assigning it to a specific day of the year
		} elsif ($transfer =~ /tempora/i) {
			$tfile = $transfer; # also if in that specific year depending on the day of Easter
		} elsif (transfered($tfile, $year, $version)) {
			$tfile = '';
		}

		if ($tfile && (-e "$datafolder/Latin/$tfile.txt" || $weekname =~ /Epi0/i)) {
			
			$tname = "$tfile.txt";
			
			if ($tomorrow) {
				$tvesp = 1;
				%tempora = %{officestring('Latin', $tname, 1)};
				$trank = $tempora{Rank};
			} else {
				$tvesp = $hora =~ /(Vespera|Completorium)/i ? 3 : 2;
				%tempora = %{officestring('Latin', $tname)};
				$trank = $tempora{Rank};
				$initia = ($tempora{Lectio1} =~ /!.*? 1\:1\-/) ? 1 : 0;
			}
			@trank = split(";;", $trank);
      
		} else { #if there is no Temporal file and we're not in Epiphany tide and there is no transfered temporal for the following day by day of Easter
			$trank = '';
			%tempora = undef;
			$tname = '';
			@trank = undef;
		}
	}
	
	if ($testmode =~ /^Season$/i) {
		$sfile = 'none';
	} else {

		#handle Sanctoral
		my $kalentries = get_kalendar($version, $sday);
		@commemoentries = split("~", $kalentries);
		
		foreach $kalentry (@commemoentries) {
			if ($kalentry) {
				if ($kalentry !~ /tempora/i) {
					$kalentry = subdirname('Sancti', $version) . "$kalentry"; }	# add path to Sancti folder if necessary
				elsif ($version =~ /monastic/i) {
					$kalentry =~ s/TemporaM?/TemporaM/; 	# modify path to Monastic Tempora folder if necessary
				}
        elsif ($version =~ /Cistercien/i) {
          $kalentry =~ s/Tempora(?:Cist)?/TemporaCist/;   # modify path to Cistercian Tempora folder if necessary
        }
			}
		}
		$sfile = shift @commemoentries;	# get the filename for the Sanctoral office from the Kalendarium
		
		if ($transfertemp && $transfertemp =~ /Sancti/ && !transfered($transfertemp, $year, $version)) {
			$sfile = $transfertemp;
		} elsif ($transfer =~ /Sancti/) {
			$sfile = $transfer;
			@commemoentries = @transfers;
		} elsif ($sfile && transfered($sfile, $year, $version)) {
			$sfile = '';
		} elsif ($transfer =~ /tempora/i && @transfers) {
			foreach my $tr (@transfers) {
				push (@commemoentries, $tr);
			}
		}

		# prevent duplicate vigil of St. Mathias in leap years
		if($day == 23 && $month == 2 && leapyear($year) && $version !~ /Cistercien/i ) {
			$sfile = subdirname('Sancti', $version) . (($sfile =~ /02-23o/) ? ''	: ($sfile =~ /02-23/) ? '02-23r' : '');
		}
		
		$BMVSabbato = ($sfile =~ /v/ || $dayofweek !~ 6) ? 0 : 1; # nicht sicher, ob das notwendig ist

		# BMV in Sabbato cannot be on Vigilia Imm. Conceptionis
		if ($version =~ /Cistercien/i && $month == 12 && ($day == 6 || $day == 7) && $month == 1 && ($day > 6 && $day < 13))  { $BMVSabbato = 0 }
		
		if (-e "$datafolder/Latin/$sfile.txt") {
			$sname = "$sfile.txt";
			if ($caller && $hora =~ /(Matutinum|Laudes)/i) { $sname =~ s/11-02t/11-02/; }	# special for All Souls day
			
			%saint = %{setupstring('Latin', $sname)};
			$srank = $saint{Rank};
			@srank = split(";;", $srank);
	
			if ($tomorrow) {
				$svesp = 1;
				$BMVSabbato = ($saint{Rank} !~ /Vigilia/ && $srank[2] <= 2 && $version !~ /(1960|Monastic)/ && $dayofweek == 6); # $version =~ /Cistercien/i, must be implemented in new version

				if ($version !~ /196|Trident/ && $hora =~ /Completorium/i && $month == 11 && $day == 1 && $dayofweek != 6) {
					$srank[2] = 7; # Office of All Souls supersedes All Saints at Completorium from 1911 to 1959
					$srank =~ s/;;[0-9]/;;7/;
				} elsif ($version =~ /196/ && $month == 11 && $day == 1) {

					# Office of All Souls' day begins at Matins???
					$srank[2] = 1;
					$srank = '';
				} elsif ($version !~ /196/ && $srank && ($tname =~ /Quadp3\-3/i || $tname =~ /Quad6\-[1-3]/i)) {
					$srank[2] = 1;	# Feria privilegiata: only comm.
				} elsif ($month == 12 && $day == 23) {	# ensure the Dominica IV adventus win in case it has a "1st Vespers" on Dec 23
					$srank = '';
					%saint = undef;
					$sname = '';
					@srank = undef;
				}
			} elsif ($hora =~ /(Vespera|Completorium)/i) {
				$svesp = 3;

				# restrict II. Vespers
				if (($saint{Rule} =~ /No secunda Vespera/i && $version !~ /196/)
						|| ($srank =~ /vigilia/i 
              && ($version !~ /196/ || $sname !~ /08\-09/)
            ) # Vigils with the ackward exception of S. Lawrence in 1960 rules
						|| ($version !~ /1960|Trident/ 
              && $hora =~ /Completorium/i 
              && $month == 11 
              && $day == 1 
              && $dayofweek != 6) # Office of All Souls supersedes All Saints at Completorium from 1911 to 1959
						|| ($srank[2] < 2 && $trank && !($month == 1 && $day > 6 && $day < 13)) # Simplex end after None.
					) {
					$srank = '';
					%saint = undef;
					$sname = '';
					@srank = undef;
				} elsif (($version !~ /196/ || $dayofweek == 6) 
          && $month == 11 
          && $srank =~ /Omnium Fidelium defunctorum/i 
          && !$caller) 
        {
					# Office of All Souls' day ends after None.
					$srank[2] = 1;
					$srank = '';
				} elsif ($version !~ /196/ && $srank && ($tname =~ /Quadp3\-3/i || $tname =~ /Quad6\-[1-3]/i)) {
					
          #$srank[2] = 1; # Feria privilegiata: only comm.
				}
			} else {
				$svesp = 2; # keine Vesper
			}
		
			if (
        ($trank[2] >= (($version =~ /19(?:55|6)/i) ? 6 : 7) && $srank[2] < 6)
					|| (
          $trank !~ /Dominica|Feria|Sabbato/i && (
            ($trank[2] >= 6 && $srank[2] < 2.1 )			# on Duplex I. cl nothing of Simplex and common octaves
					 || ($trank[2] >= 5 && $srank[2] == 2 && $srank[2] =~ /infra octavam/i)) 
           && $version !~ /Cistercien/i )					# on Duplex II. cl nothing of common octaves
					|| (
            $version =~ /19(?:55|6)/i 
            && (
            (
              $srank =~ /vigil/i 
              && ($sday !~ /(06\-23|06\-28|08\-09|08\-14|12\-24)/
                || ($dayofweek == 0 && $month < 12))    # #3873: ensure no Vigil on Sunday except Nativity
              )
             || ($srank =~ /(infra octavam|in octava)/i && nooctnat())
           )
         )
         || ( $version =~ /1960/
          && $dayofweek == 0
          && (($trank[2] >= 6 && $srank[2] < 6) || ($trank[2] >= 5 && $srank[2] < 5)))
      ) {
				$srank = '';
				%saint = undef;
				$sname = '';
				@srank = undef;
				@commemoentries = ();
			} elsif ($version =~ /196/
					&& (($srank[2] >= 6 && $trank[2] < 6 && !($trank[2] == 2.1 || $trank[2] == 3.9 || $trank[2] == 4.9 || $trank[0] =~ /Dominica/i))
						|| ($trank[0] =~ /Dominica/i && $dayname[0] !~ /Nat1/i && $trank[2] <= 5 && $srank[2] >= 5 && $saint{Rule} =~ /Festum Domini/i))) {
				$tname = $trank = '';
				@trank = undef;
				%tempora = undef;
			}	elsif ($version =~ /1955/ && $srank[2] >= 2 && $srank[2] <= 2.2 && $srank[1] =~ /Semiduplex/i) {
				$srank[2] = 1.5; #1955: semiduplex reduced to simplex
			} elsif ($version =~ /196/i && $srank[2] < 2 && $srank[1] =~ /Simplex/i	&& $testmode =~ /seasonal/i	&& ($month > 1 || $day > 13))	{
				$srank[2] = 1;
			}
		} else {
			$srank = '';
			%saint = undef;
			$sname = '';
			@srank = undef;
		}

		# In Festo Sanctae Mariae Sabbato according to the rubrics.
		if ( ($dayname[0] !~ /(Adv|Quad[0-6]|Quadp3)/i || ( $version =~ /Cistercien/i && $dayname[0] !~ /(Quad[0-6]|Quadp3)/i) ) && $testmode !~ /^season$/i && $BMVSabbato
				&& $srank !~ /(Vigil|in Octav|Omnium Fidelium)/i && ( $trank[2] < 2 && $srank[2] < 2 ) && !$transfervigil) {
			unless($tomorrow) {
				$scriptura = $tname =~ /Epi0/i ? $sname : $tname;
			}
			$tempora{Rank} = $trank = "Sanctæ Mariæ Sabbato;;Feria;;1.2;;vide $C10";
      $tname = subdirname('Commune', $version) . "$C10.txt";
			@trank = split(";;", $trank);
		}
	}
	
	if ($version =~ /Trid|Cistercien/i 
    && (($trank[2] < 5.1 && $trank[2] > 4.2 && $trank[0] =~ /Dominica/i) || $trank[0] =~ /infra octavam Corp/i)) 
    { 
      $trank[2] = 2.9; $trank[2] = 3.5 if ($version =~ /Cistercien/i);} # before Divino: Dominica minor and infra 8vam CC is outranked by any Duplex
	elsif ($version =~ /divino/i && ($trank[2] < 5.1 && $trank[0] =~ /Dominica/i)) { $trank[2] = 4.9; }
	elsif ($version =~ /196/ && $tname =~ /Nat1/i && $day > 28) {	# commemoration of the Christmas Octave according to the rubrics
		$sname = subdirname('Tempora', $version) . "Nat$day";
		%saint = %{setupstring('Latin', $sname)};
		$srank = $saint{Rank};
		@srank = split(";;", $srank);
	}

	if ($tname =~/Epi1\-0/i && $srank[2] == 5.6) { 
    $srank[2] = 2.9; 
    } # Ensure that the infra Octavam Epi does not outrank the Sunday infra Octavam or the Feast of the Holy Family
	if ($testmode =~ /seasonal/i && $version =~ /196/ && $srank[2] < 5 && $dayname[0] =~ /Adv/i) { $srank[2] = 1; }
	
	# Sort out occurrence between the sanctoral and temporal cycles.
	# Dispose of some cases in which the office can't be sanctoral:
	if (!$srank[2] 
      || ($version =~ /19(?:55|6)/i && $srank[2] <= 1.1) 
      || $trank[0] =~ /Sanctæ Mariaæ Sabbato/i) 
  {
		# if we have no sanctoral office, or it was reduced to a commemoration by Cum nostra or its our Lady on Saturday
		$sanctoraloffice = 0; # Office is temporal
	}
	elsif ($srank[2] > $trank[2]) {
		$sanctoraloffice = 1; 	# Main case: If the sanctoral office outranks the temporal, the former takes precedence.
	} elsif ($trank[0] =~ /Dominica/i && $dayname[0] !~ /Nat1/i ) {

		# On some Sundays, the sanctoral office can still win in certain circumstances, even if it doesn't outrank the Sunday numerically.
		if ($version =~ /196/) {

			# With the 1960 rubrics, II. cl. feasts of the Lord and all I. cl. feasts beat II. cl. Sundays.
			if ($trank[2] <= 5 && ($srank[2] >= 6 || ($srank[2] >= 5 && $saint{Rule} =~ /Festum Domini/i))) {
				$sanctoraloffice = 1;
			}
			elsif ($srank[0] =~ /Conceptione Immaculata/) { # && $svesp == 3) {
				# RG 15: As an exception to the general rule, the Immaculate Conception is preferred to the Second Sunday of Advent in occurrence (but not in concurrence).
				$sanctoraloffice = 1;
			} else {
				$sanctoraloffice = 0;
			}
		} elsif ($saint{Rule} =~ /Festum Domini/i && $srank[2] >= 2 && $trank[2] <= 5) 
    { # Pre-1960, feasts of the Lord of nine lessons take precedence over a lesser Sunday.
			$sanctoraloffice = 1;
			$srank[2] = 4.9 + $srank[2] / 100; # to keep the Vespers in concurrence with other Duplex feasts
		} else {
			$sanctoraloffice = 0;
		}
	} else {
		$sanctoraloffice = 0;
	}
	
	if($sanctoraloffice) {
		$rank = $srank[2];
		$officename[1] = "$srank[0] $srank[1]";
		$winner = $sname;
		$vespera = $svesp;
		
		if (my ($new_ct, $new_c) = extract_common($srank[3], $rank, $version, $dayname[0] =~ /Pasc/)) {
			($communetype, $commune) = ($new_ct, $new_c);
		}
		
		if ($srank[3] =~ /^(ex|vide)\s*(C[0-9]+[a-z]*)/i) {
			my $c = getdialog('communes');
			$c =~ s/\n//sg;
			my %communesname = split(',', $c);
			$officename[1] .= " $communetype $communesname{$commune} [$commune]";
		}
		
		if ($winner =~ /01-12t/ && ($hora =~ /laudes/i || $vespera == 3 )) {
			unshift(@commemoentries, 'Sancti/01-06.txt');
			$commemoratio = 'Sancti/01-06.txt';
			$comrank = 5.6;
		} elsif (($srank[2] < 7 && $sname !~ /01-01/)
      && ($trank[2] >= ($srank[2] >= 5 ? 2.1 : 1.5) || ($version =~ /cist/i && $trank[2] == 1.15))
      && !($srank[0] =~ /Sangu/i && $trank[0] =~ /Cord/i)) 
    { # incl. github #2950
			unshift(@commemoentries, $tname);
			$commemoratio = $tname;
			$comrank = $trank[2];
			$cvespera = $tvesp;
      $officename[2] = "Commemoratio: $trank[0]";
      $officename[2] =~ s/:/ ad Laudes \& Matutinum:/ if $tfile =~ /Pasc5\-[13]/i;    # Rogation Monday and Vigilia Acs
      $officename[2] =~ s/:/ ad Laudes tantum:/ if $trank[0] =~ /Quattuor.*Sept/;     # QT in Sep
		} elsif (my $transferedC = $commemoentries[0]) {
			$commemoratio = "$transferedC.txt";
			my %tc = %{setupstring('Latin', "$transferedC.txt")};
			my @cr = split(";;", $tc{Rank});
			$comrank = $cr[2];
			$cvespera = $svesp;
			$officename[2] = "Commemoratio: $cr[0]";

			if ($version =~ /196/i) {
				$officename[2] =~ s/:/ ad Laudes tantum:/ if $cr[2] < 6;
			} elsif ($version !~ /trident/i && $srank[2] >= 6) {
				$officename[2] =~ s/:/ ad Laudes tantum:/ if $cr[2] < 4.2 && $cr[2] != 2.1 && $srank[0] !~ /infra octavam/i;
			} elsif ($srank[2] >= 6 && $srank[0] !~ /in.*octava/i && $cr[2] < 3.1 && $cr[2] != 2.999) {

        # for Tridentine:  either Transfer or no Commemoration in Duplex I. cl. (of Sanctoral) unless dies 8va
        $commemoratio = '';
        $comrank = 0;
        @commemoentries = undef;
      } else {
        $officename[2] =~ s/:/ ad Laudes \& Matutinum:/
          if $srank[2] >= 5 && $cr[2] < 2 && $srank[0] !~ /infra octavam/i;
      }
		} elsif (transfered($tday, $year, $version)) {		#&& !$vflag)
			if ($hora !~ /Vespera|Completorium/i) {
				my %t = %{officestring('Latin', "$tday.txt")};

				if(%t) {
					my @tr = split(";;", $t{Rank});
					my $tr = shift @tr;
					$officename[2] = "Transfer: $tr";
				} else {
					$officename[2] = "Transfer: $tday file not found";
				}
			}
			$commemoratio = '';
			$comrank = 0;
		} else {
			$comrank = 0;
			$commemoratio = '';
		}
		
		if (!$officename[2] && $transfervigil) {
			my %vw = %{setupstring('Latin', $transfervigil)};

			if (%vw) {
				my $o = $vw{'Oratio Vigilia'};

				if ($o =~ /!.*?(Vigilia .*)/) {
					$officename[2] = "Commemoratio: $1";
				}
			}
		}
		
		if (!$officename[2] && ($saint{'Commemoratio 2'} || $saint{'Commemoratio'})) {
			($_) = split(/\n/, $saint{'Commemoratio 2'} || $saint{'Commemoratio'});
			$officename[2] = "Commemoratio: $_" if (s/^!Commemoratio //);
			$officename[2] =~ s/:/ ad Laudes tantum:/ if ($srank[2] >= 5 && $saint{'Commemoratio 2'} || $version =~ /196/);
		}
		
		if (($hora =~ /matutinum/i || (!$officename[2] && $hora !~ /Vespera|Completorium/i)) && $rank < 7 && $trank[0]) {
			my %scrip = %{officestring('Latin', $tname)};
			
			if (!exists($saint{"Lectio1"}) 
        && exists($scrip{Lectio1})
				&& $scrip{Lectio1} !~ /evangelii/i
				&& ($saint{Rank} !~ /\;\;ex / || ($version =~ /trident/i && $saint{Rank} !~ /\;\;(vide|ex) /i))
				&& ($version !~ /monastic/i || $tname !~ /(?:Pasc|Pent)/ || $month > 10))
			{
				$officename[2] = "Scriptura: $trank[0]";
			} else {
				$officename[2] = "Tempora: $trank[0]";
			}
			$scriptura = $tname;
		}
		
	} else { # winner is Tempora
    if ($hora !~ /Vespera/i && $trank[2] < ($version =~ /cist/i ? 1.25 : 1.5) && $transfervigil)
    {         # Vigil transfered to an empty or Simplex only day
      my $t = $transfervigil;
      my %w = setupstring('Latin', $t);
			
			if (%w) {
				$tname = $t;
				$trank = $w{Rank};
				@trank = split(';;', $trank);
			}
		}
	
		$rank = $trank[2];
		$officename[1] = "$trank[0]	$trank[1]";
		$winner = $tname;
		$vespera = $tvesp;
		
		if (my ($new_ct, $new_c) = extract_common($trank[3], $rank, $version, $dayname[0] =~ /Pasc/)) {
			($communetype, $commune) = ($new_ct, $new_c);
		}
		
		if ($trank[3] =~ /^(ex|vide)\s*(C[0-9]+[a-z]*)/i) {
			my $c = getdialog('communes');
			$c =~ s/\n//sg;
			my %communesname = split(',', $c);
			$officename[1] .= " $communetype $communesname{$commune} [$commune]";
		}
		
		if ($version =~ /1960/ && $vespera == 1 && $rank >= 6 && $comrank < 5) { 
      $commemoratio = ''; 
      $srank[2] = 0; 
      @commemoentries = undef; 
    }
		
		
		my $climit1960 = climit1960($sname);

		if ($srank[0] =~ /vigil/i && $srank[0] !~ /Epiph/i) {
			$laudesonly = 
        (   $dayname[0] =~ /(Adv|Quad[0-6])/i 
        || ($dayname[0] =~ /Quadp3/i && $dayofweek >= 4)
        || ($dayname[0] =~ /Quadp/i && $version =~ /Monastic.*Divino/i))
        ? ' ad Missam tantum'
        : ' ad Laudes tantum';
		} else {
			$laudesonly = ($missa) ? '' : ($climit1960 == 2) ? ' ad Laudes tantum' : '';
		}
		
		if ($winner =~ /Epi1\-0a/ && ($hora =~ /laudes/i || $vespera == 3 )) {
			unshift(@commemoentries, 'Sancti/01-06.txt');
			$commemoratio = 'Sancti/01-06.txt';
			$comrank = 5.6;
		} elsif ($srank[2] 
        && $climit1960
				&& $tempora{Rule} !~ /omit.*? commemoratio/i
				&& $tempora{Rule} !~ /No commemoratio/i
				&& $sname !~ /12-20o/) {
			
			if (($hora =~ /laudes/i || $missa) || $climit1960 == 1) {
				unshift(@commemoentries, $sname);
				$commemoratio = $sname;
				$comrank = $srank[2];
				$cvespera = $svesp;
			}
					
			# Don't say "Commemoratio in Commemoratione"
			my $comm = $srank[0] =~ /^In Commemoratione/ ? '' : 'Commemoratio';

			#$officename[2] = "$comm$laudesonly: $srank[0]";
			$officename[2] = "$comm: $srank[0]";
					
			if ($version =~ /196/i) {
				$officename[2] =~ s/:/ $laudesonly:/ if ($trank[2] >= 5 && $srank[2] < 2) || ($climit1960 == 2);
			} elsif ($version !~ /trident|Cistercien/i && $trank[2] >= 6) {
				$officename[2] =~ s/:/ ad Laudes tantum:/ 
          if $srank[2] < 4.2 
          && $srank[2] != 2.1 
          && $trank[0] !~ /infra octavam|cinerum|majoris hebd/i 
          && $tname !~ /Adv|Quad/i;
			} elsif ($laudesonly) {
				$officename[2] =~ s/:/ $laudesonly:/;
			} else {
				$officename[2] =~ s/:/ ad Laudes \& Matutinum:/ 
        if $trank[2] >= 5 
        && $srank[2] < 2 
        && $trank[0] !~ /infra octavam|cinerum|majoris hebd/i 
        && $version !~ /Cistercien/i # TEST!
        && $tname !~ /Adv|Quad/i;
			}
					
			if ($version =~ /196/i && $officename[2] =~ /Januarii/i) { $officename[2] = ''; }
		} elsif (my $transferedC = $commemoentries[0] 
      && $tempora{Rule} !~ /omit.*? commemoratio/i 
      && ($tempora{Rule} !~ /No commemoratio/i)) 
    {
      $commemoratio = "$transferedC.txt";
      $climit1960 = climit1960($commemoratio);

      if ($climit1960) {
        $laudesonly = ($missa) ? '' : ($climit1960 == 2) ? ' ad Laudes tantum' : '';
        my %tc = %{setupstring('Latin', $commemoratio)};
        my @cr = split(";;", $tc{Rank});
        $comrank = $cr[2];
        $cvespera = $svesp;
        $officename[2] = "Commemoratio: $cr[0]";

        if ($version =~ /196/i) {
          $officename[2] =~ s/:/ $laudesonly:/ if ($trank[2] >= 5 && $cr[2] < 2) || ($climit1960 == 2);
        } elsif ($version !~ /trident/i && $trank[2] >= 6) {
          $officename[2] =~ s/:/ ad Laudes tantum:/
            if $cr[2] < 4.2 && $cr[2] != 2.1 && $trank[0] !~ /infra octavam|cinerum|majoris hebd/i;
        } elsif ($laudesonly) {
          $officename[2] =~ s/:/ $laudesonly:/;
        } else {
          $officename[2] =~ s/:/ ad Laudes \& Matutinum:/
            if $trank[2] >= 5 && $cr[2] < 2 && $trank[0] !~ /infra octavam|cinerum|majoris hebd/i;
        }
      } else {
        $commemoratio = '';
        @commemoentries = undef;
      }
    } elsif (transfered($sday, $year, $version)) {
      if ($hora !~ /Vespera|Completorium/i) {
        my %t = %{officestring('Latin', subdirname('Sancti', $version) . "$sday.txt")};

        if (%t) {
          my @tr = split(";;", $t{Rank});
          my $tr = shift @tr;
          $officename[2] = "Transfer: $tr";
        } else {
          $officename[2] = "Transfer: $sday file not found";
        }
      }
      $commemoratio = '';
      $comrank = 0;
    } else {
      $commemoratio = '';
      $comrank = 0;
    }

		if (!$commemoratio && $sname) {  # if only a Vigil to be commemorated
			$sname =~ s/v\././;
			my %s = %{setupstring('Latin', $sname)};
			if ($s{Rank} =~ /Vigil/i && exists($s{Commemoratio})) { $commemorated = $sname; }
			if ($s{Rank} =~ /Vigil/i && exists($s{"Commemoratio 2"})) { $commemorated = $sname; }
		}
	}
	
	if ($month == 1 && $day < 14 && $officename[0] !~ /Epi/i) { $officename[0] = "Nat$day"; }

	if ($tomorrow) {
		@tomorrowname = @officename;
	} else {
		@dayname = @officename;
	}
	
	if ($version =~ /trident/i && $communetype =~ /ex/i && $rank < 1.5) { $communetype = 'vide'; }
	
	$comrank =~ s/\s*//g;
	$seasonalflag = ($testmode =~ /Seasonal/i && $winner =~ /Sancti/ && $rank < 5) ? 0 : 1;
}

sub concurrence {
	my($day, $month, $year, $version) = @_;  # sort out concurrence for the day and the next day
	
	# globals readonly
	our($testmode, $hora, $missa, $caller, $datafolder, $lang2);
	
	# globals set/mod here
	our($winner, $cwinner, $rank, $crank, $commemoratio, $comrank, $commune, $communetype);
	our($tname, $sname, $sanctoraloffice, $ctname, $csname, $csanctoraloffice);
	our(@trank, @srank, @ctrank, @csrank, @commemoentries, @ccommemoentries);
	our(%tempora, %saint, %ctempora, %csaint);
	our($antecapitulum, $antecapitulum2);
	our($vespera, $cvespera, $octvespera);
	our($tvesp, $svesp, $dayofweek);
	our($C10);
	our(%winner);
	our(@dayname, @tomorrowname);

	# globals read only
	our($hora, $version, $missa, $missanumber, $votive, $lang1, $lang2, $testmode);
	our $datafolder;
	
	
	occurrence($day, $month, $year, $version, 1);  # get next day's office
	$cwinner = $winner;
	$crank = $rank;
	my $ccomrank = $comrank;
	my $ccommune = $commune;
	my $ccommunetype = $communetype;
	@ctrank = @trank;
	@csrank = @srank;
	@ccommemoentries = @commemoentries;
	$ctname = $tname;
	$csname = $sname;
	$csanctoraloffice = $sanctoraloffice;
	%ctempora = %tempora;
	%csaint = %saint;
	my %cwinner = $csanctoraloffice ? %csaint : %ctempora;
	my @cwrank = $csanctoraloffice ? @csrank : @ctrank;
	
	occurrence($day, $month, $year, $version, 0); # get today's office
	%winner = $sanctoraloffice ? %saint : %tempora;
	my @wrank = $sanctoraloffice ? @srank : @trank;
	
	if ($winner{Rule} =~ /No secunda Vespera/i && $version !~ /1960|Monastic/i) {
		@wrank = undef;
		%winner = undef;
		$winner = '';
	} elsif ($dayname[0] =~ /Quadp3/ && $dayofweek == 3 && $version !~ /1960|1955/) {

		# before 1955, Ash Wednesday gave way at 2nd Vespers in concurrence to a Duplex
		$rank = $wrank[2] = 2.99;
	} elsif ($dayname[0] =~ /Quad[0-5]|Quadp|Adv/ && $dayofweek == 0 && $version =~ /trident/i) {

		# before Divino Afflatu, the Sundays from Septuag to Judica gave way at 2nd Vespers in concurrence to a Duplex
		$rank = $wrank[2] = 2.99;
	} elsif ($dayname[0] =~ /Quad[0-5]|Quadp|Adv/ && $dayofweek == 0 && $version =~ /divino/i) {

		# after Divino Afflatu, the Sundays from Septuag to Judica gave way at 2nd Vespers in concurrence to a Duplex II. cl.
		$rank = $wrank[2] = 4.9;
	}
	
	if ($cwrank[0] =~ /Dominica/i 
    && $cwrank[0] !~ /infra octavam/i 
    && $cwrank[1] =~ /semiduplex/i
    && $version !~ /1955|196|Cistercien/) 
  {
    # before 1955, even Major Sundays gave way at I Vespers to a Duplex (or Duplex II. cl.)
		$cwrank[2] = $crank = $version =~ /trident/i ? 2.9 : 4.9;
	}
	
	if ($cwrank[0] =~ /in.*octava/i 
    && ($wrank[0] =~ /Dominica/i || ($winner =~ /Sancti/ && $wrank !~ /in.*octava/i))
    && $version =~ /divino/i) 
  {
		$octvespera = 1; # Commemoration of resumed Octave on Sunday from 1st Vespers (Divino only)
	} elsif ($cwrank[0] =~ /Dominica/i && $trank[0] =~ /in.*octava/i) {
		$octvespera = 3;  # Commemoration of Octave on Saturday from 2nd Vespers
	}

	if ($ctrank[0] =~ /Dominica/i && !($version =~ /19(?:55|6)/ && $ctrank[0] =~ /Dominica Resurrectionis/i)) {
		# if tomorrow is a Sunday, get rid of today's tempora completely; necessary Commemorations are handled in the Sunday database file
		if($sanctoraloffice && $srank[0] !~ /infra octavam Nat/i) {
			if ($commemoentries[0] =~ /tempora/i) {
				shift @commemoentries;
			}
		} else {
			%winner = undef;
			$winner = '';
			$rank = 0;
		}
		%tempora = undef;
		@trank = '';
		$tname = '';
	}
	
if (
    $cwinner{Rule} =~ /No prima vespera/i

    # Reduced 1955: No 1st Vespers except for Duplex I. cl & II. cl & Dominica
    || ($version =~ /1955/ && $cwrank[2] < 5)

    # In 1960, II. cl. feasts have I. Vespers if and only if they're feasts of the Lord on a Sunday.
    || ( $version =~ /196/i
      && $cwrank[2] <
      (($cwrank[0] =~ /Dominica/i || ($cwinner{Rule} =~ /Festum Domini/i && $dayofweek == 6)) ? 5 : 6))

    # no Ferias, Vigils and infra Oct days
    || ( $cwinner{Rank} =~ /Feria|Sabbato|Vigilia|Quat[t]*uor/i
      && $cwinner{Rank} !~ /in Vigilia Epi|in octava|infra octavam|Dominica|C10/i)

    # before DA infra octavam always gets commemorated as at 2nd Vespers; after DA also when the office is of the octave
    || ( $cwinner{Rank} =~ /infra octavam/i
      && $cwinner{Rank} !~ /Dominica/i
      && ($version =~ /trident/i || $sanctoraloffice == $csanctoraloffice))

    # infra 8vam Pasch & Pent
    || ($weekname =~ /Pasc[07]/i && $cwinner{Rank} !~ /Dominica/i)

    # no commemoration of the Octave of S. Stephen after DA (and in Cist. we need the eventual Comm. of SS. Nominis Jesu)
    || ($winner =~ /01-01/ && $version !~ /trident|Cistercien/i)

    # sort out BVM concurrent with BMV
    || ($cwinner{Rank} =~ /C10/i && $winner{Rank} =~ /C1[01]/i)

    # no 1st Vespers of Easter after 1955
    || ($version =~ /19(?:55|6)/ && $cwinner{Rank} =~ /Dominica Resurrectionis|Patrocinii S. Joseph/i)

    # TODO: last condition should be made obsolete and handled via database
    || ($version =~ /19(?:55|6)/
      && ($cwinner{Rank} =~ /octav/i && $cwinner{Rank} !~ /dominica|cum Octava/i && $cwrank[2] < 6))
  ) {

    if (
      $ccomrank >= (
             $rank >= ($version =~ /trident/i ? 6 : 5)
          && $wrank[0] !~ /feria|octava/i ? 2.1 : $version !~ /cist/i ? 1.1 : 1
      )
      && $version !~ /1955|196/
    ) {
			$vespera = 3;
			$dayname[2] = $tomorrowname[2] . "<br>Vespera de Officio occurente, Commemoratio Sanctorum crastinorum tantum";
			unless ($version =~ /Cistercien/ && $testmode =~ /seasonal/i) # TEST (1.12.2024: Cistercien: Vespers showed Comm. of Monday)
			{
			$cwrank = '';
			$ctname = '';
			%cwinner = undef;
			@cwrank = undef;
			$cwinner = '';
			$crank = 0;
			$cvespera = 0;
			}
		} elsif (($csanctoraloffice && $cwrank[0] !~ /infra octavam Epi/i || $cwinner =~ /Nat2-0/i) 
      && $version !~ /1955|196/) 
    {
			$vespera = 3;

      if ($sanctoraloffice) {
        $dayname[2] .= "<br/>Vespera de Officio occurente; nihil de sequenti";
      } else {
        $dayname[2] .= "<br/>Vespera de Tempore occurente; nihil de sequenti";
      }
			$cwrank = '';
			$csname = '';
			%cwinner = undef;
			@cwrank = undef;
			$cwinner = '';
			$crank = 0;
			$cvespera = 0;
			@ccommemoentries = ();
		} else {
			$vespera = 3;
      $dayname[2] = '' unless $dayname[2] =~ /Dominica|Advent|Quadr|Pass/i;

      if ($sanctoraloffice) {
        $dayname[2] .= "<br/>Vespera de Officio occurente" unless $version =~ /1955|196/;
      } else {
        $dayname[2] .= "<br/>Vespera de Tempore occurente" unless $version =~ /1955|196/;
      }
			$cwrank = '';
			$ctname = '';
			%cwinner = undef;
			@cwrank = undef;
			$cwinner = '';
			$crank = 0;
			$cvespera = 0;
			@ccommemoentries = () unless $version =~ /Cistercien/i; 
		}
	} elsif (!$sanctoraloffice && !$csanctoraloffice) {
		# two "concurrent" Tempora
		if ($crank >= $rank || $tempora{Rule} =~ /No secunda vespera/i) {
			$vespera = 1;
			$tvesp = 1;
			$cvespera = 0;
			$winner = $cwinner;

      if ($crank < 7 && $comrank >= $ccomrank && $comrank > 2) {
        $tomorrowname[2] = $dayname[2] .= "<br/>Vespera de sequenti; Commemoratio Sanctorum hodiernorum tantum";
      } else {
        $tomorrowname[2] .= "<br/>Vespera de sequenti.";
        @commemoentries = ();
        $commemoratio = '';
      }
			@dayname = @tomorrowname;
			$rank = $crank;
			$commune = $ccommune;
			$communetype = $ccommunetype;
			$cwinner = '';
			%cwinner = undef;
			@cwrank = undef;
		} else {
			$vespera = 3;
			$tvesp = 3;
			$dayname[2] .= "<br>Vespera de Tempore præcedenti; nihil de sequenti";
			$ctrank = '';
			$ctname = '';
			%cwinner = undef;
			@cwrank = undef;
			$cwinner = '';
			$crank = 0;
			$cvespera = 0;
		}
	} else {

		#	before DA, more Semiduplex and Duplex where treated as "A capitulo"
		# Cistercien: in flc?rank (both), there was /trident|Cistercien/i. It flattened Dom. I. Adv., so that it yielded to St. Andrew (30.11.2024, Vespers), which is wrong. Now this works. Testing needed.
    my $flrank =
        ($version =~ /cist/i && $cwinner{Rank} =~ /Dominica/i && $dayname[0] =~ /Adv1|Quad[156]/)
      ? ($rank < 4.9 ? 2 : $rank)
      : $version =~ /trident/i ? (
          ($rank < 2.9 && !($rank == 2.1 && $winner{Rank} !~ /infra Octavam/i)) ? 2
        : ($rank >= 3 && $rank < 4.9 && $rank != 4 && $rank != 3.2) ? 3
        : $rank
      )
      : $rank;
    my $flcrank =
      $version =~ /trident/i
      ? ($crank < 2.91 ? 2 : ($cwinner{Rank} =~ /Dominica/i ? 2.99 : ($crank < 4.9 && $crank != 4) ? 3 : $crank))
      : ($version =~ /divino/i && $cwinner{Rank} =~ /Dominica/i) ? 4.9
      : $crank;
		
		# in 1906, infra 8vam is no longer equal to Semiduplex but still to Sunday in precedence but not sequence
		if($version =~ /1906/ && $winner{Rank} =~ /infra Octavam/i && $crank == 2.2) { $flcrank = 2.2; }
		elsif ($version =~ /1906/ && $cwinner{Rank} =~ /infra Octavam/i && $rank == 2.2) { $flrank = 2.2; }
		
		# Cist: my original: ($rank >= (($version =~ /19(?:55|6)/) ? 6 : 7) && $crank < 6 && $version !~ /Cistercien/i) # e.g. 05-26-2022
    if (
      # On Saturday, 1st Vespers gets commemorated in Festis I. cl. github #3907
      ($rank >= (($version =~ /19(?:55|6)/ && $dayofweek < 6) ? 6 : 7) && $crank < 6 && $version !~ /Cistercien/i)

      # Rubr. 1960: on a II. cl Sunday nothing at 1st Vespers in concurrence with a Feast of the Lord
      || ( $version =~ /196/
        && ($cwinner{Rank} =~ /Dominica/i && $dayname[0] !~ /Nat1/i && $crank <= 5)
        && ($rank >= 5 && $winner{Rule} =~ /Festum Domini/i))

      # on Trid: Duplex I. cl / DA: II. cl no commemoration of following Simplex and Common Octaves
      || ( $rank >= ($version =~ /cist/i ? 7 : $version =~ /trident/i ? 6 : 5)
        && $winner !~ /feria|in.*octava/i
        && $crank < 2.1)
    ) {
				$dayname[2] .= "<br>Vespera de præcedenti; nihil de sequenti";
				$cwinner = '';
				%cwinner = ();
				$vespera = 3;
				$crank = 0;
				$cvespera = 0;
				@ccommemoentries = ();
				$ccomrank = 0;
		} elsif (

      # No 2nd Vespers of a Simplex
      ($rank < 2 && !($rank == 1.15 && $winner =~ /tempora/i))

      # Rubr. 1960: on any Sunday or 1st Vespers of a Feast of the Lord , nothing of a preceding III. cl feast
      || ( $version =~ /196/
        && ($cwrank[0] =~ /Dominica/i || ($cwinner{Rule} =~ /Festum Domini/i && $dayofweek == 6))
        && $rank < 5)

      # in 1st Vespers of Duplex I. cl. only commemoration of Feria major, Dominica (major), 8va privilegiata and Duplex II./I. cl
      # Standard setting omitted ij. Vesp. of S. Henry (MM. min.) on 15.7. due to St. Stephan Harding (Serm. maj.)
      || ( $crank >= ($version !~ /cist/i ? 6 : 7)
        && !($rank == 1.15 || $rank == 2.1 || $rank == 2.99 || $rank == 3.9 || $rank >= 4.2)
        && $cwrank[0] !~ /Dominica|feria|in.*octava/i)

      # on Christmas Eve and New Year's Eve, nothing of a preceding Sunday
      || ($cwinner =~ /12-25|01-01/ && $version !~ /Cistercien/i)

			# in Cistercian Rite, St. Silvester is commemorated on Circumcision 
      || ($cwinner =~ /12-25/ && $version =~ /Cistercien/i)

      # in 1st Vespers of Duplex II. cl. also commemoration of any Duplex
      || ( $crank >= 5
        && !($rank == 1.15 || $rank == 2.1 || $rank >= 2.99)
        && $cwrank[0] !~ /Dominica|feria|in.*octava/i)
    ) {
      @dayname = @tomorrowname;
      $vespera = 1;
      $cvespera = 3;

      if (($comrank == 1.15 || $comrank == 2.1 || $comrank == 2.99 || $comrank == 3.9) && $cwinner !~ /12-25|01-01/)
      {    # privileged Feria, Dominica, or infra 8vam
        $dayname[2] .= "<br/>Vespera de sequenti; commemoratio de off. priv. tantum";
      } else {
        $dayname[2] .= "<br />Vespera de sequenti; nihil de præcedenti";
      }
      $rank = $crank;
      $commune = $ccommune;
      $communetype = $ccommunetype;
      $winner = $cwinner;
      $cwinner = '';
      %cwinner = ();
		} elsif ($version !~ /196|Cistercien/
				&& ($winner{Rank} =~ /Dominica/i 
          && $dayname[0] !~ /Nat1/i 
          && (($rank <= 5 && $crank > 2.1 && $cwinner{Rule} =~ /Festum Domini/i)))
    ) {
			# Pre-1960, feasts of the Lord of nine lessons take precedence over a lesser Sunday.
			# and doubles of at least the II. cl. beat all Sundays in concurrence.
			$vespera = 1;
			$cvespera = 3;
			$commemoratio = $winner;
			$tomorrowname[2] = "Commemoratio: $wrank[0]";
			$winner = $cwinner;
			$cwinner = $commemoratio;
			@dayname = @tomorrowname;
			$dayname[2] .= "<br>Vespera de sequenti; commemoratio de præcedenti Dominica";
			$rank = $crank;
			$commune = $ccommune;
			$communetype = $ccommunetype;
		} elsif (

      # Pre-1960, The other way round then above
      (
        $version !~ /196/ && ($cwinner{Rank} =~ /Dominica/i
          && $dayname[0] !~ /Nat1/i
          && (($crank <= 5 && $rank > 2.1 && $winner{Rule} =~ /Festum Domini/i)))
      )

      # In 1960, in concurrence of days of equal rank, the preceding takes precedence
      || ($version =~ /196/ && $rank >= $crank)
    ) {
      $vespera = 3;
      $cvespera = 1;
      $commemoratio = $cwinner;
      $dayname[2] = "Commemoratio: $cwrank[0]";
      $dayname[2] .= "<br />Vespera de præcedenti; commemoratio de sequenti";
      $dayname[2] .= " Dominica" if $cwinner{Rank} =~ /Dominica/i;
    } elsif ($flcrank == $flrank) {    # "flattend ranks" are equal => a capitulo
      $commemoratio = $winner;
      %commune =
        ($version =~ /trident|Cistercien/i || $flrank >= 5)
        ? %{officestring($lang1, $commune, 0)}
        : ();                          #  Commune psalms only in Trident or Dpx I./II.cl
      $tomorrowname[2] = "Commemoratio: $wrank[0]";
      $antecapitulum =
          (exists($winner{'Ant Vespera 3'})) ? $winner{'Ant Vespera 3'}
        : (exists($winner{'Ant Vespera'})) ? $winner{'Ant Vespera'}
        : (exists($commune{'Ant Vespera 3'})) ? $commune{'Ant Vespera 3'}
        : (exists($commune{'Ant Vespera'})) ? $commune{'Ant Vespera'}
        : '';

      if ($antecapitulum) {
        my %winner2 = %{officestring($lang2, $winner, 0)};
        my %commune2 = %{officestring($lang2, $commune, 0)};
        $antecapitulum2 =
            (exists($winner2{'Ant Vespera 3'})) ? $winner2{'Ant Vespera 3'}
          : (exists($winner2{'Ant Vespera'})) ? $winner2{'Ant Vespera'}
          : (exists($commune2{'Ant Vespera 3'})) ? $commune2{'Ant Vespera 3'}
          : (exists($commune2{'Ant Vespera'})) ? $commune2{'Ant Vespera'}
          : '';

        if (
             $winner{Rule} !~ /no Psalm5/i
          && $version !~ /monastic/i
          && ( $winner{Rule} =~ /Psalm5 Vespera3=([0-9]+)/i
            || $commune{Rule} =~ /Psalm5 Vespera3=([0-9]+)/i
            || $winner{Rule} =~ /Psalm5 Vespera=([0-9]+)/i
            || $commune{Rule} =~ /Psalm5 Vespera=([0-9]+)/i)
        ) {
          #  Hi-jacking an "unused" 6th line to pass on Psalm5 Vespera information to psalmi.pl
          $antecapitulum .= "\nPsalm5 VesperaAnte=$1";
        }

      }
			$vespera = 1;
			$cvespera = 3;
			$winner = $cwinner;
			$cwinner = $commemoratio;
			@dayname = @tomorrowname;
			$rank = $crank;
			$commune = $ccommune;
			$communetype = $ccommunetype;
			$dayname[2] .= "<br>A capitulo de sequenti; commemoratio de præcedenti";
		}	elsif ($crank > $rank) {	# tommorow is outranking today
			$vespera = 1;
			$commemoratio = $winner;
			$cvespera = 3;
			$tomorrowname[2] = "Commemoratio: $wrank[0]";
			$winner = $cwinner;
			$cwinner = $commemoratio;
			@dayname = @tomorrowname;
			$rank = $crank;
			$commune = $ccommune;
			$communetype = $ccommunetype;
			$dayname[2] .= "<br>Vespera de sequenti; commemoratio de præcedenti";
		} else {		# today is outranking tomorrow
			$commemoratio = $cwinner;
			$dayname[2] = "Commemoratio: $cwrank[0]";
			$vespera = 3;
			$cvespera = 1;
			$dayname[2] .= "<br>Vespera de præcedenti; commemoratio de sequenti";

			if ($cwinner{Rank} =~ /infra octavam/i || $ccommemoentries[0] =~ /infra octavam/i) {
				my @comentries = ();
				my %cstr = ();

				foreach $commemo (@commemoentries) {
					if (!(-e "$datafolder/Latin/$commemo") && $commemo !~ /txt$/i) { $commemo =~ s/$/\.txt/; }
					%cstr = %{officestring('Latin', $commemo, 0)};

					unless(!%cstr || ($cstr{Rank} =~ /infra octavam/i && $cstr{Rank} !~ /Dominica/i)) { push(@comentries, $commemo); }
				}
				@commemoentries = @comentries;
			}
		}
	}
	
	if ($hora =~ /completorium/i) {
		$dayname[2] = '';
	}
	
	### Restrict commemoration according to the respective rubrics
	if ($vespera == 3) {    # We have 2nd Vespers:
     # In Concurrence (i.e. tomorrow): Duplex I. cl (or also II. cl) and not "just" a privileged Feria or day (in/of) Octave exludes Simplex and infra 8vam communis
    my $ranklimit =
      ($rank >= ($version =~ /trident/i ? 6 : 5) && $wrank[0] !~ /Dominica|feria|in.*octava/i) ? 2.1 : 1.1;

    # Cisterciense: Following feast gets always commemorated
    $ranklimit = 1 if $version =~ /cist/i;

    my @comentries = ();
    my %cstr = ();

		foreach $commemo (@ccommemoentries) {
			if (!(-e "$datafolder/Latin/$commemo") && $commemo !~ /txt$/i) { $commemo =~ s/$/\.txt/; }
			%cstr = %{officestring('Latin', $commemo, 1)};

			if (($commemo =~ /tempora/i || $cstr{Rank} =~ /infra octavam/i) && $cstr{Rank} !~ /Dominica/i) { 
        next; 
      }	# no superseded Tempora or day within octave can have 1st vespers unless a Sunday

			if (%cstr) {
				my @cr = split(";;", $cstr{Rank});

				unless ($cr[2] < $ranklimit || $cstr{Rule} =~ /No prima vespera/i || $version =~ /1955|196/) { 
          push(@comentries, $commemo); 
        }
			}
		}
		#Cist "original": @ccommemoentries = @comentries unless ($version =~ /Cistercien/i && $cstr{Rule} !~ /No prima vespera/i); # adds superfluous Advent comm.
		@ccommemoentries = @comentries;
		
		# In Occurence (i.e. today): Simplex end after None.
    $ranklimit =
        ($wrank[0] =~ /Dominica|feria|in.*octava/i) ? 2
      : $rank >= 6 ? ($version !~ /trident/i ? 4.2 : $version !~ /cist/i ? 3.1 : 2.1)
      : $rank >= 5 ? 2.1
      : 2;
    @comentries = ();

    foreach $commemo (@commemoentries) {
      if ($commemo =~ /tempora/i && (($trank[2] < 2 && $trank[2] != 1.15) || $trank[0] =~ /Rogatio|Quattuor.*Sept/i)) {
        next;    # Feria minor, Rogation days, Q.T. in Sept., and Vigils have no Vespers if superseded
      }
      if (!(-e "$datafolder/Latin/$commemo") && $commemo !~ /txt$/i) { $commemo =~ s/$/\.txt/; }
      %cstr = %{officestring('Latin', $commemo, 0)};

      if (%cstr) {
        my @cr = split(";;", $cstr{Rank});

        unless (($cr[2] < $ranklimit && !($cr[2] == 1.15 || $cr[2] == 2.1 || $cr[2] == 2.99 || $cr[2] == 3.9))
          || $cstr{Rule} =~ /No secunda vespera/i)
        {
          push(@comentries, $commemo);
        }        # sort out Simplex
      }
    }
    @commemoentries = @comentries;
  } else {    # We have 1st Vespers
     # in Concurrence (i.e. today): Duplex I. cl excludes below Duplex II. cl., Duplex II. cl exludes below Duplex; Simplex have no 2nd Vespers
    my $ranklimit =
        ($rank >= 6 && $cwrank[0] !~ /Dominica|feria|in.*octava/i) ? 4.2
      : ($rank >= 5 && $cwrank[0] !~ /Dominica|feria|in.*octava/i) ? 2.99
      : 2;

    # Cist: Festum sermonis excludes only dies infra 8vam communis; iij. Lect. etc. have no 2nd Vespers
    $ranklimit = 2.1 if $rank >= 5 && $cwrank[0] !~ /Dominica|feria|in.*octava/i && $version =~ /cist/i;

    my @comentries = ();
    my %cstr = ();
    @comentries = ();

    foreach $commemo (@commemoentries) {
      if ($commemo =~ /tempora/i && $trank[2] != 1.15 && ($trank[2] < 2 || $trank[0] =~ /Rogatio|Quattuor.*Sept/i)) {
        next;
      }    # Feria minor and Vigils have no Vespers if superseded
      if (!(-e "$datafolder/Latin/$commemo") && $commemo !~ /txt$/i) { $commemo =~ s/$/\.txt/; }
      %cstr = %{officestring('Latin', $commemo, 0)};

      if (%cstr) {
        my @cr = split(";;", $cstr{Rank});

        unless (($cr[2] < $ranklimit && !($cr[2] == 1.15 || $cr[2] == 2.1 || $cr[2] == 2.99 || $cr[2] == 3.9))
          || $cstr{Rule} =~ /No secunda vespera/i
          || $cr[0] =~ /De VII di/i)
        {
          push(@comentries, $commemo);
        }    # sort out (Semi-)duplex and infra 8vam communis except for Feria major / Dominica major
      }
    }
		@commemoentries = @comentries;
		
    # In Occurencce (i.e. tomorrow):
    $ranklimit =
        ($cwrank[0] =~ /Dominica|feria|in.*octava/i) ? ($version !~ /cist/i ? 1.1 : 1)
      : $rank >= 6 ? ($version !~ /trident/i ? 4.2 : $version !~ /cist/i ? 3.1 : 2.2)
      : $rank >= 5 ? 2.2
      : $version !~ /cist/i ? 1.1
      : 1;
    @comentries = ();

		# Test!
		if ($version =~ /Cistercien/i) {$ranklimit = 1;}

    foreach $commemo (@ccommemoentries) {
      if (!(-e "$datafolder/Latin/$commemo") && $commemo !~ /txt$/i) { $commemo =~ s/$/\.txt/; }
      %cstr = %{officestring('Latin', $commemo, 1)};

      if (($commemo =~ /tempora/i || $cstr{Rank} =~ /infra octavam/i) && $cstr{Rank} !~ /Dominica/i) {
        next;    # no superseded Tempora or day within octave can have 1st vespers unless a Sunday
      }

      if (%cstr) {
        my @cr = split(";;", $cstr{Rank});

        unless (
             $cr[2] < $ranklimit
          || $cstr{Rule} =~ /No prima vespera/i
          || ($version =~ /1955|196/ && $cstr{Rank} !~ /Dominica/i)
          || ( $cstr{Rank} =~ /Feria|Sabbato|Vigilia|Quat[t]*uor/i
            && $cstr{Rank} !~ /in Vigilia Epi|in octava|Dominica/i)
        ) {
          push(@comentries, $commemo);
        }
      }
    }
    @ccommemoentries = @comentries;
  }
}

#*** extract_common($common_field, $office_rank)
# Extracts the type and filename of a common referenced by an
# expression of the form used in rank lines. $common_field is this
# expression, and $office_rank is the rank of the corresponding office.
# Returns respectively the type ('ex' or 'vide') and the filename.
sub extract_common {
	my ($common_field, $office_rank, $version, $paschal_tide) = @_;
	
	# These shadow globals.
	my ($communetype, $commune);
	our ($datafolder);
	
	if ($common_field =~ /^(ex|vide)\s*(C[0-9]+[a-z]*)/i) {
		
		# Genuine common.
		$communetype = $1;
		$commune = $2;
		$communetype = 'ex' if ($version =~ /Trident/i && $office_rank >= 2);
		if ($paschal_tide) {
			my $paschal_fname = "$datafolder/Latin/" . subdirname('Commune', $version) . "$commune" . 'p.txt';
			$commune .= 'p' if -e $paschal_fname;
		}
		$commune = subdirname('Commune', $version) . "$commune.txt" if ($commune);
	} elsif ($common_field =~ /(ex|vide)\s*Sancti\/(.*)\s*$/i) {
		
		# Another sanctoral office used as a pseudo-common.
		$communetype = $1;
		$commune = subdirname('Sancti', $version) . "$2.txt";
		$communetype = 'ex' if ($version =~ /Trident/i);
	} elsif ($common_field =~ /(ex|vide)\s*(.*)\s*$/i) {
		$communetype = $1;
		my $name = $2;
		if ($name !~ /Sancti|Commune|Tempora/i) {
			$commune = subdirname('Tempora', $version) . "$name.txt";
		} else {
			$commune = "$name.txt";
		}
		$communetype = 'ex' if ($version =~ /Trident/i);
	}
	return ($communetype, $commune);
}


#*** emberday
# return 1 if emberday, 0 otherwise
# used $dayofweek, $dayname[0] season and week,
# for September the weekday office
sub emberday {
	# globals readonly
	our ($day, $month, $year, @dayname, %winner, %commemoratio, %scriptura);
	
	my $dayofweek = day_of_week($day, $month, $year);
	if ($dayofweek < 3 || $dayofweek == 4) { return 0; }
	if ($dayname[0] =~ /Adv3|Quad1|Pasc7/i) { return 1; }
	if ($month != 9) { return 0; }
	if ($winner{Rank} =~ /Quat[t]*uor/i || $commemoratio{Rank} =~ /Quat[t]*uor/i || $scriptura{Rank} =~ /Quat[t]*uor/i) { return 1; }
	
	return 0;
}

#*** gettoday($flag)
#get the currend date in mm-dd-yyy format
# flag is set only for primary call for the standalone version
# for the web version javascrip function obtains the user's date
sub gettoday {
	my $flag = shift;
	if (our $browsertime && !$flag) { return $browsertime; }
	my @date = localtime(time());
	my $month = $date[4] + 1;
	my $day = $date[3];
	my $year = $date[5] + 1900;
	return "$month-$day-$year";
}

sub setsecondcol {
	our($winner, $commemoratio, $commune, $scriptura);
	our($lang2, $tvesp, $testmode);
	
	our(%winner2, %commemoratio2, %commune2, %scriptura2) = () x 4;
	
	%winner2 = %{officestring($lang2, $winner, $winner =~ /tempora/i && $tvesp == 1)} if $winner;
	%commemoratio2 = %{officestring($lang2, $commemoratio)} if $commemoratio;
	%commune2 = %{officestring($lang2, $commune)} if $commune;
	%scriptura2 = %{officestring($lang2, $scriptura)} if $scriptura;
	
	if ($testmode =~ /Commune/i) {
		foreach my $key (keys %winner2) {
			next if $key =~ /Rank/i;
			
			if (exists($commune2{$key})) {
				$winner2{$key} = $commune2{$key};
			} else {
				delete($winner2{$key});
			}
		}
	}
}

#*** precedence()
# get date, rank, winner, preloads hashes
sub precedence {
	# globals sets here
	our($winner, $commemoratio, $commemoratio1, $commune, $scriptura) = ('') x 5;
	our(%winner, %commemoratio, %commemoratio1, %commune, %scriptura) = () x 5;
	our(@dayname, @tomorrowname) = () x 2;
	our($month, $day, $year) = ('') x 3;
	our($rule, $communerule, $communetype, $laudes, $transfervigil) = ('') x 5;
	our($C10, $duplex) = ('') x 2;
	
	our($antecapitulum, $antecapitulum2) = ('') x 2;;
	our($tname, $sname, $sanctoraloffice, $ctname, $csname, $csanctoraloffice) = ('') x 6;
	our(@trank, @srank, @ctrank, @csrank, @commemoentries, @ccommemoentries) = () x 6;
	our(%tempora, %saint, %ctempora, %csaint) = () x 2;
	
	# globals read only
	our($hora, $version, $missa, $missanumber, $votive, $lang1, $lang2, $testmode);
	our($vespera, $cvespera, $tvesp, $svesp, $rank);
	our $datafolder;
	
	# set global date
	our($date1) = shift || strictparam('date');
	if (!$date1 || $votive =~ /hodie/) { $date1 = gettoday(); }
	$date1 =~ s/\//\-/g;
	($month, $day, $year) = split('-', $date1);
	
	my $dayofweek = day_of_week($day, $month, $year);
	
	if ($month < 1 || $month > 12 || $day < 1 || $day > 31) {
		error("Wrong date $date1 using today");
		$date1 = '';
	} elsif (sprintf("%04d%02d%02d", $year, $month, $day) < '15821015') {
		error("Date $date1 is before Gregorian calendar using today.");
		$date1 = '';
	}
	
	if (!$date1) { ($month, $day, $year) = split('-', gettoday()); }
	
	@dayname = (getweek($day, $month, $year, 0, $missa), '', '');
	
	$C10 = 'C10';
	if ($missa) {
		$C10 .= ($dayname[0] =~ /Adv/i) ? 'a'
		: ($month == 1 || ($month == 2 && $day == 1)) ? 'b'
		: ($dayname[0] =~ /(Epi|Quad)/i) ? 'c'
		: ($dayname[0] =~ /Pasc/i) ? 'Pasc'
		: '';
	}
	else {
		$C10 .= ($month == 1 || ($month == 2 && $day == 1)) ? 'n'
		: ($dayname[0] =~ /Pasc/i) ? 'p'
		: '';
	}
	
	### Get the relevant Office and Commemorations
	if($hora =~ /vespera|completorium/i) {
		concurrence($day, $month, $year, $version);
	} else {
		occurrence($day, $month, $year, $version, 0);
	}
	
	$duplex = 0;
	if ($dayname[1] && $dayname[1] !~ /duplex/i) {
		$duplex = 1;
	} elsif ($dayname[1] =~ /semiduplex/i) {
		$duplex = 2;
	} else {
		$duplex = 3;
	}
	$rule = $communerule = '';
	
	if ($winner) {
		if ($missa && $missanumber) {
			my $wm = $winner;
			$wm =~ s/\.txt/m$missanumber\.txt/i;
			if ($missanumber && (-e "$datafolder/Latin/$wm")) { $winner = $wm; }
		}
		my $flag = ($winner =~ /tempora/i && $vespera == 1) ? 1 : 0;
		%winner = %{officestring($lang1, $winner, $flag)};
		
		# In the feriae where the octave of the Epiphany used to be, the
		# Mass is of the Epiphany ('Ecce advenit') before the Sunday, and
		# of I. Sunday after the Epiphany ('In excelso throno') afterwards.
		if ( $version =~ /19(?:55|6)/
			&& $missa
			&& $dayname[0] =~ /Epi1/i
			&& $winner =~ /01\-([0-9]+)/
			&& $1 < 13
			&& $dayofweek != 0)
		{
			$communetype = 'ex';
			$commune = 'Tempora/Epi1-0a.txt';
		}
		$rule = $winner{Rule};
	}
	
	if ($version !~ /196/ && exists($winner{'Oratio Vigilia'}) && $dayofweek != 0 && $hora =~ /Laudes/i) {
		$transfervigil = $winner;
	}
	
	# Restrict/Add commemorations
	if ($winner =~ /Sancti/ && $rule =~ /Tempora none/i) {
		$commemoratio = $scriptura = $dayname[2] = '';
		@commemoentries = ();
	}
	if ($version !~ /1960/ && $hora =~ /Vespera/ && $month == 1 && $day == 3 && $dayofweek == 6) {
		$commemoratio1 = 'Sancti/01-04.txt';
	}
	if ($version =~ /1960/ && $winner{Rule} =~ /No Sunday commemoratio/i && $dayofweek == 0) {
		$commemoratio = $commemoratio1 = $dayname[2] = '';
		@commemoentries = ();
	}
	
	if ($commemoratio) {
		my $flag = ($commemoratio =~ /tempora/i && $tvesp == 1) ? 1 : 0;
		%commemoratio = %{officestring($lang1, $commemoratio, $flag)};
		
		if ($version =~ /1960/ && $winner{Rule} =~ /Festum Domini/ && $commemoratio{Rule} =~ /Festum Domini/i) {
			$commemoratio = '';
			%commemoratio = undef;
			$dayname[2] = '';
			@commemoentries = ();
		}
		if ($version =~ /196/ && $commemoratio =~ /06-28r?/i && $dayofweek == 0) {
			$commemoratio = '';
			%commemoratio = undef;
			$dayname[2] = '';
			@commemoentries = ();
		}
		if ($vespera == $svesp && $vespera == 1 && $cvespera == 3 && $commemoratio{Rule} =~ /No second Vespera/i) { # should be obsolte already
			$commemoratio = '';
			%commemoratio = undef;
			$dayname[2] = '';
			@commemoentries = ();
		}
	}
	
#	if ($commemoratio1) {
#		my $flag = ($commemoratio1 =~ /tempora/i && $tvesp == 1) ? 1 : 0;
#		%commemoratio1 = %{officestring($lang1, $commemoratio1, $flag)};
#		
#		if ($version =~ /196/ && $winner{Rule} =~ /Festum Domini/ && $commemoratio1{Rule} =~ /Festum Domini/) {
#			$commemoratio1 = '';
#			%commemoratio1 = undef;
#			$dayname[2] = '';
#		}
#	}
	
	# only short readings in monastic summer
	$scriptura = '' if ($version =~ /monastic/i && $scriptura =~ /(?:Pasc|Pent)/ && $month < 11);

	if ($scriptura) {
		%scriptura = %{officestring($lang1, $scriptura)};
		if (!$dayname[2]) {
			$dayname[2] = "Scriptura: $scriptura{Rank}  $scriptura";
			$dayname[2] =~ s/;;.*//s;

		}
	}

	if ($version =~ /Cistercien/i && $day == 7 && $month == 12 && $dayofweek != 0)  { $dayname[2] .= "Vigilia Immaculatæ Conceptionis Beatæ Mariæ Virginis."; }
	
	#Epiphany days for 1955|1960
	#if ($version =~ /(1955|1960)/ && $month == 1 && $day > 6 && $day < 13 && $winner{Rank} =~ /Die/i	&&
	#		exists($scriptura{Rank}))
	#	{$winner{Rank} = $scriptura{Rank}; $winner2{Rank} = $scriptura2{Rank};}
	
	#no transfervigil if emberday
	#if ( $winner{Rank} =~ /Quat[t]*uor/i
	#|| $commemoratio{Rank} =~ /Quat[t]*uor/i
	#|| $scriptura{Rank} =~ /Quat[t]*uor/i)
	if(emberday()) {
		$transfervigil = '';
	}
	
	if ($commune) {
		%commune = %{officestring($lang1, $commune)};
		
		# XXX: this should moved where Responsories are in use
		if (exists($commune{Responsory7c})) {
			my @a = split("\n", $commune{Responsory7});
			my @b = split("\n", $scriptura{Responsory1});
			
			if ($a[0] =~ /$b[0]/i) {
				$commune{Responsory7} = $commune{Responsory7c};
				# $commune2{Responsory7} = $commune2{Responsory7c};
			}
		}
		
		if ($commune =~ /C10/) {
			$rule .= "ex $C10";
			$rule =~ s/Oratio Dominica//gi;
			$winner{Rank} = "Sanctæ Mariæ Sabbato;;Feria;;1;;ex $C10";
		}
		
		if ($winner{Rank} =~ /\;\;ex\s/
		|| ($version =~ /Trident/i && $rank =~ /\;\;(ex|vide)/i && $duplex > 1))
		{
			$communerule = $commune{Rule};
		}
		
		if ($testmode =~ /Commune/i) {
			foreach my $key (keys %winner) {
				next if $key =~ /Rank/i;
				
				if (exists($commune{$key})) {
					$winner{$key} = $commune{$key};
				} else {
					delete($winner{$key});
				}
			}
		}
	}
	
	my $vtv = $votive =~ /^C1?\da?/ ? $votive : '';

	if ($vtv && !$missa) {
		if ($vtv =~ /C12/i) {
			if ( ($month == 12 && ($day == 24 && $hora =~ /Vespera|Completorium/ || ($day > 24)))
				|| $month == 1
				|| ($month == 2 && $day < 3))
			{
				$vtv = 'C12N';
			} elsif ($dayname[0] =~ /adv/i) {
				$vtv = 'C12A';
			} elsif ($dayname[0] =~ /Pasc/i) {
				$vtv = 'C12P';
			} elsif (
			$month == 3
			&& (($day == 24 && $hora =~ /(Vespera|Completorium)/i)
			|| $day == 25)
			)
			{
				$vtv = 'C12';
			} elsif ($dayname[0] =~ /(Quadp|Quad)/i) {
				$vtv = 'C12Q';
			}
		}
		$winner = subdirname('Commune', $version) . "$vtv.txt";
		$commemoratio = $commemoratio1 = $scriptura = $commune = '';
		%winner = %{setupstring($lang1, $winner)};
		%commemoratio = %commemoratio1 = %scriptura = %commune = {};
		$rule = $winner{Rule};
		
		if ($vtv =~ /C12/i) {
			$commune = subdirname('Commune', $version) . "C11.txt";
			$communetype = 'ex';
			%commune = %{setupstring($lang1, $commune)};
		}
		$dayname[1] = $winner{Name};
		$dayname[2] = '';
	}
	
	if ($vtv && $missa) {
		$winner = "Votive/$vtv.txt";
		$commemoratio = $commemoratio1 = $scriptura = $commune = '';
		%winner = %{setupstring($lang1, $winner)};
		%commemoratio = %scriptura = %commune = {};
		$rule = $winner{Rule};
		
		if ($vtv =~ /Maria/i) {
			#$commune = "Commune/C11.txt";
			$commune = subdirname('Commune', $version) . "C11.txt";
			$communetype = 'ex';
			%commune = %{setupstring($lang1, $commune)};
			# %commune2 = updaterank(setupstring($lang2, $commune));
		}
		$dayname[1] = $winner{Name};
		$dayname[2] = '';
	}
	
	# Choose the appropriate scheme for Lauds. Roughly speaking, penitential days
	# have Lauds II and others have Lauds I, although for the Tridentine rubrics
	# only the Sundays of Septuagesima and Lent have a sort of "Lauds II", with
	# all other days being unambiguous.
	if ($version =~ /Trident/i) {
		$laudes =
		($dayname[0] =~ /Quad/i && $dayofweek == 0 && $winner =~ /Tempora/i)
		? 2
		: '';
	} else {
		$laudes = (
		(
		(($dayname[0] =~ /Adv/i && $dayofweek != 0) || $dayname[0] =~ /Quad/i || emberday())
		&& $winner =~ /tempora/i
		&& $winner{Rank} !~ /(Beatæ|Sanctæ) Mariæ/i
		)
		|| $rule =~ /Laudes 2/i
		|| ($winner{Rank} =~ /vigil/i && $version !~ /19(?:55|60)/)
		)
		? 2
		: 1;
	}
	if ($missa && $winner{Rank} =~ /Defunctorum/) { $votive = 'Defunct'; }
}

#*** officestring($lang, $fname, $flag)
# same as setupstring (in dialogcommon.pl = reads the hash for $fname office)
# with the addition that for the monthly ferias/scriptures (aug-dec)
# it adds that office to the otherwise empty season related one
# if flag is 1 looks for the anticipated office for vespers
# returns the filled hash for the ofiice
sub officestring($$;$) {
	my ($lang, $fname, $flag) = @_;
	
	my $basedir = our $datafolder;
	my %s;
	
	# read only globals
	our ($version, $day, $month, $year);
	
	# set this global here
	our $monthday;
	if ($fname !~ /tempora[M|Cist]*\/(Pent|Epi)/i) {
		%s = %{setupstring($lang, $fname)};
		if ($version =~ /196/ && $s{Rank} =~ /Feria.*?(III|IV) Adv/i && $day > 16) { $s{Rank} =~ s/;;2.1/;;4.9/; }
		return \%s;
	}
	
  if ($fname !~ /tempora[M|Cist]*\/Pent([0-9]+)/i && $1 < 5) {
		%s = %{setupstring($lang, $fname)};
		return \%s;
	}
	$monthday = monthday($day, $month, $year, ($version =~ /196/) + 0, $flag);
	
	if (!$monthday) {
		%s = %{setupstring($lang, $fname)};
		return \%s;
	}
	%s = %{setupstring($lang, $fname)};
	if (!%s) { return ''; }
	my @rank = split(';;', $s{Rank});
	my $m = 0;
	my $w = 0;
	if ($monthday =~ /([0-9][0-9])([0-9])\-[0-9]/) { $m = $1; $w = $2; }
	my @months = ('Augusti', 'Septembris', 'Octobris', 'Novembris', 'Decembris');
	my @weeks = ('I.', 'II.', 'III.', 'IV.', 'V.');
	if ($m) { $m = $months[$m - 8]; }
	if ($w) { $w = $weeks[$w - 1]; }
	if ( $version !~ /Cistercien/i ) { $rank[0] .= " $w $m"; }
    else { $rank[0] .= " ($w $m)"; }
	$s{Rank} = join(';;', @rank);
	my %m = %{setupstring($lang, subdirname('Tempora', $version) . "$monthday.txt")};
	
	foreach my $key (keys %m) {
		if (($version =~ //i && $key =~ /Rank/i)) {
			;
		} else {
			$s{$key} = $m{$key};
		}
	}
	return \%s;
}

#*** climit1960($commemoratio)
# returns 1 if commemoratio is allowed for 1960 rules
sub climit1960 {
	my $c = shift;
	if (!$c) { return 0; }
  if ( $version =~ /Cistercien/i ) { return 1; }
	
	# read only globals
	our ($version, $datafolder, $winner, $hora, $rank);
	
	if ($version !~ /196/ || $c !~ /sancti/i) { return 1; }
	
	# Subsume commemoration in special case 7-16 with Common 10 (BVM in Sabbato)
	return 0 if $c =~ /7-16/ && $winner =~ /C10/;
	my %w = %{setupstring('Latin', $winner)};
	if ($winner !~ /tempora|C10/i) { return 1; }
	my %c = %{setupstring('Latin', $c)};
	my @r = split(';;', $c{Rank});
	
	if ($w{Rank} =~ /Dominica/i) {
		if (($hora !~ /(Vespera|Completorium)/i && $r[2] >= 5) || $r[2] >= 6) { return 1; }
		if ($hora =~ /Laudes/i && $r[2] >= 5 && $rank < 6) { return 1; }
	} elsif ($r[2] >= 6) {
		return 1;
	} elsif ($r[2] > 1) {
		return 2;
	}
	return 0;
}

#*** setheadline();
# returns the winner name and rank, different for 1960
sub setheadline {
	my $name = shift;
	my $rank = shift;
	my $latname;
	
	# read only globals
	our(%winner, $winner, @dayname, $version, $day, $month, $year, $dayofweek, $hora, $rule, $lang);
	
	if ((!$name || !$rank) && exists($winner{Rank})) {
		my @rank = split(';;', $winner{Rank});
		$name = $rank[0];
		$rank = $rank[2];
	}
	
	if ($lang !~ /Latin/i) {
		my %latwinner = %{setupstring('Latin', $winner)};
		my @latrank = split(';;', $latwinner{Rank});
		$latname = $latrank[0];
	} else {
		$latname = $name;
	}
	
	if ($latname && $rank) {
		my $rankname = '';
		
		if (($latname !~ /(?:Die|Feria|Sabbato|^In Octava)/i) && ($dayname[0] !~ /Pasc[07]/i || $dayofweek == 0 || $name !~ /Pasc|Pent/i)) {
			my @tradtable = (
			'none', 'Simplex', 'Semiduplex', 'Duplex',
			'Duplex majus', 'Duplex II. classis', 'Duplex I. classis', 'Duplex I. classis'
			);
			my @newtable = (
			'none',
			'Commemoratio',
			'III. classis',
			'III. classis',
			'III. classis',
			'II. classis',
			'I. classis',
			'I. classis'
			);
      my @cisttable = (   # Cistercian table
      'Commemoratio',
      'iij. Lect. et M.',
      'xij. Lect. et M.',
      'MM. min.',
      'MM. maj.',
      'Serm. min.',
      'Serm. maj.',
      'Serm. maj.'
      );

      if ($version =~ /Monastic.*Divino/i) {
        $tradtable[1, 2] = 'Memoria';
      } elsif ($version =~ /1955/) {
        $tradtable[1, 2] = 'Simplex';
      }

      $rankname =
          $version =~ /cist/i ? $cisttable[$rank]
        : $version !~ /196/ ? $tradtable[$rank]
        : $newtable[$rank];

      if ($version =~ /19(?:55|60)|Cistercien/ && $winner !~ /Pasc5-3/i && $dayname[1] =~ /feria/i) { $rankname = 'Feria'; }
			
			if ($version =~ /1570/i) { $rankname =~ s/ majus//;	} # no Duplex majus yet in 1570
			
      if ($latname =~ /Vigilia Epi/i) {
        $rankname =
            $version =~ /cist/i ? ($dayofweek ? 'Vigilia privilegiata' : 'Vigilia ' . $cisttable[2])
          : $version =~ /trident/i ? 'Semiduplex'
          : 'Semiduplex Vigilia II. classis';
      } elsif ($latname =~ /^In Vigilia/i && $rank <= 2.5) {
        $rankname = $version =~ /cist/i ? 'iij. Lect. et M.' : 'Simplex';
      }
			
			if($latname =~ /Sanctæ Fami/i && $version !~ /196/) {
				$rankname = 'Duplex majus';
			}
			
			if ($latname =~ /Dominica/i && $version !~ /196/) {
				if ($version !~ /trident/i || $version =~ /Cistercien/i) {
          local $_ = getweek($day, $month, $year, $dayofweek == 6 && $hora =~ /Vespera|Completorium/i);
					$rankname = (/Pasc[017]/i || /Pent01/i) ? 'Duplex I. classis'
						: (/(Adv1|Quad[1-6])/i) ? 'Semiduplex Dominica I. classis'
						: (/(Adv[2-4]|Quadp)/i) ? 'Semiduplex Dominica II. classis'
						: (/(Epi[1-6])|Pent[22-23]/i && $dayofweek > 0 && !($dayofweek == 6 && $hora =~ /Vespera|Completorium/i)) 
						? 'Semiduplex Dominica anticipata'
						: 'Semiduplex Dominica minor';
				} else {
					local $_ = getweek($day, $month, $year, $dayofweek == 6 && $hora =~ /Vespera|Completorium/i);
					$rankname = 
						(/Pasc[017]/i || /Pent01/i) ? 'Duplex I. classis'
					: (/(Adv1|Quad1|Quad[5-6])/i) ? 'Semiduplex Dominica I. classis'
					: (/(Adv[2-4]|Quadp|Quad[2-4])/i) ? 'Semiduplex Dominica II. classis'
					: (/(Epi[1-6])|Pent[22-23]/i && $dayofweek > 0 && !($dayofweek == 6 && $hora =~ /Vespera|Completorium/i)) 
					? 'Simplex Dominica anticipiata'
					: 'Semiduplex Dominica minor';
				}

				  if ($version =~ /cist/i) {
          my $weekN = getweek($day, $month, $year, $dayofweek == 6 && $hora =~ /Vespera|Completorium/i);
          $rankname =~ $cisttable[6] if $weekN =~ /Pasc[07]/i;
          $rankname =~ $cisttable[5] if $weekN =~ /Pent01/i;
          $rankname =~ s/Duplex /Dominica /;
          $rankname =~ s/Semiduplex //;
        }
			}
    } elsif ($version =~ /196/ && $dayname[0] =~ /Pasc[07]/i && $dayofweek > 0 && $winner !~ /Pasc7-0/) {
      $rankname = 'Dies Octavæ I. classis';    # Paschal & Pentecost Octave post 1960
    } elsif ($version =~ /196/ && $winner =~ /Pasc6-6/) {
      $rankname = 'I. classis';                # Vigilia Pentecostes
    } elsif ($version =~ /196/ && $winner =~ /Pasc5-3/) {
      $rankname = 'II. classis';               # Vigilia Asc
    } elsif ($version =~ /196/ && $month == 12 && $day > 16 && $day < 25 && $dayofweek > 0) {
      $rankname = 'II. classis';               # Week before Christmas
    } elsif ($version !~ /196/ && $rule =~ /C10/) {
      $rankname = $version =~ /cist/i ? 'iij. Lect. et M.' : 'Simplex';    # BMV Sabbato
    } elsif ($version =~ /cist/i && $dayname[0] =~ /Pasc[07]/i && $dayofweek > 0) {
      $rankname = ($rank =~ 7) ? 'MM. maj.' : 'iij. Lect. et M.';          # Paschal & pentecost Octave pre 1960
    } elsif ($version !~ /196/ && $dayname[0] =~ /Pasc[07]/i && $dayofweek > 0) {
      $rankname = ($rank =~ 7) ? 'Duplex I. classis' : 'Semiduplex';       # Paschal & pentecost Octave pre 1960
    } elsif ($version =~ /trid/i && $latname =~ /^In Octava/i) {
      $rankname = $version =~ /cist/i ? 'xij. Lect. et M.' : 'Duplex';     # all other Octaves pre Divino
    } elsif ($version =~ /trid/i && $latname =~ /infra Octavam|post Octavam Asc|Vigilia Pent/i) {
      $rankname = $version =~ /cist/i ? 'iij. Lect. et M.' : 'Semiduplex';    # all other Octaves pre Divino
    } elsif ($version =~ /Divino/ && $latname =~ /^In Octava|infra Octavam|post Octavam Asc|Vigilia Pent/i) {
      $rankname =
          ($rank < 2) ? 'Simplex'
        : ($rank < 3 && $latname !~ /Asc|Nat|Cord/i || $latname =~ /post|Joan/) ? 'Semiduplex'
        : ($rank < 3) ? 'Semiduplex III. ordinis'
        : ($rank < 5 && $latname !~ /Asc|Nat|Cord/i) ? 'Duplex majus'
        : ($rank < 5) ? 'Duplex majus III. ordinis'
        : ($rank < 5.61) ? 'Semiduplex II. ordinis'
        : ($rank < 6.5) ? 'Duplex majus II. ordinis'
        : 'Semiduplex Vigilia I. classis';

			#} elsif ($version =~ /(1570|1910|Divino|1955)/ && $dayname[0] =~ /Quad/i && $dayname[0] !~ /Quad6-4|5|6/i && $dayofweek > 0) {
			#$rankname = 'Simplex';
		} elsif ($version !~ /196/ && $dayname[0] =~ /07-04/i && $dayofweek > 0) {
			$rankname = ($rank =~ 7) ? 'Duplex I. classis' : 'Semiduplex'; # TODO: what is this? Independecne Day????
		} else {	# Default for Ferias
			if ($version !~ /196/) {
        $rankname =
            ($rank < 1.1 || ($rank < 2 && $version !~ /cist/i)) ? 'Feria'
          : ($rank < 3) ? ($version =~ /monastic.*divino/i ? 'Feria privilegiata III. ordinis' : 'Feria major')
          : ($rank < 5) ? 'Feria privilegiata II. ordinis'
          : 'Feria privilegiata';
			} else {
				my @ranktable = (
				'',
				'IV. classis',
				'III. classis',
				'III. classis',
				'II. classis',
				'II. classis',
				'II. classis',
				'I. classis',
				'I. classis'
				);
				$rankname = $ranktable[$rank];
			}
		}

    return "$name ~ $rankname";
	} else {
		return $dayname[1];
	}
}

sub subdirname {
	my($subdir, $version) = @_;
	return "${subdir}M/" if $version =~ /^Monastic/;
	return "${subdir}Cist/" if $version =~ /Cistercien/;
  return "${subdir}OP/" if $version =~ /^Ordo Praedicatorum/;
	#$subdir .= 'M' if $version =~ /monastic/i;
  #$subdir .= 'Cist' if $version =~ /Cistercien/i;
	"$subdir/"
}

sub nomatinscomm {
	my $w = shift;
	my %w = %$w;
	if ($w{Rule} =~ /9 lectiones/i && exists($w{Responsory9})) { return 1; }
	if ($w{Rule} !~ /9 lectiones/i && exists($w{Responsory3})) { return 1; }
	return 0;
}

#*** days_to_date($days)
# returns the ($sec, $min, $hour, $day, $month-1, $year-1900, $wday, $yday, 0) array from the number of days from 01-01-1970
sub days_to_date {
	my $days = shift;
	if ($days > 0 && $days < 24837) { return localtime($days * 60 * 60 * 24 + 12 * 60 * 60); }
	if ($days < -141427) { error("Date before the Gregorian Calendar!"); }
	my @d = ();
	$d[0] = 0;
	$d[1] = 0;
	$d[2] = 6;
	$d[6] = (($days % 7) + 4) % 7;
	$d[8] = 0;
	my $count = 10957;
	my $yc = 20;
	my $add;
	my $oldadd;
	my $oldcount = $count;
	my $oldyc = $yc;
	
	if ($days < $count) {
		while ($days < $count) { $yc--; $add = (($yc % 4) == 0) ? 36525 : 36524; $count -= $add; }
	} else {
		while ($days >= $count) {
			$oldcount = $count;
			$oldyc = $yc;
			$add = (($yc % 4) == 0) ? 36525 : 36524;
			$count += $add;
			$yc++;
		}
		$count = $oldcount;
		$yc = $oldyc;
	}
	$add = 4 * 365;
	if (($yc % 4) == 0) { $add += 1; }
	$yc *= 100;
	$oldcount = $count;
	$oldyc = $yc;
	while ($count <= $days) { $oldcount = $count; $oldyc = $yc; $count += $add; $add = 4 * 365 + 1; $yc += 4; }
	$count = $oldcount;
	$yc = $oldyc;
	$add = 366;
	if (($yc % 100) == 0 && ($yc % 400) > 0) { $add = 365; }
	$oldyc = $yc;
	while ($count <= $days) { $oldadd = $add; $oldyc = $yc; $count += $add; $add = 365; $yc++; }
	$count -= $oldadd;
	$yc = $oldyc;
	$d[5] = $yc - 1900;
	$d[7] = $days - $count + 1;
	my @months = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	
	if (($yc % 4) == 0) {
		$months[1] = 29;
	} else {
		$months[1] = 28;
	}
	if (($yc % 100) == 0 && ($yc % 400) > 0) { $months[1] = 28; }
	my $c = 0;
	while ($count <= $days) { $count += $months[$c]; $c++; }
	$c--;
	$count -= $months[$c];
	$d[4] = $c;
	$d[3] = $days - $count + 1;
	return @d;
}

#*** date_to_days($day, $month-1, $year)
# returns the number of days from the epoch 01-01-1070
sub date_to_days {
	my ($d, $m, $y) = @_;
	if ($y > 1970 && $y < 2038) { floor(timelocal(0, 0, 12, $d, $m, $y) / 60 * 60 * 24); }
	my $yc = floor($y / 100);
	my $c = 20;
	my $ret = 10957;
	my $add;
	
	if ($y < 2000) {
		while ($c > $yc) { $c--; $add = (($c % 4) == 0) ? 36525 : 36524; $ret -= $add; }
	} else {
		while ($c < $yc) { $add = (($c % 4) == 0) ? 36525 : 36524; $ret += $add; $c++; }
	}
	$add = 4 * 365;
	if (($yc % 4) == 0) { $add += 1; }
	$yc *= 100;
	while ($yc < ($y - ($y % 4))) { $ret += $add; $add = 4 * 365 + 1; $yc += 4; }
	$add = 366;
	if (($yc % 100) == 0 && ($yc % 400) > 0) { $add = 365; }
	while ($yc < $y) { $ret += $add; $add = 365; $yc++; }
	my @months = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	
	if (($y % 4) == 0) {
		$months[1] = 29;
	} else {
		$months[1] = 28;
	}
	if (($y % 100) == 0 && ($y % 400) > 0) { $months[1] = 28; }
	$c = 0;
	while ($c < $m) { $ret += $months[$c]; $c++; }
	$ret += ($d - 1);
	if ($ret < -141427) { error("Date before the Gregorian Calendar!"); }
	return $ret;
}
#*** nooctnat()
# returns 1 for 1960/1955 not Christmas Octave days
sub nooctnat {
	our $version =~ /19(?:55|6)/ && (our $month < 12 || our $day < 25)
}

# Latin spelling variety in versions
sub spell_var {
	my $t = shift;
	
	if (our $version =~ /196/) {
		# substitute i for j
		# but not in html tags!
		my @parts = split(/(<[^<>]*>)/, $t);
		
		foreach (@parts) {
			next if /^</;
			tr/Jj/Ii/;
			s/H\-Iesu/H-Jesu/g;
			s/er eúmdem/er eúndem/g;
		}
		$t = join('', @parts);
	} else {
		$t =~ s/Génetrix/Génitrix/g;
		$t =~ s/\bco(t[ií]d[ií])/quo$1/g;
	}
  if (our $version =~ /Cistercien/) {
    $t =~ s/cæl/cœl/g;
    $t =~ s/Cæl/Cœl/g;
    $t =~ s/cǽl/cœl/g;
    $t =~ s/Cǽl/Cœl/g;
    $t =~ s/cael/cœl/g;
    $t =~ s/Cael/Cœl/g;
    $t =~ s/caríssi/charíssi/g;
    $t =~ s/Caríssi/Charíssi/g;
    $t =~ s/carit/charit/g;
    $t =~ s/Carit/Charit/g;
    $t =~ s/cárit/chárit/g;
    $t =~ s/Cárit/Chárit/g;
    $t =~ s/eius/ejus/g;
    $t =~ s/ iam/ jam/g;
    $t =~ s/ iud/ jud/g;
    $t =~ s/ Iam/ Jam/g;
	  $t =~ s/abic/abjic/g;
    $t =~ s/Abic/Abjic/g;
    $t =~ s/p(ae|æ|ǽ)niten/pœniten/g;
    $t =~ s/P(ae|æ|ǽ)niten/Pœniten/g;
    $t =~ s/p(ae|æ|ǽ)nitén/pœnitén/g;
    $t =~ s/P(ae|æ|ǽ)nitén/Pœnitén/g;
    $t =~ s/ǽ/æ/g; # traditional Cistercian materials don't use it.
    #$t =~ s/V. /℣. /g;
    #$t =~ s/R. /℟. /g;
    }
	return $t;
}

#*** papal_commem_rule($rule)
#	Determines whether a rule contains a clause for a commemorated Pope.
#	Returns a list ($class, $name), as for papal_rule.
sub papal_commem_rule($) {
	return papal_rule(shift, (commemoration => 1));
}

#*** papal_rule($rule, %params)
#	Determines whether a rule contains a clause for the office of a
#	Pope. If $params{'commemoration'} is true, a commemorated Pope
#	(only) is checked for; otherwise, only in the office of the day.
#
#	Returns a list ($plural, $class, $name), where $plural is true if
#	the office is of several Popes; $class is 'C', 'M' or 'D' as the
#	Pope is a confessor, doctor or martyr, respectively; and $name is
#	the name(s) of the Pope(s). The empty list is returned if there is
#	no match.
sub papal_rule($%) {
	my ($rule, %params) = @_;
	my $classchar = $params{'commemoration'} ? 'C' : 'O';
	return ($rule =~ /${classchar}Papa(e)?([CMD])=(.*?);/i);
}

#*** papal_prayer($lang, $plural, $class, $name[, $type])
#	Returns the collect, secret or postcommunion from the Common of
#	Supreme Pontiffs, where $lang is the language; $plural, $class and
#	$name are as returned by papal_rule; and $type optionally specifies
#	the key for the template (otherwise, it will be 'Oratio').
sub papal_prayer($$$$;$) {
	my ($lang, $plural, $class, $name, $type) = @_;
	$type ||= 'Oratio';
	
	# Get the prayer from the common.
	my (%common, $num);
	our ($missa, $version);
	
	if ($missa) {
		%common = %{setupstring($lang, subdirname('Commune', $version) . "C4b.txt")};
		$num = $plural && $type eq 'Oratio' ? 91 : '';
	} else {
		%common = %{setupstring($lang, subdirname('Commune', $version) . "C4.txt")};
		$num = $plural ? 91 : 9;
	}
	my $prayer = $common{"$type$num"};
	
	# Fill in the name(s).
	$prayer =~ s/ N\.([a-z ]+N\.)*/ $name/;
	
	# If we're not a martyr, get rid of the bracketed part; if we are,
	# then just get rid of the brackets themselves.
	if ($class !~ /M/i) {
		$prayer =~ s/\s*\((.|~[\s\n\r]*)*?\)//;
	} else {
		$prayer =~ tr/()//d;
	}
	return $prayer;
}

#*** papal_antiphon_dum_esset($lang)
#	Returns the Magnificat antiphon "Dum esset" from the Common of
#	Supreme Pontiffs, where $lang is the language.
sub papal_antiphon_dum_esset($) {
	my $lang = shift;
	our $version;
	my %papalcommon = %{setupstring($lang, subdirname('Commune', $version) . "C4.txt")};
	return $papalcommon{'Ant 3 summi Pontificis'};
}

# Block for conditional-handling routines.
{
	
	use strict;
	
	my %conditional_values;
	my %stopword_weights;
	my %backscoped_stopwords;
	my $stopwords_regex;
	my $scope_regex;
	
	BEGIN {
		# Main stopwords. These have implicit backward scope.
		$stopword_weights{'sed'} = $stopword_weights{'vero'} = 1;
		$stopword_weights{'atque'} = 2;
		$stopword_weights{'attamen'} = 3;
		%backscoped_stopwords = %stopword_weights;
		
		# Extra stopwords which require explicit backward scoping.
		$stopword_weights{'si'} = 0;
		$stopword_weights{'deinde'} = 1;
		my $stopwords_regex_string = join('|', keys(%stopword_weights));
		$stopwords_regex = qr/$stopwords_regex_string/i;
		$scope_regex = qr/
		(?:\bloco\s+(?:hu[ij]us\s+versus|horum\s+versuum)\b)?
		\s*
		(?:
		\b
		(?:
		(?:dicitur|dicuntur)(?:\s+semper)?
		|
		(?:hic\s+versus\s+)?omittitur
		|
		(?:hoc\s+versus\s+)?omittitur
		|
		(?:hæc\s+versus\s+)?omittuntur
		|
		(?:hi\s+versus\s+)?omittuntur
		|
		(?:haec\s+versus\s+)?omittuntur
		)
		\b
		)?
		/ix;
	}
	
	# We have four types of scope (in each direction):
	use constant SCOPE_NULL => 0;		# Null scope.
	use constant SCOPE_LINE => 1;		# Single line.
	use constant SCOPE_CHUNK => 2;	 # Until the next blank line.
	use constant SCOPE_NEST => 3;		# Until a (weakly) stronger conditional.
	
	#*** evaluate_conditional($conditional)
	#	Evaluates a expression from a data-file conditional directive.
	sub evaluate_conditional($) {
		my $conditional = shift;
		my $expression = '';
		
		# Pick out tokens.
		while ($conditional =~ /([a-z_\d]+|[><!\(\)]+|==|>=|<=|!=|&&|\|\||\s*)/gi) {
			
			# Look up identifiers in the hash.
			my $token = $1;
			$expression .= ($token =~ /[a-z_]/) ? "$conditional_values{$token}" : $token;
		}
		return eval $expression;
	}
	
	#*** conditional_regex()
	#	Returns a regex that matches conditionals, capturing stopwords,
	#	the condition itself and scope keywords, in that order.
	sub conditional_regex() {
		return qr/\(\s*($stopwords_regex\b)*(.*?)($scope_regex)?\s*\)/o;
	}
	
	sub parse_conditional($$$) {
		my ($stopwords, $condition, $scope) = @_;
		my ($strength, $result, $backscope, $forwardscope);
		$strength = 0;
		$strength += $stopword_weights{$_} foreach (split /\s+/, lc($stopwords));
		$result = vero($condition);
		
		# The regexes we use to test here are considerably more general
		# than is allowed by the specification, but we're working on the
		# assumption that the input was first matched against the regex
		# returned by &conditional_regex, which is rather stricter.
		# Do we have a stopword that gives us implicit backscope?
		my $implicit_backscope = 0;
		$implicit_backscope ||= exists($backscoped_stopwords{$_}) foreach (split /\s+/, lc($stopwords));
		$backscope =
		$scope =~ /versuum|omittuntur/i ? SCOPE_NEST
		: $scope =~ /versus|omittitur/i ? SCOPE_CHUNK
		: $scope !~ /semper/i && $implicit_backscope ? SCOPE_LINE
		: SCOPE_NULL;
		
		if ($scope =~ /omittitur|omittuntur/i) {
			$forwardscope = SCOPE_NULL;
		} elsif ($scope =~ /dicuntur/i) {
			$forwardscope = ($backscope == SCOPE_CHUNK) ? SCOPE_CHUNK : SCOPE_NEST;
		} else {
			$forwardscope = ($backscope == SCOPE_CHUNK || $backscope == SCOPE_NEST) ? SCOPE_CHUNK : SCOPE_LINE;
		}
		return ($strength, $result, $backscope, $forwardscope);
	}
}

#*** cache_prayers()
#	Loads Prayers.txt for each language into global hash.
sub cache_prayers() {
	our %prayers;
	our ($lang1, $lang2);
	our $datafolder;
	my $dir = our $missa ? 'Ordo' : 'Psalterium';
	$prayers{$lang1} = setupstring($lang1, "$dir/Prayers.txt");
	$prayers{$lang2} = setupstring($lang2, "$dir/Prayers.txt");
}

#*** sub expand($line, $lang, $antline)
# for & references calls the sub
# $ references are filled from Psalterium/Prayers file
# antline to handle redding the beginning of psalm is same as antiphona
# returns the expanded text or the link
sub expand {
	use strict;
	my ($line, $lang, $antline) = @_;
	$line =~ s/^\s+//;
	$line =~ s/\s+$//;
	
	# Extract and remove the sigil indicating the required expansion type.
	# TODO: Fail more drastically when the sigil is invalid.
	$line =~ s/^([&\$])// or return $line;
	my $sigil = $1;
	our ($expand, $missa);
	local $expand = $missa ? 'all' : $expand;
	
	#returns the link or text for & references
	if ($sigil eq '&') {
		
		# Make popup link if we shouldn't expand.
		if ($expand =~ /nothing/i
			|| ($expand !~ /all/i && ($line =~ /^(?:[A-Z]|pater_noster)/)))
		{
			return setlink($sigil . $line, 0, $lang);
		}
		
		# Actual expansion for & references.
		# Get function name and any parameters.
		my ($function_name, $arg_string) = ($line =~ /(.*?)(?:[(](.*)[)])?$/);
		my @args = (parse_script_arguments($arg_string), $lang);
		
		# If we have an antiphon, pass it on to the script function.
		if ($antline) {
			$antline =~ s/^\s*Ant\. //i;
			push @args, $antline;
		}
		return dispatch_script_function($function_name, @args);
	} else		# Sigil is $, so simply look up the prayer.
	{
		if ($expand =~ /all/i) {
			
			#actual expansion for $ references
			our %prayers;
			return $prayers{$lang}->{$line};
		} else {
			return setlink($sigil . $line, 0, $lang);
		}
	}
}
1;

# use warnings;
# use strict;

sub capitulum_major {
  my $lang = shift;

  our ($winner, $vespera, $seasonalflag, $version, $hora, $label);

  my $name = 'Capitulum Laudes';    # same for Vespera
                                    # special cases
  $name = 'Capitulum Vespera 1' if $winner =~ /12-25/ && $vespera == 1;
  $name = 'Capitulum Vespera' if $winner =~ /C12/;

  setbuild('Psalterium/Special/Major Special', $name, 'Capitulum ord');

  my ($capit, $c) = getproprium($name, $lang, $seasonalflag, 1);
  if (!$capit && !$seasonalflag) { ($capit, $c) = getproprium($name, $lang, 1, 1); }

  if (!$capit) {
    my %capit = %{setupstring($lang, 'Psalterium/Special/Major Special.txt')};
    $name = gettempora('Capitulum major');

    if ($version =~ /Monastic/) {
      $name .= 'M';
      $name =~ s/Day[1-5]M/DayFM/i;
    }
    $name .= " $hora";
    $capit = $capit{$name};
  }

  if ($version =~ /^Monastic/) {
    my (@capit) = split(/\n/, $capit);
    postprocess_short_resp(@capit, $lang);
    $capit = join("\n", @capit);
  }

  setcomment($label, 'Source', $c, $lang);
  $capit;
}

sub monastic_major_responsory {
  my $lang = shift;

  our ($hora, $winner, $vespera, $seasonalflag, $version);

  my $key = "Responsory $hora";

  # special case only 4 times
  $key .= ' 1' if ($winner =~ /(?:12-25|Quadp[123]-0)/ && $vespera == 1);

  my ($resp, $c) = getproprium($key, $lang, $seasonalflag, 1);

  # Monastic Responsories at Major Hours are usually identical to Roman at Tertia and Sexta
  if (!$resp) {
    $key =~ s/Vespera/Breve Sexta/;
    $key =~ s/Laudes/Breve Tertia/;
    ($resp, $c) = getproprium($key, $lang, $seasonalflag, 1);
  }

  # For backwards compatability, look for the legacy "R.br & Versicle" if necessary
  if (!$resp) {
    $key =~ s/Breve //;
    ($resp, $c) = getproprium($key, $lang, $seasonalflag, 1);
  }

  # For backwards compatibility, remove any attached versicle
  $resp =~ s/\n?_.*//s;

  if ($resp) {
    my @resp = split("\n", $resp);
    postprocess_short_resp(@resp, $lang);
    $resp = join("\n", @resp);
  }

  $resp;
}

sub capitulum_minor {
  my $lang = shift;

  our ($hora, $version, $votive, $seasonalflag, $label, $item);

  my %capit = %{setupstring($lang, 'Psalterium/Special/Minor Special.txt')};
  my $name = gettempora('Capitulum minor') . " $hora";
  $name = 'Completorium' if $hora eq 'Completorium';
  $name .= 'M' if ($version =~ /Monastic/);
  my $capit = $capit{$name} =~ s/\s*$//r;
  my ($resp, $comment);

  if ($resp = $capit{"Responsory $name"}) {
    $resp =~ s/\s*$//;
    $capit =~ s/\s*$/\n_\n$resp/;
  }

  if ($hora eq 'Completorium' && $version !~ /^Ordo Praedicatorum/) {
    $capit .= "\n_\n$capit{'Versum 4'}";
  } else {
    $comment = $name =~ /Dominica|Feria/ ? 5 : 1;
    setbuild('Psalterium/Special/Minor Special', $name, 'Capitulum ord');

    #look for special from prorium the tempore or sancti
    # use Laudes for Tertia apart C12
    my $key = "Capitulum $hora";
    $key =~ s/Tertia/Laudes/ if ($hora eq 'Tertia' && $votive !~ /C12/);
    my ($w, $c) = getproprium($key, $lang, $seasonalflag, 1);

    if ($w && $w !~ /\_\nR\.br/) {    # add responsory if missing
      $name = "Responsory $hora";
      $name .= 'M' if ($version =~ /Monastic/);    # getproprium subsitutes Nocturn 123 Versum only from Commune
      my ($wr, $cr) = getproprium($name, $lang, $seasonalflag, 1);

      if (!$wr) {

        # The Versicle in Monastic is usually taken from the 3 Nocturns in order
        my %replace = (
          Tertia => 'Nocturn 1 Versum',    # getproprium subsitutes Versum 1 only from Commune
          Sexta => 'Nocturn 2 Versum',
          Nona => 'Nocturn 3 Versum',
        );
        my $vers = '';

        if ($version !~ /Monastic/) {

          # The Short Response in Roman is usually composed of the Versicles of the 3 Nocturns
          # with the Versicle of the next Nocturn (Laudes being the "4th") attached
          %replace = (
            Tertia => 'Versum Tertia',    #	getproprium substitutes Nocturn 2 Versum only from Commune
            Sexta => 'Versum Sexta',      #	getproprium substitutes Nocturn 3 Versum only from Commune
            Nona => 'Versum Nona',        #	getproprium substitutes Versum 2 only from Commune
          );
          ($wr, $cr) = getproprium("Responsory Breve $hora", $lang, $seasonalflag, 1);
          $wr =~ s/\s*$/\n\_\n/ if $wr;
        }

        ($vers, $cvers) = getproprium($replace{$hora}, $lang, $seasonalflag, 1);
        $wr .= $vers;
      }
      $resp = $wr || $resp;
      $w =~ s/\s*$/\n_\n$resp/;
    }

    if ($w) {
      $capit = $w;
      $comment = $c;
    }
  }

  my @capit = split("\n", $capit);
  postprocess_short_resp(@capit, $lang);

  if ($hora ne 'Completorium') {
    setcomment($label, 'Source', $comment, $lang);
  }

  @capit;
}

1;
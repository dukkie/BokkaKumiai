package BokkaKumiai;
use Mouse;
our $VERSION = '0.01';

#- input 
has 'key' => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);
has 'time' => (
	is => 'rw',
	isa => 'Str', 	#-本当は分数
	required => 1,
);

has 'pattern' => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

has 'cord_progress' => (	#- コード進行
	is => 'rw',
	isa => 'ArrayRef',
);

has 'tension' => (
	is => 'rw',
	isa => 'Int',
);

__PACKAGE__->meta->make_immutable;
no Mouse;


use Data::Dumper;

#- サブルーチン群


#- コード進行出力
sub print_code_progress {
	my ( $self ) = shift;
	my ( $output ) = "$self->{time}\n";
	my ( $cntr ) = 0;
	foreach my $bar ( @{$self->{cord_progress}} ){
		$output .= sprintf("| %-8s", $bar);
		$cntr++;
		if ( $cntr % 4 eq 0 ) {
			$output .= "|\n";
		}
	}
	print $output . "\n";

}

#- コード進行をパターンから生成
sub mk_code_progress {
	my $self = shift;
	my $cp;	#- array ref
	if ( $self->{pattern} eq 'pachelbel' ) {
		$self->{cord_progress} = ['I V/VII', 'VIm IIIm/V', 'IV I/III', 'IV/II V7'];
	} elsif ( $self->{pattern} eq 'blues' ) {
		$self->{cord_progress} = ['I', 'I', 'I', 'I', 'IV', 'IV', 'I', 'I', 'V', 'IV', 'I', 'V7'];
	} elsif ( $self->{pattern} eq 'vamp' ) {
		$self->{cord_progress} = ['I', 'I', 'IV', 'IV', 'I', 'I', 'IV', 'IV'];
	} elsif ( $self->{pattern} eq 'icecream' ) {
		$self->{cord_progress} = ['I', 'VIm', 'IIm', 'V7', 'I', 'VIm', 'IIm', 'V7'];
	} elsif ( $self->{pattern} eq 'major3' ) {
		$self->{cord_progress} = ['bVI', 'bVII', 'I', 'I'];
	}
	if ( $self->{tension} >= 1 )  {
		$self->add_tension;
	}
	$self->ajust_keys;
}

#- キーに合わせる
sub ajust_keys {
	my ( $self ) = shift;
	my ( $wholetone ) = 	['C','C#', 'D',  'Eb',  'E', 'F', 'F#','G', 'Ab', 'A',  'Bb',  'B'];
	my ( $relative_tone ) = {
		'I' => 0,
		'#I' => 1,
		'II' => 2,
		'bIII' => 3,
		'III' => 4,
		'IV' => 5,
		'#IV'=>6,
		'V' => 7,
		'bVI'=>8,
		'VI'=>9,
		'bVII' => 10,
		'VII' => 11
	};
	$wholetone = $self->arrange_order( $wholetone );
	my ( $many_codes ) = 0;
	my ( $pedal_codes ) = 0;
	foreach my $bar ( @{$self->{cord_progress}} ) {
		my @codes;
		if ( $bar =~ /\s+/ ) {
			@codes = split (/\s+/, $bar);
			$many_codes = 1;
		} else {
			push @codes, $bar;
		}
		foreach my $code ( @codes ) {
			my ( @notes );
			if ( $code =~ /\// ) {
				@notes = split (/\//, $code );
				$pedal_codes = 1;
			} else {
				push @notes, $code;
			}
			foreach my $note ( @notes ) {	#- 1コードレベル
				my ( $minor_Major );
				if ( $note =~ /([mM\d]+)$/ ) {
					$minor_Major = $1;
					$note =~ s/$minor_Major//;
				}
				my ( $pntr ) = $relative_tone->{$note};
				if ( $minor_Major ) {
					$note = $wholetone->[$pntr] . $minor_Major;
				} else { 
					$note = $wholetone->[$pntr];
				}
			}
			if ( $pedal_codes ) {
				$code = join ('/', @notes);
			} else {
				$code = $notes[0];
			}
		}
		if ( $many_codes ) {
			$bar = join (' ', @codes);
		} else {
			$bar = $codes[0];
		}
	}

}

#- ホールトーンスケールの順序を変える
sub arrange_order {
	my ( $self, $wholetone ) = @_;
	my ( $neworder ) = [];
	my ( @tmparray_before, @tmparray );
	my ( $done ) = 0;
	for ( my $i = 0; $i <= $#$wholetone; $i++ ) {
		if ( $self->{key} eq $wholetone->[$i] ) {
			$done = 1;
			push @tmparray, $wholetone->[$i];
		} elsif ( $done < 1 )  {
			push @tmparray_before, $wholetone->[$i];
		} else {
			push @tmparray, $wholetone->[$i];
		}
	}
	push @tmparray, @tmparray_before;
	$neworder = \@tmparray;
	return $neworder;
}

#- テンションをつける
sub add_tension {
	my ( $self ) = shift;
	my ( $tension_notes ) = {
		#- 適当
		'I' => ['6', '69', 'M7', 'M79'],
		'#I' => [],
		'II' => ['7'],
		'bIII' => ['7'],
		'III' => ['7'],
		'IV' => ['M7', 'M79', 'M713'],
		'#IV'=> [],
		'V' => ['7', '79', '713'],
		'bVI'=>['7'],
		'VI'=>['7'],
		'bVII' => ['7'],
		'VII' => [], 
	};
	my ( $many_codes ) = 0;
	my ( $pedal_codes ) = 0;
	foreach my $bar ( @{$self->{cord_progress}} ) {
		my @codes;
		if ( $bar =~ /\s+/ ) {
			@codes = split (/\s+/, $bar);
			$many_codes = 1;
		} else {
			push @codes, $bar;
		}
		foreach my $code ( @codes ) {
			my $pedal_cord;
			if ( $code =~ '/' ) {
				( $code, $pedal_cord) = split ('/', $code);
			}
			$code =~ s/\d+$//g;
			my ( $minor_Major );
			if ( $code =~ /([mM])$/ ) {
				$minor_Major = $1;
				$code =~ s/$minor_Major//;
			}	
			#- def tension
			my $tension = '';
			for ( my $i = ($self->{tension} - 1); $i >= 0; $i-- ) {
				if ( $tension_notes->{$code}->[$i] ) {
					$tension = $tension_notes->{$code}->[$i];
					last;
				}
			}
			if ( $minor_Major ) {
				$code .= $minor_Major . $tension;
			} else { 
				$code .= $tension;
			}
			if ( $pedal_cord ) {
				$code .= '/' . $pedal_cord;
			}
		}
		if ( $many_codes ) {
			$bar = join (' ', @codes);
		} else {
			$bar = $codes[0];
		}
	}
}

1;
__END__

=head1 NAME

BokkaKumiai - Music Code Progression Analysis Module.


=head1 SYNOPSIS

  use BokkaKumiai;

=head1 DESCRIPTION

BokkaKumiai is

=head1 AUTHOR

DUKKIE E<lt>dukkiedukkie@yahoo.co.jpE<gt>

thanks to Bokka Kumiai readers.
http://ameblo.jp/dukkiedukkie/

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, Musicians and JASRAC!

=cut

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

has 'bars_by_one_row' => (	#- 一行の小節数（タブ）
	is => 'rw',
	isa => 'Int',
	default => 2,
);
__PACKAGE__->meta->make_immutable;
no Mouse;


use Data::Dumper;

my $guitar_cords = +{
	'C' => [qw(0 1 0 2 3 X)],
	'C6'=> [qw(0 1 2 2 3 X)],
	'C69'=>[qw(0 3 2 2 3 X)],
	'CM7'=>[qw(0 0 0 2 3 X)],
	'D' => [qw(2 3 2 0 0 X)],
	'Dm'=> [qw(1 3 2 0 0 X)],
	'Dm7'=>[qw(1 1 2 0 0 X)],
	'E'=>  [qw(0 0 1 2 2 0)],
	'E7'=> [qw(0 0 1 0 2 0)],
	'Em'=> [qw(0 0 0 2 2 0)],
	'Em7'=>[qw(0 0 0 0 2 0)],
	'F' => [qw(1 1 2 3 3 1)],
	'FM7'=>[qw(0 1 2 3 3 1)],
	'G' => [qw(3 0 0 0 2 3)],
	'G7'=> [qw(1 0 0 0 2 3)],
	'Ab'=> [qw(4 4 5 6 6 4)],
	'Ab7'=>[qw(4 4 5 4 6 4)],
	'Am'=> [qw(0 1 2 2 0 0)],
	'Am7'=>[qw(0 1 0 2 0 0)],
	'Bb'=> [qw(1 3 3 3 1 1)],
	'Bb7'=>[qw(1 3 1 3 1 1)],
	'B'=>  [qw(2 4 4 4 2 2)],
};
#- ハイノートも欲しい


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
	if ( $self->{tension} )  {
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

#- ギタータブ譜を書く
sub guitar_tab {
	my $self = shift;
	my $one_bar_str = 1;
	my $guitar_str = [qw(e B G D A E)];
	my $one_row;
	my $tab = +{};
	my $tab_block = +{};
	my $tab_blocks = 0;
	my $sprint_format_num = 0;
	#- 拍子で長さを決める。フォーマト&build_tab_format;
	if ( $self->{time} =~ /(\d+)\/(\d+)/ ) {
		my $child = $1;
		my $mother = $2;
		my $hyphens = 1 + ( $mother * $child );
		 $sprint_format_num =  $mother * $child ; 
		for ( my $i = 0; $i < $hyphens; $i++ ) {
			$one_row .= '-';
		}

	##} elsif ( $self->{time} eq '3/4' ) {


	}
	##print "\$one_row->$one_row\n";

	#- 運指を決める


	#- 採譜する かつタブ書式ブロックを作る。
	my $bar_cnt = 0;
	my $bars_by_one_row = $self->{bars_by_one_row};
	for my $bar ( @{$self->{cord_progress}} ) {
		if ( $bar_cnt % $bars_by_one_row == 0 ) {
			$tab_block->{$tab_blocks} .= '   ';
		} else {
			$tab_block->{$tab_blocks} .= '  ';
		}
		my ( @cords );
		if ( $bar =~ / / ) {
			@cords = split (/ /, $bar);
		} else {
			push @cords, $bar;
		}
		my ( $sprintf_format_num ) = int( $sprint_format_num / ( $#cords + 1 ));
		my ( $code_num ) = 0;
		for my $cord ( @cords ) {
			my $format = '%-' . $sprintf_format_num . 's';
			$tab_block->{$tab_blocks} .= sprintf($format, $cord);
		}
		if ( $bar_cnt % $bars_by_one_row == 1 ) {
			$tab_block->{$tab_blocks} .= "\n";
		}
		#- 以上ヘッダづくり
		#- ここに伯ごとに+出力
		my $str_num = 0;
		for my $str ( @{$guitar_str} ) {
			my $one_tab_row = $one_row;
			#- コードの内容に応じて、指をおく。
			#- ビートも考慮したい。
			my ( $cord_num ) = 0;
			for my $cord ( @cords ) {
				if ( $cord  =~ /(\/[A-Z#b]+)/ ) {
					$cord =~ s/$1//g;
				}
				if ( ( defined $guitar_cords->{$cord}->[$str_num] ) &&  ( $guitar_cords->{$cord}->[$str_num] ne '' )) {
					my $str_len = length ( $guitar_cords->{$cord}->[$str_num] );
					my $offset = 1 + ( $sprintf_format_num * $cord_num );
					#print 'note:' , $guitar_cords->{$cord}->[$str_num] ,"\n";
					#print "\$offset->$offset\n";
					#print "\$one_tab_row->$one_tab_row\n";
					#print "\$str_len->$str_len\n";
					substr($one_tab_row, $offset, $str_len, $guitar_cords->{$cord}->[$str_num]);
				}
				$cord_num++;
			}

			if ( $bar_cnt % $bars_by_one_row == 0 ) {
				$tab->{$bar_cnt}->{$str} =  "$str:$one_tab_row|"; #- 譜面を書く
			} else {
				$tab->{$bar_cnt}->{$str} =  "$one_tab_row|";	#- 譜面を書く
			}
			#- 最後に来て、かつ2ブロック目ならまとめて書きだす
			if (( $bar_cnt % $bars_by_one_row  == 1) && ( $#$guitar_str == $str_num )) {
				for my $Str ( @{$guitar_str} ) {
					for my $i ( sort {$a<=>$b} keys %$tab ) {
						$tab_block->{$tab_blocks} .= $tab->{$i}->{$Str};
					}
					$tab_block->{$tab_blocks} .=  "\n";
				}
				$tab_blocks++;
				$tab = undef;
			}
			$str_num++;
		}
		$bar_cnt++;
	}
	#- 出力する
	for my $cnt ( sort {$a<=>$b} keys %$tab_block ) {
		print $tab_block->{$cnt};
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

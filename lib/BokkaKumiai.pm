package BokkaKumiai;
use Mouse;
use Mouse::Util::TypeConstraints;
our $VERSION = '0.01';

#- type
subtype 'BokkaKumiai::Keys'
	=> as 'Str',
	=> where { $_ =~ /^(C|C#|Db|D|D#|Eb|E|F|F#|Gb|G|G#|Ab|A|A#|Bb|B)$/ }
	=> message { "This key ($_) is not musical keys!" }
;
subtype 'BokkaKumiai::Time'
	=> as 'Str',
	=> where { $_ =~ /^\d+\/\d+$/ }
	=> message { "This time ($_) is not musical time!" }
;
subtype 'BokkaKumiai::Beat'
	=> as 'Int',
	=> where { $_ =~ /^(2|4|8|16)$/ },
	=> message { "This beat ($_) is not musical beat!" }
;
subtype 'BokkaKumiai::Tension'
	=> as 'Int',
	=> where { $_ =~ /^(undef|0|1|2|3|4)$/ }
	=> message { "This tention level ($_) is not supperted by BokkaKumiai.enter 1-4" }
;
subtype 'BokkaKumiai::OneRow'
	=> as 'Int',
	=> where { $_ =~ /^(2|4)$/ }
	=> message { "This bars_by_one_row  ($_) is not supperted by BokkaKumiai: enter 2 or 4" }
;

#- input 
has 'key' => (
	is => 'rw',
	isa => 'BokkaKumiai::Keys',
	required => 1,
);
has 'time' => (
	is => 'rw',
	isa => 'BokkaKumiai::Time',
	required => 1,
	default => '4/4',
);

has 'beat' => (	
	is => 'rw',
	isa => 'BokkaKumiai::Beat',
	default => 4,
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
	isa => 'BokkaKumiai::Tension',
);

has 'bars_by_one_row' => (	#- 一行の小節数（タブ）
	is => 'rw',
	isa => 'BokkaKumiai::OneRow',
	default => 2,
);
__PACKAGE__->meta->make_immutable;
no Mouse;
no Mouse::Util::TypeConstraints;

use Data::Dumper;

my $guitar_cords = +{
	'standard' => +{
		'C' => [qw(0 1 0 2 3 X)],
		'C6'=> [qw(0 1 2 2 3 X)],
		'C69'=>[qw(0 3 2 2 3 X)],
		'CM7'=>[qw(0 0 0 2 3 X)],
		'C7' =>[qw(0 1 3 2 3 X)],
		'C#' =>[qw(4 6 6 6 4 4)],
		'C#M7'=>[qw(4 6 6 6 4 4)],
		'D' => [qw(2 3 2 0 0 X)],
		'D7'=> [qw(2 1 2 0 0 X)],
		'Dm'=> [qw(1 3 2 0 0 X)],
		'Dm7'=>[qw(1 1 2 0 0 X)],
		'Eb'=> [qw(6 8 8 8 6 6)],
		'Eb7'=>[qw(6 8 6 8 6 6)],
		'E'=>  [qw(0 0 1 2 2 0)],
		'E7'=> [qw(0 0 1 0 2 0)],
		'Em'=> [qw(0 0 0 2 2 0)],
		'Em7'=>[qw(0 0 0 0 2 0)],
		'F' => [qw(1 1 2 3 3 1)],
		'Fm'=> [qw(1 1 1 3 3 1)],
		'FM7'=>[qw(0 1 2 3 3 X)],
		'FM79'=>[qw(0 1 0 3 3 X)],
		'G' => [qw(3 0 0 0 2 3)],
		'Gm'=> [qw(3 3 3 5 5 3)],
		'G7'=> [qw(1 0 0 0 2 3)],
		'Ab'=> [qw(4 4 5 6 6 4)],
		'Ab7'=>[qw(4 4 5 4 6 4)],
		'Am'=> [qw(0 1 2 2 0 0)],
		'Am7'=>[qw(0 1 0 2 0 0)],
		'Bb'=> [qw(1 3 3 3 1 1)],
		'Bbm'=>[qw(1 2 3 3 1 1)],
		'Bb7'=>[qw(1 3 1 3 1 1)],
		'Bbm7'=>[qw(1 2 1 3 1 1)],
		'B'=>  [qw(2 4 4 4 2 2)],
		'Bm'=> [qw(2 3 4 4 2 2)],
	},
	'funky' => +{

	},
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
	} elsif ( $self->{pattern} eq 'iwantyouback' ) {
		$self->{cord_progress} = ['I','IV','VIm I/III IVM7 I','IIm7 V7 I I'];
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
	my $tab = +{};
	my $print_out_block = +{};	#-書き出し用単位
	my $beat_tick = +{};
	my $tab_blocks = 0;
	#- 拍子で長さを決める。フォーマトbuild_tab_format;
	my ( $child, $mother, $one_bar_length, $one_beat_length, $one_row, $one_bar_tick ) = $self->build_tab_format;
	my $bar_cnt = 0;
	my $bars_by_one_row = $self->{bars_by_one_row};
	#- コード進行に応じた一小節ごとのループ
	for my $bar ( @{$self->{cord_progress}} ) {
		#- 一行目のコード進行表示部分
		if ( $bar_cnt % $bars_by_one_row == 0 ) {
			$print_out_block->{$tab_blocks} .= '   ';
		} else {
			$print_out_block->{$tab_blocks} .= '  ';
		}
		my ( @cords );
		if ( $bar =~ / / ) {
			@cords = split (/ /, $bar);
		} else {
			push @cords, $bar;
		}
		my ( $sprintf_format_num ) = int( $one_bar_length / ( $#cords + 1 )); #- 3つあるときは？？
		my ( $code_num ) = 0;
		for my $cord ( @cords ) {
			my $format = '%-' . $sprintf_format_num . 's';
			$print_out_block->{$tab_blocks} .= sprintf($format, $cord);
		}
		if ( $bar_cnt % $bars_by_one_row == ($bars_by_one_row -1) ) {
			$print_out_block->{$tab_blocks} .= "\n";
		}
		#- 以上ヘッダづくり
		my $string_num = 0;
		for my $string ( @{$guitar_str} ) {
			my $one_tab_row = $one_row;
			#- コードの内容に応じて、指をおく。
			my ( $cord_num ) = 0;
			for my $cord ( @cords ) {
				if ( $cord  =~ /(\/[A-Z#b]+)/ ) {
					$cord =~ s/$1//g;
				}
				if ( ( defined $guitar_cords->{standard}->{$cord}->[$string_num] ) &&  ( $guitar_cords->{standard}->{$cord}->[$string_num] ne '' )) {
					my $string_len = length ( $guitar_cords->{standard}->{$cord}->[$string_num] );
					#- 置き換え位置をここで決めている。
					my $offset = 1 + ( $sprintf_format_num * $cord_num );
					#- 弦を押さえる。
					substr($one_tab_row, $offset, $string_len, $guitar_cords->{standard}->{$cord}->[$string_num]);
					#- 弱拍の考慮 mute beat
					my ( $mute_beat_offset );
					if ( $self->{beat} == 2) {
						$mute_beat_offset = $sprintf_format_num - 3 + ($sprintf_format_num * $cord_num );
					} elsif ( $self->{beat} == 4) {
						$mute_beat_offset = $sprintf_format_num - 3 + ($sprintf_format_num * $cord_num );
						
					} elsif ( $self->{beat} == 8 ) {
						$mute_beat_offset = $sprintf_format_num - 1 + ($sprintf_format_num * $cord_num );
					} elsif ( $self->{beat} == 16 ) {
						$mute_beat_offset = $sprintf_format_num - 1 + ($sprintf_format_num * $cord_num );
					} 
					substr($one_tab_row, $mute_beat_offset, $string_len, $guitar_cords->{standard}->{$cord}->[$string_num]);
					
				}
				$cord_num++;
			}

			if ( $bar_cnt % $bars_by_one_row == 0 ) {
				$tab->{$bar_cnt}->{$string} =  "$string:$one_tab_row|"; #- 譜面を書く
			} else {
				$tab->{$bar_cnt}->{$string} =  "$one_tab_row|";	#- 譜面を書く
			}
			#- 最後に来て、かつ2ブロック目ならまとめて書きだしハッシュを作る
			if (( $bar_cnt % $bars_by_one_row == ( $bars_by_one_row - 1)) && ( $#$guitar_str == $string_num )) {
			##if (( $bar_cnt % $bars_by_one_row  == 1) && ( $#$guitar_str == $string_num )) {
				#- 一拍ごとの区切りをつける
				$print_out_block->{$tab_blocks} .= ' ';
				for ( my $i = 0; $i < $bars_by_one_row; $i++ ) {
					$print_out_block->{$tab_blocks} .= ' '. $one_bar_tick;
				}
				$print_out_block->{$tab_blocks} .= "\n";
				#- 各弦ごとのタブを連結
				for my $Str ( @{$guitar_str} ) {
					for my $i ( sort {$a<=>$b} keys %$tab ) {
						$print_out_block->{$tab_blocks} .= $tab->{$i}->{$Str};
					}
					$print_out_block->{$tab_blocks} .=  "\n";
				}
				$tab_blocks++;
				$tab = undef;
			}
			$string_num++;
		}
		$bar_cnt++;
	}
	#- 出力する
	for my $cnt ( sort {$a<=>$b} keys %$print_out_block ) {
		print $print_out_block->{$cnt};
	}
}

#- 一小節のフォーマットづくり
sub build_tab_format {
	my $self = shift;
	my ( $one_bar_length, $one_beat_length, $one_row, $one_bar_tick);
	my ( $child, $mother ) = split ('/', $self->{time} );
	if ( ( $mother == 4 ) || ( $mother == 2) )  {
		$one_bar_length =  $mother * $child ;
	} elsif ( ( $mother == 8 ) || ( $mother == 16 ) )  {
		$one_bar_length =  ( $mother * $child ) / 2 ;
	}
	$one_beat_length = $one_bar_length / $child;
	for ( my $i = 0; $i < $one_bar_length; $i++ ) {
		$one_row .= '-';
		if ( $i % $one_beat_length == 0 ) {
			$one_bar_tick .= '+';
		} else {
			$one_bar_tick .= ' ';
		}
	}
	$one_row .= '-';	#-見やすくするため一つ足す
	$one_bar_tick = ' ' . $one_bar_tick;
	return ( $child, $mother, $one_bar_length, $one_beat_length, $one_row, $one_bar_tick);
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

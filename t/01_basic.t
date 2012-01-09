use strict;
use Test::More tests => 5;

require_ok ('BokkaKumiai');

my $cp = BokkaKumiai->new(
	'key' => 'C',
	'time' => '4/4',
	'beat' => 4,
	'pattern' => 'pachelbel',
);
#- $cpはBokkaKumiaiクラスであるか？
isa_ok ( $cp, "BokkaKumiai");

#- 必要なメソッドがあるか？　
my @methods = qw(guitar_tab mk_chord_progress return_offset);
can_ok ( $cp, @methods );

ok ( $cp->return_offset(4,4,1,0), 'オフセット期待値' );
ok ( $cp->return_offset(16,8,2,1), 'オフセット期待値' );

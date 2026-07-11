package My::TAP::Harness;
  
use base 'TAP::Harness';
my $harness = TAP::Harness->new;

$harness->rules({
  seq => [
    { seq => 't/test1.t'},
    { seq => 't/test6.t'},
    { par => ['t/test3.t', 't/test4.t', 't/test5.t'], },
    { seq => 't/test2.t'},
  ],
});

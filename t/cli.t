use t::TestSimple tests => 3;

filters {
    command => [qw(chomp run_command)],
    result => 'set_result',
};

run_is command => 'result';

sub run_command {
    open my $execution, "$^X bin/$_ |"
      or die "Couldn't open subprocess: $!\n";
    local $/;
    my $output = <$execution>;
    close $execution;
    undef $_;
    return $output;
}

sub set_result {
    return <<'...';
Hi Lyssa,

Have a nice day.

Smooches, Ingy
...
}

__DATA__

=== Render
--- command
tt-render --post-chomp --data=t/render.yaml --path=t/template/ letter.tt
--- result
=== Render with path//template
--- command
tt-render --post-chomp --data=t/render.yaml t/template//letter.tt
--- result
=== Options abbreviated
--- command
tt-render --post-c --d=t/render.yaml -I t/template/ letter.tt
--- result

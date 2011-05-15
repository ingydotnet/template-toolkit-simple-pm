use TestML -run,
    -require_or_skip => 'YAML::XS';

sub run_command {
    my $command = shift->value;
    open my $execution, "$^X bin/$command |"
      or die "Couldn't open subprocess: $!\n";
    local $/;
    my $output = <$execution>;
    close $execution;
    return $output;
}

__DATA__
%TestML 1.0

Plan = 3;

wanted = *wanted;
*command.Chomp.run_command == wanted;

=== Want this output
--- wanted
Hi Löver,

Have a nice day.

Smööches, Ingy

=== Render
--- command
tt-render --post-chomp --data=t/render.yaml --path=t/template/ letter.tt
=== Render with path//template
--- command
tt-render --post-chomp --data=t/render.yaml t/template//letter.tt
=== Options abbreviated
--- command
tt-render --post-c --d=t/render.yaml -I t/template/ letter.tt

use TestML -run,
    -require_or_skip => 'YAML::XS',
    -require_or_skip => 'JSON::XS',
    -require_or_skip => 'XML::Simple';

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

Plan = 9;

wanted = *wanted;
*command.Chomp.run_command == wanted;

=== Want this output
--- wanted
Hi Lover,

Have a nice day.

Smooches, Ingy

=== Render YAML
--- command
tt-render --post-chomp --data=t/render.yaml --path=t/template/ letter.tt
=== Render YAML with path//template
--- command
tt-render --post-chomp --data=t/render.yaml t/template//letter.tt
=== YAML Options abbreviated
--- command
tt-render --post-c --d=t/render.yaml -I t/template/ letter.tt
=== Render JSON
--- command
tt-render --post-chomp --data=t/render.json --path=t/template/ letter.tt
=== Render JSON with path//template
--- command
tt-render --post-chomp --data=t/render.json t/template//letter.tt
=== JSON Options abbreviated
--- command
tt-render --post-c --d=t/render.json -I t/template/ letter.tt
=== Render XML
--- command
tt-render --post-chomp --data=t/render.xml --path=t/template/ letter.tt
=== Render XML with path//template
--- command
tt-render --post-chomp --data=t/render.xml t/template//letter.tt
=== XML Options abbreviated
--- command
tt-render --post-c --d=t/render.xml -I t/template/ letter.tt

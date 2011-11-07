use TestML -run,
    -require_or_skip => 'YAML::XS';

use Template::Toolkit::Simple;

sub render_template {
    my $context = shift;
    return tt
        ->post_chomp
        ->path('t/template')
        ->data('t/render.yaml')
        ->render($context->value);
}

__DATA__
%TestML 1.0

Plan = 1;

*template.render_template == *result;

=== Simple Render
--- template: letter.tt
--- result
Hi Löver,

Have a nice day.

Smööches, Ingy

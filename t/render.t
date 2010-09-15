use TestML -run;

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
Hi Lover,

Have a nice day.

Smooches, Ingy

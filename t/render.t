use t::TestSimple tests => 1;
use Template::Toolkit::Simple;

filters {
    template => ['render_template'],
};

run_is template => 'result';

sub render_template {
    undef $_;
    return tt
        ->post_chomp
        ->path('t/template')
        ->data('t/render.yaml')
        ->render(shift);
}

__DATA__
=== Simple Render
--- template: letter.tt
--- result
Hi Lyssa,

Have a nice day.

Smooches, Ingy

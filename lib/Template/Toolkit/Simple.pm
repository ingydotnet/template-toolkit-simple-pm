##
# name:      Template::Toolkit::Simple
# abstract:  A Simple Interface to Template Toolkit
# author:    Ingy döt Net <ingy@cpan.org>
# copyright: 2008, 2009, 2010, 2011
# license:   perl

use strict;
use warnings;
use 5.008003;
use Template 2.22 ();
use YAML::XS 0.37 ();

package Template::Toolkit::Simple;

our $VERSION = '0.16';

use Encode;
use Getopt::Long;
use Template;
use Template::Constants qw( :debug );
use YAML::XS;

use base 'Exporter';
our @EXPORT = qw(tt);

sub tt {
    return Template::Toolkit::Simple->new();
}

my $default = {
    data => undef,
    config => undef,
    output => undef,

    encoding => 'utf8',
    include_path => undef,
    eval_perl => 0,
    start_tag => quotemeta('[' . '%'),
    end_tag => quotemeta('%' . ']'),
    tag_style => 'template',
    pre_chomp => 0,
    post_chomp => 0,
    trim => 0,
    interpolate => 0,
    anycase => 0,
    delimiter => ':',
    absolute => 0,
    relative => 0,
    strict => 0,
    default => undef,
    blocks => undef,
    auto_reset => 1,
    recursion => 0,
    pre_process => undef,
    post_process => undef,
    process_template => undef,
    error_template => undef,
    output_path => undef,
    debug => 0,
    cache_size => undef,
    compile_ext => undef,
    compile_dir => undef,
};

my $abbreviations = {
    data => 'd',
    include_path => 'path|i',
    output => 'o',
    config => 'c',
};

sub new {
    my $class = shift;
    return bless shift || {%$default}, $class;
}

sub field {
    my ($name, $value) = @_;
    return sub {
        my $self = shift;
        $self->{$name} = @_ ? shift : $value;
        return $self;
    };
}

{
    for my $name (keys %$default) {
        next if $name =~ /^(data|config)/;
        my $value = $default->{$name};
        if (defined $value) {
            $value = 1 - $value if $value =~/^[01]$/;
            $value = [] if $name eq 'include_path';
        }
        no strict 'refs';
        *{__PACKAGE__ . '::' . $name} = field($name, $value);
    }
}

{
    no warnings 'once';
    *path = \&include_path;
}

sub render {
    my $self = shift;
    my $template = shift
      or die "render method requires a template name";
    if ($template =~ qr{//}) {
        my $path;
        ($path, $template) = split '//', $template, 2;
        $self->include_path($path);
    }
    $self->data(shift(@_)) if @_;
    $self->output(shift(@_)) if @_;

    if ($self->{output}) {
        $self->process($template, $self->{data}, $self->{output})
            or $self->croak;
        return '';
    }

    my $output = '';
    $self->process($template, $self->{data}, \$output)
        or $self->croak;
    return Encode::encode_utf8($output);
}

sub usage {
    return <<'...'
Usage:

    tt-render --path=path/to/templates/ --data=data.yaml foo.tt2

...
}

sub croak {
    my $self = shift;
    require Carp;
    my $error = $self->{tt}->error;
    chomp $error;
    Carp::croak($error . "\n");
};

sub process {
    my $self = shift;

    $self->{tt} = Template->new(
        ENCODING            => $self->{encoding},
        INCLUDE_PATH        => $self->{include_path},
        EVAL_PERL           => $self->{eval_perl},
        START_TAG           => $self->{start_tag},
        END_TAG             => $self->{end_tag},
        PRE_CHOMP           => $self->{pre_chomp},
        POST_CHOMP          => $self->{post_chomp},
        TRIM                => $self->{trim},
        INTERPOLATE         => $self->{interpolate},
        ANYCASE             => $self->{anycase},
        DELIMITER           => $self->{delimiter},
        ABSOLUTE            => $self->{absolute},
        STRICT              => $self->{strict},
        DEFAULT             => $self->{default},
        BLOCKS              => $self->{blocks},
        AUTO_RESET          => $self->{auto_reset},
        RECURSION           => $self->{recursion},
        PRE_PROCESS         => $self->{pre_process},
        POST_PROCESS        => $self->{post_process},
        PROCESS_TEMPLATE    => $self->{process_template},
        ERROR_TEMPLATE      => $self->{error_template},
        OUTPUT_PATH         => $self->{output_path},
        DEBUG               =>
            ($self->{debug} && DEBUG_ALL ^ DEBUG_CALLER ^ DEBUG_CONTEXT),
        CACHE_SIZE          => $self->{cache_size},
        COMPILE_EXT         => $self->{compile_ext},
        COMPILE_DIR         => $self->{compile_dir},
    );

    return $self->{tt}->process(@_);
}

sub data {
    my $self = shift;
    $self->{data} = $self->_file_to_hash(@_);
    return $self;
}

sub config {
    my $self = shift;
    $self = {
        %$self,
        $self->_file_to_hash(@_)
    };
    return $self;
}

sub _file_to_hash {
    my $self = shift;
    my $file_name = shift;
    return
        (ref($file_name) eq 'HASH')
        ? $file_name
        : ($file_name =~ /\.(?:yaml|yml)$/i)
        ? $self->_load_yaml($file_name)
        : ($file_name =~ /\.json$/i)
        ? $self->_load_json($file_name)
        : ($file_name =~ /\.xml$/i)
        ? $self->_load_xml($file_name)
        : die "Expected '$file_name' to end with .yaml, .json or .xml";
}

sub _load_yaml {
    my $self = shift;
    YAML::XS::LoadFile(shift);
}

sub _load_json {
    my $self = shift;
    require JSON::XS;
    my $json = do { local $/; open my $json, '<', shift; <$json> };
    JSON::XS::decode_json($json);
}

sub _load_xml {
    my $self = shift;
    require XML::Simple;
    XML::Simple::XMLin(shift);
}

sub _run_command {
    my $class = shift;
    my $self = $class->new($default);
    local @ARGV = @_;
    my $template = pop or do {
        print STDERR $self->usage();
        return;
    };
    my $setter = sub {
        my ($name, $value) = @_;
        my $method = lc($name);
        $method =~ s/-/_/g;
        $value = quotemeta($value)
            if $method =~ /_tag$/;
        $self->$method($value);
    };
    GetOptions(
        map {
            my $option = $_;
            my $option2 = $option;
            $option .= "|$option2" if $option2 =~ s/_/-/g;
            $option .= "|$abbreviations->{$_}"
                if defined $abbreviations->{$_};
            $option .= ((not defined $default->{$_} or $option =~/\-tag$/) ? '=s' : '');
            ($option, $setter);
        } keys %$default
    );

    print STDOUT $self->render($template); 
}

1;

=head1 SYNOPSIS

    use Template::Toolkit::Simple;

    print tt
        ->path(['./', 'template/'])
        ->data('values.yaml')
        ->post_chomp
        ->render('foo.tt');

or from the command line:

    tt-render --path=./:template/ --data=values.yaml --post-chomp foo.tt

=head1 DESCRIPTION

Template Toolkit is the best Perl template framework. The only problem
with it is that using it for simple stuff is a little bit cumbersome.
Also there is no good utility for using it from the command line.

This module is a simple wrapper around Template Toolkit. It exports a
function called C<tt> which returns a new Template::Toolkit::Simple
object. The object supports method calls for setting all the Template
Toolkit options.

This module also installs a program called C<tt-render> which you can
use from the command line to render templates with all the power of the
Perl object. All of the object methods become command line arguments in
the command line version.

=head1 COMMAND LINE USAGE

This command renders the named file and prints the output to STDOUT. If
an error occurs, it is printed to STDERR.

    tt-render [template-options] file-name

=head1 TEMPLATE PATH

When using Template::Toolkit::Simple or C<tt-render>, the most common
parameters you will use are the main template file name and the
directory of supporting templates. As a convenience, you can specify
these together.

This:

    tt->render('foo//bar/baz.tt');
    > tt-render foo//bar/baz.tt  # command line version

is the same as:

    tt->include_path('foo/')->render('bar/baz.tt');
    > tt-render --include_path=foo/ bar/baz.tt  # command line version

Just use a double slash to separate the path from the template. This is extra
handy on the command line, because (at least in Bash) tab completion still
works after you specify the '//'.

=head1 EXPORTED SUBROUTINES

=over

=item tt

Simply returns a new Template::Toolkit::Simple object. This is Simple
sugar for:

    Template::Toolkit::Simple->new();

It takes no parameters.

=back

=head1 METHODS

This section describes the methods that are not option setting methods.
Those methods are described below.

=over

=item new()

Return a new Template::Toolkit::Simple object. Takes no parameters.

=item render($template, $data);

This is the method that actually renders the template. It is similar to
the Template Toolkit C<process> method, except that it actually returns
the template result as a string. It returns undef if an error occurs.

The C<$data> field is optional and can be set with the C<data> method.

If you need more control, see the process command below:

=item process($template, $data, $output, %options);

This command is simply a proxy to the Template Toolkit C<process>
command. All the parameters you give it are passed to the real
C<process> command and the result is returned. See L<Template> for more
information.

=item output($filepath)

Specify a filepath to print the template result to.

=item error()

This method is a proxy to the Template Toolkit C<error> method. It
returns the error message if there was an error.

=back

=head1 OPTION METHODS

All of the Template Toolkit options are available as methods to
Template::Toolkit::Simple objects, and also as command line options to
the C<tt-render> command.

For example, the C<POST_CHOMP> options is available in the following ways:

    tt->post_chomp      # turn POST_CHOMP on
    tt->post_chomp(1)   # turn POST_CHOMP on
    tt->post_chomp(0)   # turn POST_CHOMP off

    --post_chomp        # turn POST_CHOMP on
    --post-chomp        # same. use - instead of _
    --post_chomp=1      # turn POST_CHOMP on
    --post_chomp=0      # turn POST_CHOMP off

If the method functionality is not explained below, please refer to
L<Template>.

=over

=item config($file_name || $hash)

If you have a common set of Template Toolkit options stored in a file,
you can use this method to read and parse the file, and set the
appropriate options.

The currently supported file formats are YAML, JSON and XML. The format
is determined by the file extension, so use the appropriate one. Note
that XML::Simple is used to parse XML files and JSON::XS is used to 
parse JSON files.

=item data($file_name || $hash)

Most templates use a hash object of data to access values while
rendering. You can specify this data in a file or with a hash reference.

The currently supported file formats are YAML, JSON and XML. The format
is determined by the file extension, so use the appropriate one. Note
the XML::Simple is used to parse XML files.

=item include_path($template_directories) -- Default is undef

This method allows you to specify the directories that are searched to
find templates. You can specify this as a string containing a single
directory, an array ref of strings containing directory names, or as a
string containing multiple directories separated by ':'.

=item path() -- Default is undef

This is a shorter name for C<include_path>. It does the exact
same thing.

=item start_tag() -- Default is '[%'

=item end_tag() -- Default is '%]'

=item tag_style() -- Default is 'template'

=item pre_chomp() -- Default is 0

=item post_chomp() -- Default is 0

=item trim() -- Default is 0

=item interpolate() -- Default is 0

=item anycase() -- Default is 0

=item delimiter() -- Default is ':'

=item absolute() -- Default is 0

=item relative() -- Default is 0

=item strict() -- Default is 0

=item default() -- Default is undef

=item blocks() -- Default is undef

=item auto_reset() -- Default is 1

=item recursion() -- Default is 0

=item eval_perl() -- Default is 0

=item pre_process() -- Default is undef

=item post_process() -- Default is undef

=item process_template() -- Default is undef

This is a proxy to the Template Toolkit PROCESS option. The C<process>
method is used to actually process a template.

=item error_template() -- Default is undef

This is a proxy to the Template Toolkit ERROR option. The C<error()>
method returns the error message on a failure.

=item debug() -- Default is 0

=item cache_size() -- Default is undef

=item compile_ext() -- Default is undef

=item compile_dir() -- Default is undef

=item encoding() -- Default is 'utf8'

=back

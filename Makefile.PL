use inc::Module::Install;

name            'Template-Toolkit-Simple';
author          'Ingy döt Net';
abstract        'A Simple Interface to Template Toolkit';
version         '0.01';
license         'perl';
perl_version    '5.008003';

requires        'Template' => '0';

install_script  'bin/tt-render';

WriteAll;

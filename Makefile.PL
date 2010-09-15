use inc::Module::Install;

all_from 'lib/Template/Toolkit/Simple.pm';
readme_from;
manifest_skip;

requires 'Template' => '0';
install_script 'bin/tt-render';
use_testml;
ack_xxx;

WriteAll;

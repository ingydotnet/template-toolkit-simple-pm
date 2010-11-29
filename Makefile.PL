use inc::Module::Install;

all_from 'lib/Template/Toolkit/Simple.pm';
readme_from;
manifest_skip;
version_check;
ack_xxx;
repository 'git://github.com/ingydotnet/template-toolkit-simple-pm.git';

requires 'Template' => '0';
recommends 'YAML::XS';

install_script 'bin/tt-render';
use_testml;

WriteAll;

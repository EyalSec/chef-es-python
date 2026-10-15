name              'eyalsec_es_python'
maintainer        'EyalSec'
maintainer_email  'eyal@eyalsec.com'
license           'MIT'
description       'Installs es-python, the EyalSec Python runtime, for one user on each node'
version           '1.0.0'
chef_version      '>= 16.0'
source_url        'https://github.com/EyalSec/chef-es-python'
issues_url        'https://github.com/EyalSec/chef-es-python/issues'

%w(ubuntu debian redhat rocky almalinux amazon fedora arch).each do |os|
  supports os
end

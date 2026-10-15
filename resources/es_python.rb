# Installs es-python, the EyalSec Python runtime, for one user, the way the
# install command on the EyalSec Machines page does. With an API key the node is
# found by machine name on your account and added on the first run. Once
# es-python is installed for the user, later runs change nothing.

provides :es_python
unified_mode true

property :user, String, name_property: true,
                        description: 'The user es-python is installed for. It installs into this user\'s home and runs as this user.'
property :api_key, String, sensitive: true,
                           description: 'A full-access EyalSec API key. One key serves every node.'
property :install_secret, String, sensitive: true,
                                  description: 'A one-time install secret for one machine. It works once and expires 10 minutes after it was issued.'
property :authorized, [true, false], default: false,
                                     description: 'Required with an API key: your confirmation that you own this node or are authorized to monitor it.'
property :machine_name, String, default: lazy { node['fqdn'] || node['hostname'] },
                                callbacks: { 'must be 1 to 128 characters' => ->(n) { n.length.between?(1, 128) } },
                                description: 'The machine name this node reports under. Each node needs its own.'
property :python_version, String, equal_to: %w(3.9 3.10 3.11 3.12 3.13 3.14),
                                  description: 'The Python version. Leave unset to match the node\'s own python3.'
property :url, String, default: 'https://eyalsec.com', regex: %r{\Ahttps://},
                       description: 'Your EyalSec address.'
property :manage_dependencies, [true, false], default: true,
                                              description: 'Install curl and CA certificates when they are missing.'
property :helper_path, String, default: '/usr/local/libexec/eyalsec/es-python-fleet-install.sh'

action :install do
  if new_resource.api_key.nil? && new_resource.install_secret.nil?
    raise Chef::Exceptions::ValidationFailed, 'es_python: set api_key or install_secret'
  end
  if new_resource.api_key && !new_resource.authorized
    raise Chef::Exceptions::ValidationFailed,
          'es_python: set authorized true to confirm you own this node or are authorized to monitor it'
  end

  if new_resource.manage_dependencies
    package platform_family?('debian') ? %w(curl ca-certificates) : %w(ca-certificates)
  end

  directory ::File.dirname(new_resource.helper_path) do
    recursive true
    mode '0755'
  end

  cookbook_file new_resource.helper_path do
    cookbook 'eyalsec_es_python'
    source 'es-python-fleet-install.sh'
    mode '0755'
  end

  env = {
    'EYALSEC_URL' => new_resource.url,
    'EYALSEC_MACHINE' => new_resource.machine_name,
    'EYALSEC_AUTHORIZED' => new_resource.authorized.to_s,
    'EYALSEC_PLAIN_OUTPUT' => '1',
  }
  env['EYALSEC_PYTHON_VERSION'] = new_resource.python_version if new_resource.python_version
  if new_resource.api_key
    env['EYALSEC_API_KEY'] = new_resource.api_key
  else
    env['EYALSEC_INSTALL_SECRET'] = new_resource.install_secret
  end

  execute "install es-python for #{new_resource.user}" do
    command ['/bin/sh', new_resource.helper_path]
    user new_resource.user
    cwd '/'
    environment env
    timeout 1800
    # Keeps the credential, which travels in the environment, out of every log.
    sensitive true
    not_if ['/bin/sh', new_resource.helper_path, '--check'], user: new_resource.user,
                                                             environment: env.slice('EYALSEC_PYTHON_VERSION'), cwd: '/'
  end
end

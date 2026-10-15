#
# Cookbook:: eyalsec_es_python
# Recipe:: default
#
# Installs es-python for node['es_python']['user'], with the API key from the
# (encrypted) data bag item node['es_python']['data_bag'] / ['data_bag_item'],
# field "api_key".

cfg = node['es_python']
key = data_bag_item(cfg['data_bag'], cfg['data_bag_item'])['api_key']

es_python cfg['user'] do
  api_key key
  authorized cfg['authorized']
  python_version cfg['python_version'] if cfg['python_version']
  machine_name cfg['machine_name'] if cfg['machine_name']
  url cfg['url']
end

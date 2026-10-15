# Used by the default recipe. To call the es_python resource from your own
# cookbook instead, ignore these.
default['es_python']['user'] = 'root'
default['es_python']['authorized'] = false
default['es_python']['python_version'] = nil
default['es_python']['url'] = 'https://eyalsec.com'
default['es_python']['machine_name'] = nil
# The API key is read from a data bag item, never from an attribute (attributes
# are saved on the Chef Infra Server with the node). Use an encrypted data bag.
default['es_python']['data_bag'] = 'eyalsec'
default['es_python']['data_bag_item'] = 'api_key'

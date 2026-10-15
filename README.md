# eyalsec_es_python: es-python for Chef

**Install es-python, the EyalSec Python runtime, on the Linux nodes you manage with Chef Infra. One API key covers the fleet, and each node reports to your EyalSec dashboard as its own machine.**

[![Website](https://img.shields.io/badge/website-eyalsec.com-e8b04b)](https://eyalsec.com)
[![Docs](https://img.shields.io/badge/docs-install-2a2c27)](https://eyalsec.com/docs/install)

Your nodes already converge on what your cookbooks describe. This cookbook adds
one resource, `es_python`, which installs es-python for the user your Python
service runs as, the same way the install command on the EyalSec Machines page
does. Once a node has es-python, later runs skip it.

es-python runs your Python app unchanged and follows untrusted input to the SQL
query, shell command or file path that uses it. You choose, per machine,
whether it reports each flow or also stops it.

**For:** teams with an EyalSec account that includes es-python, on Linux nodes
(x86_64 or aarch64), Python 3.9 to 3.14, Chef Infra Client (or Cinc Client) 16
or newer. No cookbook dependencies.

## Quick start

1. On your EyalSec dashboard, open **Settings > API access** and create a
   full-access key ([API keys](https://eyalsec.com/docs/api-keys)).
2. Store it in an encrypted data bag item, `eyalsec/api_key`, with the field
   `api_key`:

   ```bash
   knife data bag create eyalsec api_key --secret-file ~/.chef/encrypted_data_bag_secret
   ```

3. Use the resource in your own cookbook (add `depends 'eyalsec_es_python'` to
   its `metadata.rb`):

   ```ruby
   es_python 'app' do                 # the user your service runs as
     api_key data_bag_item('eyalsec', 'api_key')['api_key']
     authorized true                  # see "Authorization" below
     python_version '3.12'
   end
   ```

   Or add `recipe[eyalsec_es_python]` to the run list and set
   `node['es_python']['user']` and `node['es_python']['authorized']`; the
   recipe reads the key from the same data bag item.

Then start your service with `/home/app/.local/bin/es-python` where it ran
`python`. See [Running es-python](https://eyalsec.com/docs/running-es-python).

Until the cookbook is listed on Supermarket, point a Policyfile at this
repository:

```ruby
cookbook 'eyalsec_es_python', git: 'https://github.com/EyalSec/chef-es-python.git', tag: 'v1.0.0'
```

## The es_python resource

`es_python 'user'` with action `:install` (the default).

| Property | Default | Meaning |
|---|---|---|
| `user` | the name | The user es-python is installed for. |
| `api_key` | | A full-access API key (sensitive). One key serves every node. |
| `install_secret` | | Instead of a key: a one-time install secret for one machine (sensitive). It works once and expires 10 minutes after it was issued. |
| `authorized` | `false` | Required with an API key. See [Authorization](#authorization). |
| `machine_name` | `node['fqdn']` | The machine name this node reports under. Each node needs its own. |
| `python_version` | | `'3.9'` to `'3.14'`. Unset matches the node's own `python3`. |
| `url` | `'https://eyalsec.com'` | Your EyalSec address. |
| `manage_dependencies` | `true` | Install `curl` (Debian family) and CA certificates when they are missing. |
| `helper_path` | `/usr/local/libexec/eyalsec/es-python-fleet-install.sh` | Where the install helper is placed. |

## How it works

The resource places a small install helper on the node and runs it as `user`,
unless the helper's `--check` says es-python is already installed for that
user. The helper finds the machine named `machine_name` on your account, adds
it the first time with its build left to detection (as **Add machine** does by
default), gets a fresh one-time install secret, and runs the EyalSec installer.

es-python installs into the user's home (`~/opt/`, `~/.local/bin/es-python`,
`~/.eyalsec/`) and changes nothing system-wide. See
[What it installs](https://eyalsec.com/docs/install#what-it-installs).

## Keeping the key secret

The key reaches the helper in its environment, never on a command line. The
`execute` resource that carries it is `sensitive`, so Chef prints neither its
command, its environment nor its output, at debug level included. Keep the key
out of node attributes, which are saved on the Chef Infra Server with the node:
read it from an encrypted data bag or a vault, as above.

If an install fails, the run says so without the installer's output, because
that output is hidden with the rest of the resource. Run the helper by hand as
the user to see it, with the key in a file only that user can read:
`EYALSEC_AUTHORIZED=true sh /usr/local/libexec/eyalsec/es-python-fleet-install.sh --api-key-stdin < key-file`.

## Authorization

`authorized true` is your confirmation that you own these nodes or are
authorized to monitor them, that you will not use es-python to surveil third
parties, and that you are not located in or a national of an embargoed
destination and not on a denied-party list. It is the same statement as the
tick box on the Machines page. es-python may capture values from your program's
memory, including secrets and personal data, when untrusted data reaches a
monitored operation, so only run it on systems you are authorized to monitor.

## Things to know

- **Each node is one machine** and counts toward your
  [machine limit](https://eyalsec.com/docs/plans#machine-limit). When a node is
  retired, delete its machine on the Machines page so it stops counting.
- **Machine names must be unique.** Two nodes with the same `machine_name`
  share one machine, and the second install stops the first from reporting.
- **Updating.** To reinstall the newest build on a node, remove the user's
  launcher (`~/.local/bin/es-python`, or `es-python3.X` when `python_version`
  is set) and let the next run install again; the machine keeps its name,
  settings and events.

## Getting es-python

es-python needs an EyalSec account. To get one,
[book a live demo](https://eyalsec.com/contact); pricing is at
[eyalsec.com/pricing](https://eyalsec.com/pricing).

## License

MIT. See [LICENSE](LICENSE).

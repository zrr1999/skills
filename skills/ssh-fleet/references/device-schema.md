# Device inventory schema

`devices.toml` is a strict versioned document:

```toml
version = 1
domain = "example.com"

[[devices]]
name = "home-main"
group = "home"
hostname = "main.ssh.home.example.com"
description = "main host"
tags = ["server"]

[devices.ssh]
user = "alice"
# port = 22
# forward_agent = false

[devices.addresses]
private = { value = "10.0.0.10" }
public = { source = "snmp", key = "wan1" }
```

## Fields

- `version`: required schema version; currently `1`.
- `domain`: required DNS suffix used by generated records.
- `devices[].name`: required stable unique ID and generated SSH `Host` alias. Lowercase letters, digits, and hyphens only.
- `devices[].group`: required single primary operational group.
- `devices[].hostname`: required canonical DNS name or SSH target. Address-managed devices must be below `domain`.
- `devices[].description`: optional human-facing note.
- `devices[].tags`: optional unique selectors consumed by generators. `server` produces the compatibility Ansible groups `servers` and `server-<group>`.
- `devices[].ssh`: optional SSH capability. `user` is required; `port` defaults to `22`; `forward_agent` defaults to `false`.
- `devices[].addresses`: optional address sources for DNS outputs. `public` and `private` each contain either a literal `value` or both `source` and `key`.

Unknown fields and duplicate names are errors. Do not reintroduce `system`, `hardware`, `kind`, `roles`, `lifecycle`, `criticality`, `extra`, `ssh.alias`, nested containers, Ansible aliases, or private key paths. If a future consumer truly needs another fact, add one narrowly typed field with validation and migration tests.

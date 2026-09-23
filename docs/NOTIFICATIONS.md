# Package Repository Notifications

Repository publication has three independently controlled destinations:

| Event | Destination |
| --- | --- |
| Build failure | Private `builder-failures` Discord webhook |
| Verified publication | Private `repository-published` Discord webhook |
| Verified publication | Public `aero7-updates` Discord webhook and `aero7-updates` ntfy topic |

Notifications are not a publishing transport and cannot make a repository
current. The builder uploads signed files over SSH, the website server verifies
and atomically activates them, and a public HTTP smoke test must pass before
`repository-published` is sent.

## Builder configuration

Copy `config/notifications.example.conf` to:

```text
~/.config/aero7-builder/notifications.conf
```

Set mode `0600`. The real Discord URLs and ntfy publisher token must never be
committed or written to build logs. Run a routing test with:

```bash
scripts/notify-release.sh configuration-test setup
```

Build failures use:

```bash
scripts/notify-release.sh build-failed "$build_id" "See the retained builder log."
```

The server-side publisher uses this only after activation and public
verification:

```bash
scripts/notify-release.sh repository-published "$build_id"
```

## User notifications

`https://notify.aero7.org/aero7-updates` is readable without an account.
Publishing requires the dedicated builder token. The topic is for successful
package publications only; failed builds are never broadcast to users.

Aero7 installations do not need ntfy to discover package updates. The existing
daily local update checker remains the normal desktop path and can be turned on
or off per user in Control Panel. ntfy is an extra opt-in announcement channel.

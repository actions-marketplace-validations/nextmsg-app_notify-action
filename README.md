# NextMsg Notify

Get a push notification on your phone when a GitHub Actions workflow fails, finishes or needs your attention. One step, no bots, no chat app, no account.

[NextMsg](https://nextmsg.app) is a one-way messenger for AI agents, scripts and servers: they send, you read.

## Setup

1. Install the NextMsg app: [App Store](https://apps.apple.com/app/nextmsg-push-notifications/id6831546010) (iPhone) or [Google Play](https://play.google.com/store/apps/details?id=app.nextmsg) (Android).
2. In the app, open **Settings → Send key** and copy it (`nextmsg_live_…`).
3. In your repository: **Settings → Secrets and variables → Actions → New repository secret**, name `NEXTMSG_KEY`, paste the key.

## Usage

Notify when the build fails:

```yaml
- uses: nextmsg-app/notify-action@v1
  if: failure()
  with:
    key: ${{ secrets.NEXTMSG_KEY }}
    status: ${{ job.status }}
```

Your phone shows: `❌ CI failed on main (acme/app, run #42)`

Always report the result, in its own channel:

```yaml
- uses: nextmsg-app/notify-action@v1
  if: always()
  with:
    key: ${{ secrets.NEXTMSG_KEY }}
    status: ${{ job.status }}
    channel: deploys
```

Your own message:

```yaml
- uses: nextmsg-app/notify-action@v1
  with:
    key: ${{ secrets.NEXTMSG_KEY }}
    message: "Release **${{ github.ref_name }}** is live"
    channel: releases
```

## Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `key` | yes | | Your send key, from a secret. |
| `message` | no | run summary | Up to 640 characters (longer text is cut). `**bold**`, `*italic*`, `~~strike~~` and `` `code` `` are shown in the app. |
| `status` | no | | Usually `${{ job.status }}`; picks ✅, ❌ or ⚪ for the default message. |
| `channel` | no | `ci` | Groups messages in the app: `a-z`, `0-9`, `-`, `_`, up to 32 characters. |
| `fail-on-error` | no | `false` | Fail the step if the message can't be sent. By default it only logs a warning, so a notification never breaks your build. |

## Outputs

| Output | Description |
| --- | --- |
| `id` | Message id when sent. |
| `http-status` | HTTP status from the NextMsg API (`200` when sent). |

## Notes

- The key is sent in the `Authorization` header and masked in logs; it never appears in a URL.
- Runs on Linux, macOS and Windows runners (needs `bash`, `curl` and `jq`, all preinstalled on GitHub-hosted runners).
- The free plan includes 100 messages a month; Pro is a one-time purchase in the app.
- Prefer plain `curl`? `curl -d 'Build failed' https://api.nextmsg.app/p/$NEXTMSG_KEY`. More recipes: [nextmsg.app/guides/github-actions](https://nextmsg.app/guides/github-actions).

## License

MIT

# Releasing edge

The GitHub Actions release workflow builds a universal DMG for Apple silicon and Intel, signs the app with **Developer ID Application**, and notarizes the DMG with Apple before publishing it. A DMG is the standard Mac download: users open it and drag `edge.app` to Applications.

## Configure signing once

You need an Apple Developer Program account, a Developer ID Application certificate, and an App Store Connect Team API key for notarization. Export the certificate with its private key from Keychain Access as a password-protected `.p12` file.

Add these as repository Actions secrets for `nhestrompia/edge`:

| Secret | Value |
| --- | --- |
| `DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64` | Base64 of the application `.p12` |
| `DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD` | Password used for that `.p12` |
| `DEVELOPER_ID_APPLICATION_IDENTITY` | Exact `Developer ID Application: ...` identity |
| `NOTARY_API_KEY_BASE64` | Base64 of the App Store Connect `.p8` key |
| `NOTARY_API_KEY_ID` | App Store Connect API key ID |
| `NOTARY_ISSUER_ID` | App Store Connect issuer ID |

Find the two identity values locally with:

```sh
security find-identity -v -p codesigning
```

For example, upload a certificate without exposing it in the shell history:

```sh
base64 < "$HOME/Desktop/Developer ID Application.p12" | tr -d '\n' | gh secret set DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64 --repo nhestrompia/edge
gh secret set DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD --repo nhestrompia/edge
```

Repeat for the `.p8` key. `gh secret set` prompts for values when no input is piped.

## Rebuild an existing release

After all secrets are configured, rebuild `v0.1.1` so its assets are replaced with signed and notarized files:

```sh
gh workflow run release.yml --repo nhestrompia/edge --ref main -f version=0.1.1
gh run watch --repo nhestrompia/edge
```

For a new release, update the version and push a tag as described in the main README.

# Secrets

Secrets are encrypted with [`age`](https://github.com/FiloSottile/age) and [`agebox`](https://github.com/slok/agebox).

> These binaries should be available in the `$PATH`.

## To encrpyt

To encrypt files:

```bash
# Use the public key
agebox encrypt -p ~/.ssh/homeserver_secrets.pub secret-file
```

After encrypting, the `secret-file` would be encrypted to `secret-file.agebox`
and `secret-file` would be removed.

> **NOTE:** Files in this repo are encrpyted using password-protected `homeserver-secrets` key file (also stored in Azure KeyVault).

## To decrypt

```bash
# Use the public key
agebox decrypt -i ~/.ssh/homeserver_secrets secret-file.agebox
```

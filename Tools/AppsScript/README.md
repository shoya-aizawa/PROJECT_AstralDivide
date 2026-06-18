# Apps Script Sync Workspace

This folder is the local workspace for the remote log monitoring Apps Script project.

## What belongs here

- `RemoteLogReceiver.gs`
- `appsscript.json`
- `.clasp.json`
- `.claspignore`

## Script ID

The Apps Script **Script ID** is **not** the deployment ID.

You can find the Script ID from either place:

1. Open the Apps Script project editor and check the URL.
   Example:
   `https://script.google.com/home/projects/<SCRIPT_ID>/edit`
2. In the Apps Script editor:
   `Project Settings` -> `IDs` -> `Script ID`

## First-time setup

If this folder is not linked yet, run these commands here:

```bash
clasp clone <SCRIPT_ID>
```

If you want to keep this folder structure instead of cloning into a fresh directory:

```bash
clasp create --type standalone --rootDir .
```

Then replace the generated files with the ones in this folder and update `.clasp.json`.

## Recommended workflow

Pull current remote code before editing:

```bash
clasp pull
```

Push local changes:

```bash
clasp push
```

Create a version after a meaningful update:

```bash
clasp version "remote log update"
```

List deployments:

```bash
clasp deployments
```

## Deployment note

For this project's web app deployment:

- Execute as: `Me`
- Who has access: choose based on your remote client usage


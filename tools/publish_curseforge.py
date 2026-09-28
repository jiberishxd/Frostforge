"""Preview validated ZIPs, or upload them for a published GitHub release.

API: https://support.curseforge.com/support/solutions/articles/9000197321
WoW version types/endpoint: BigWigsMods/packager release.sh (upload_curseforge).
No network requests occur without --upload. Tokens never enter output or URLs.
"""
import argparse
import hashlib
import http.client
import json
import os
from pathlib import Path
import re
import sys
import uuid
import zipfile

from package import CLIENTS, ROOT, VERSION

HOST = "wow.curseforge.com"
VERSION_TYPES = {"Retail": 517, "Forever": 88568}


def clients_from(value):
    clients = [v.strip() for v in value.split(",")]
    if not clients or any(c not in CLIENTS for c in clients) or len(set(clients)) != len(clients):
        raise ValueError("CF_CLIENTS must be Retail, Forever, or Retail,Forever.")
    return clients


def release_metadata(event):
    release = event.get("release")
    if release is None:
        return "beta", f"Build-only preview of Frostforge {VERSION}; nothing will be uploaded."
    if event.get("action") != "published" or release.get("draft") is not False:
        raise ValueError("Uploads require a published GitHub release.")
    if release.get("tag_name") != f"v{VERSION}":
        raise ValueError(f"Release tag must be v{VERSION}, matching the TOC and addon version.")
    if type(release.get("prerelease")) is not bool:
        raise ValueError("Release must identify whether it is a prerelease.")
    notes = release.get("body")
    if not isinstance(notes, str) or not notes.strip():
        raise ValueError("Add release notes before publishing the GitHub release.")
    return ("beta" if release["prerelease"] else "release"), notes


def package_plan(directory, clients, event):
    release_type, notes = release_metadata(event)
    reports = json.loads((directory / "packages.json").read_text())
    plans = []
    for client in clients:
        matches = [r for r in reports if r.get("client") == client]
        if len(matches) != 1:
            raise ValueError(f"Expected one validated package for {client}.")
        report = matches[0]
        filename = f"Jiberishs-Frostforge-{client}-{VERSION}.zip"
        interface, baseline, revision = CLIENTS[client]
        if (report.get("file") != filename or report.get("version") != VERSION
                or report.get("interface") != interface or report.get("baseline") != baseline
                or report.get("source_revision") != revision or report.get("addon_folder") != "Frostforge"):
            raise ValueError(f"Package metadata does not match the {client} build.")
        path = directory / filename
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest != report.get("sha256"):
            raise ValueError(f"Package checksum mismatch: {filename}")
        with zipfile.ZipFile(path) as archive:
            names = archive.namelist()
            toc = archive.read("Frostforge/Frostforge.toc").decode()
            if ({n.split("/")[0] for n in names} != {"Frostforge"}
                    or len(names) != len(set(names)) or len(names) != report.get("files")
                    or not re.search(rf"^## Interface: {interface}$", toc, re.M)
                    or not re.search(rf"^## Version: {re.escape(VERSION)}$", toc, re.M)):
                raise ValueError(f"Package contents do not match {client} {VERSION}.")
        game_version = f"{interface // 10000}.{interface // 100 % 100}.{interface % 100}"
        plans.append({"client": client, "file": filename, "sha256": digest,
                      "game_version": game_version, "metadata": {
                          "displayName": f"Frostforge {VERSION} — {client}",
                          "releaseType": release_type, "changelogType": "markdown", "changelog": notes,
                      }})
    return plans


def resolve_versions(plans, versions):
    if not isinstance(versions, list):
        raise ValueError("CurseForge did not return its WoW game-version list.")
    # Validate all selected clients before posting the first file. Never silently
    # substitute an older version or a different WoW flavor.
    for plan in plans:
        matches = [v for v in versions if isinstance(v, dict)
                   and v.get("name") == plan["game_version"]
                   and v.get("gameVersionTypeID") == VERSION_TYPES[plan["client"]]]
        if len(matches) != 1 or type(matches[0].get("id")) is not int or matches[0]["id"] <= 0:
            raise ValueError(f"No unique CurseForge version for {plan['client']} {plan['game_version']}. "
                             "Check the supported game versions before uploading.")
        plan["metadata"]["gameVersions"] = [matches[0]["id"]]


def request_json(method, path, token, body=None, content_type=None):
    # A fixed HTTPS host and no redirects keep credentials at the intended API.
    connection = http.client.HTTPSConnection(HOST, timeout=180)
    headers = {"X-Api-Token": token, "Accept": "application/json"}
    if content_type:
        headers["Content-Type"] = content_type
    try:
        connection.request(method, path, body=body, headers=headers)
        response = connection.getresponse()
        data = response.read()
        if not 200 <= response.status < 300:
            raise ValueError(f"CurseForge {method} returned HTTP {response.status}. "
                             "Check the project ID, token and dashboard. No automatic retry was made.")
        return json.loads(data)
    finally:
        connection.close()


def multipart(plan, directory):
    boundary = "frostforge-" + uuid.uuid4().hex
    start = (f"--{boundary}\r\nContent-Disposition: form-data; name=\"metadata\"\r\n"
             "Content-Type: application/json\r\n\r\n").encode()
    middle = (f"\r\n--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; "
              f"filename=\"{plan['file']}\"\r\nContent-Type: application/zip\r\n\r\n").encode()
    data = (directory / plan["file"]).read_bytes()
    if hashlib.sha256(data).hexdigest() != plan["sha256"]:
        raise ValueError("Package changed after validation; upload stopped.")
    body = start + json.dumps(plan["metadata"]).encode() + middle + data + f"\r\n--{boundary}--\r\n".encode()
    return body, f"multipart/form-data; boundary={boundary}"


def publish(plans, directory, project_id, token, request=request_json):
    if not re.fullmatch(r"[1-9][0-9]*", project_id):
        raise ValueError("Set the numeric CF_PROJECT_ID repository variable first.")
    if not token or any(c in token for c in "\r\n"):
        raise ValueError("Set the private CF_API_TOKEN repository secret first.")
    versions = request("GET", "/api/game/wow/versions", token)
    resolve_versions(plans, versions)
    receipts = []
    for plan in plans:
        body, content_type = multipart(plan, directory)
        # POST is deliberately not retried: a timeout may follow a successful
        # upload. Keep each confirmed ID even if a later client upload fails.
        result = request("POST", f"/api/projects/{project_id}/upload-file", token, body, content_type)
        if not isinstance(result, dict) or type(result.get("id")) is not int or result["id"] <= 0:
            raise ValueError("Upload returned no file ID. Check CurseForge before retrying.")
        receipt = {"client": plan["client"], "file": plan["file"], "sha256": plan["sha256"],
                   "project_id": int(project_id), "file_id": result["id"]}
        receipts.append(receipt)
        (directory / "curseforge-uploads.json").write_text(json.dumps(receipts, indent=2) + "\n")
        print(f"Uploaded {plan['file']}: CurseForge file {result['id']} (subject to moderation).")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--upload", action="store_true")
    parser.add_argument("--dist", type=Path, default=ROOT / "dist")
    args = parser.parse_args(argv)
    event_path = os.environ.get("GITHUB_EVENT_PATH")
    event = json.loads(Path(event_path).read_text()) if event_path else {}
    if args.upload and (os.environ.get("GITHUB_EVENT_NAME") != "release" or "release" not in event):
        raise ValueError("Only the published-release workflow may upload; manual runs build only.")
    client_setting = os.environ.get("CF_CLIENTS", "")
    if args.upload and not client_setting:
        raise ValueError("Set CF_CLIENTS to Retail, Forever, or Retail,Forever before publishing.")
    plans = package_plan(args.dist, clients_from(client_setting or "Retail,Forever"), event)
    print(json.dumps({"mode": "upload" if args.upload else "preview", "packages": [
        {"file": p["file"], "client": p["client"], "game_version": p["game_version"],
         "release_type": p["metadata"]["releaseType"]} for p in plans]}, indent=2))
    if args.upload:
        publish(plans, args.dist, os.environ.get("CF_PROJECT_ID", ""), os.environ.get("CF_API_TOKEN", ""))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, http.client.HTTPException, zipfile.BadZipFile, KeyError) as error:
        # Do not echo remote bodies or environment values that may contain tokens.
        message = str(error) if isinstance(error, ValueError) and not isinstance(error, json.JSONDecodeError) else type(error).__name__
        print(f"Publishing stopped: {message}\nIf an upload started, check the CurseForge file list before retrying.", file=sys.stderr)
        sys.exit(1)

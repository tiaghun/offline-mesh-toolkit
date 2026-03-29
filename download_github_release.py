#!/usr/bin/env python3
"""
Download GitHub Release Assets
-------------------------------
Helper script to download firmware files from GitHub releases.
Works offline once files are cached locally.

Usage:
    python download_github_release.py <owner/repo> [--tag <tag>] [--pattern <glob>] [--output <dir>]

Examples:
    python download_github_release.py meshtastic/firmware --tag v2.5.6.0 --output meshtastic-firmware
    python download_github_release.py rocketgod-git/meshcore-firmware --output meshcore-firmware
    python download_github_release.py meshtastic/firmware --pattern "*.uf2" --output meshtastic-firmware
"""

import argparse
import json
import os
import sys
import time
import urllib.request
import urllib.error
import fnmatch


GITHUB_API = "https://api.github.com"


def get_headers():
    """Build request headers, including GitHub token if available."""
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "offline-mesh-toolkit/1.0",
    }
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def api_request(url):
    """Make a GitHub API request and return parsed JSON."""
    req = urllib.request.Request(url, headers=get_headers())
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        if e.code == 403:
            print(f"ERROR: Rate limited by GitHub API. Set GITHUB_TOKEN env var to increase limits.")
            print(f"  Create a token at: https://github.com/settings/tokens")
        elif e.code == 404:
            print(f"ERROR: Not found: {url}")
        else:
            print(f"ERROR: HTTP {e.code} from {url}")
        sys.exit(1)


def get_latest_release(repo):
    """Get the latest release for a repo."""
    url = f"{GITHUB_API}/repos/{repo}/releases/latest"
    return api_request(url)


def get_release_by_tag(repo, tag):
    """Get a specific release by tag."""
    url = f"{GITHUB_API}/repos/{repo}/releases/tags/{tag}"
    return api_request(url)


def list_releases(repo, limit=10):
    """List recent releases for a repo."""
    url = f"{GITHUB_API}/repos/{repo}/releases?per_page={limit}"
    return api_request(url)


def download_file(url, dest_path, filename=None):
    """Download a file with progress indication."""
    if filename is None:
        filename = os.path.basename(dest_path)

    if os.path.exists(dest_path):
        print(f"  SKIP (exists): {filename}")
        return True

    print(f"  Downloading: {filename} ... ", end="", flush=True)
    headers = get_headers()
    headers["Accept"] = "application/octet-stream"
    req = urllib.request.Request(url, headers=headers)

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            total = int(resp.headers.get("Content-Length", 0))
            downloaded = 0
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            with open(dest_path, "wb") as f:
                while True:
                    chunk = resp.read(65536)
                    if not chunk:
                        break
                    f.write(chunk)
                    downloaded += len(chunk)
            size_mb = downloaded / (1024 * 1024)
            print(f"OK ({size_mb:.1f} MB)")
            return True
    except Exception as e:
        print(f"FAILED: {e}")
        if os.path.exists(dest_path):
            os.remove(dest_path)
        return False


def download_release_assets(repo, tag=None, pattern=None, output_dir=".", list_only=False):
    """Download assets from a GitHub release."""
    # Get release info
    if tag:
        print(f"Fetching release {tag} from {repo}...")
        release = get_release_by_tag(repo, tag)
    else:
        print(f"Fetching latest release from {repo}...")
        release = get_latest_release(repo)

    tag_name = release["tag_name"]
    print(f"Release: {tag_name} ({release['name']})")
    print(f"Published: {release['published_at']}")

    assets = release.get("assets", [])
    if not assets:
        print("WARNING: No assets found in this release.")
        return []

    # Filter by pattern if specified
    if pattern:
        assets = [a for a in assets if fnmatch.fnmatch(a["name"], pattern)]

    if list_only:
        print(f"\nAssets ({len(assets)}):")
        for a in assets:
            size_mb = a["size"] / (1024 * 1024)
            print(f"  {a['name']} ({size_mb:.1f} MB)")
        return assets

    # Download
    print(f"\nDownloading {len(assets)} assets to {output_dir}/")
    os.makedirs(output_dir, exist_ok=True)

    downloaded = []
    failed = []
    for asset in assets:
        dest = os.path.join(output_dir, asset["name"])
        if download_file(asset["browser_download_url"], dest, asset["name"]):
            downloaded.append(asset["name"])
        else:
            failed.append(asset["name"])
        time.sleep(0.2)  # Be nice to GitHub

    print(f"\nDone: {len(downloaded)} downloaded, {len(failed)} failed")
    if failed:
        print("Failed files:")
        for f in failed:
            print(f"  - {f}")

    # Save release metadata
    meta_path = os.path.join(output_dir, "_release_info.json")
    meta = {
        "repo": repo,
        "tag": tag_name,
        "name": release["name"],
        "published_at": release["published_at"],
        "downloaded_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "assets": [a["name"] for a in assets],
    }
    with open(meta_path, "w") as f:
        json.dump(meta, f, indent=2)

    return downloaded


def main():
    parser = argparse.ArgumentParser(description="Download GitHub release assets")
    parser.add_argument("repo", help="GitHub repo (owner/repo)")
    parser.add_argument("--tag", "-t", help="Release tag (default: latest)")
    parser.add_argument("--pattern", "-p", help="Filename glob pattern filter")
    parser.add_argument("--output", "-o", default=".", help="Output directory")
    parser.add_argument("--list", "-l", action="store_true", help="List assets only, don't download")
    parser.add_argument("--list-releases", action="store_true", help="List recent releases")
    args = parser.parse_args()

    if args.list_releases:
        releases = list_releases(args.repo)
        print(f"Recent releases for {args.repo}:")
        for r in releases:
            asset_count = len(r.get("assets", []))
            print(f"  {r['tag_name']:20s}  {r['published_at'][:10]}  ({asset_count} assets)  {r['name']}")
        return

    download_release_assets(
        repo=args.repo,
        tag=args.tag,
        pattern=args.pattern,
        output_dir=args.output,
        list_only=args.list,
    )


if __name__ == "__main__":
    main()

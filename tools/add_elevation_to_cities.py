"""Add elevation data to cities.json using Open Elevation API.

Reads existing cities.json, sends batch requests to the Open Elevation API
(https://api.open-elevation.com/api/v1/lookup) to get elevation for each city
based on its lat/lng coordinates, and writes back the updated JSON.

The API supports batch POST requests with multiple coordinates.
For reliability, we send batches of 100 coordinates at a time with retry logic.

Usage:
    python tools/add_elevation_to_cities.py

Ref: Plan feature-elevation-correction-1.md, TASK-001
"""
import json
import os
import time
import urllib.request
import urllib.error

# Open Elevation API endpoint
API_URL = "https://api.open-elevation.com/api/v1/lookup"

# Batch size (API supports up to ~200 per request, we use 100 for safety)
BATCH_SIZE = 100

# Retry settings
MAX_RETRIES = 3
RETRY_DELAY_SECONDS = 5


def fetch_elevations(locations: list[dict]) -> list[int]:
    """Fetch elevation data for a batch of locations from Open Elevation API.

    Args:
        locations: List of dicts with 'latitude' and 'longitude' keys.

    Returns:
        List of elevation values (int, meters) in the same order as input.

    Raises:
        Exception: If API request fails after all retries.
    """
    payload = json.dumps({
        "locations": [
            {"latitude": loc["latitude"], "longitude": loc["longitude"]}
            for loc in locations
        ]
    }).encode("utf-8")

    req = urllib.request.Request(
        API_URL,
        data=payload,
        headers={"Content-Type": "application/json", "Accept": "application/json"},
    )

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                return [
                    max(0, int(round(r["elevation"])))  # Clamp to >= 0
                    for r in data["results"]
                ]
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as e:
            print(f"  Attempt {attempt}/{MAX_RETRIES} failed: {e}")
            if attempt < MAX_RETRIES:
                print(f"  Retrying in {RETRY_DELAY_SECONDS}s...")
                time.sleep(RETRY_DELAY_SECONDS)
            else:
                raise Exception(
                    f"Failed to fetch elevations after {MAX_RETRIES} attempts"
                ) from e

    return []  # unreachable


def main():
    # Resolve paths
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    cities_path = os.path.join(project_root, "assets", "data", "cities.json")

    # Load existing cities
    print(f"Loading cities from {cities_path}...")
    with open(cities_path, "r", encoding="utf-8") as f:
        cities = json.load(f)
    print(f"  -> {len(cities)} cities loaded")

    # Check if elevation already exists
    has_elevation = all("elevation" in c for c in cities)
    if has_elevation:
        print("  -> All cities already have elevation data. Skipping API calls.")
        print("  -> To re-fetch, remove 'elevation' keys from cities.json first.")
        return

    # Process in batches
    total = len(cities)
    elevations = []

    for i in range(0, total, BATCH_SIZE):
        batch = cities[i : i + BATCH_SIZE]
        batch_num = (i // BATCH_SIZE) + 1
        total_batches = (total + BATCH_SIZE - 1) // BATCH_SIZE
        print(f"Fetching batch {batch_num}/{total_batches} ({len(batch)} cities)...")

        batch_elevations = fetch_elevations(batch)
        elevations.extend(batch_elevations)

        # Be polite to free API
        if i + BATCH_SIZE < total:
            time.sleep(1)

    # Apply elevations to cities
    assert len(elevations) == len(cities), (
        f"Elevation count mismatch: {len(elevations)} vs {len(cities)}"
    )

    for city, elev in zip(cities, elevations):
        city["elevation"] = elev

    # Write updated cities.json
    with open(cities_path, "w", encoding="utf-8") as f:
        json.dump(cities, f, indent=2, ensure_ascii=False)

    print(f"\nUpdated {len(cities)} cities -> {cities_path}")
    print(f"File size: {os.path.getsize(cities_path) / 1024:.1f} KB")

    # Spot-check known cities
    print("\n=== SPOT CHECK ===")
    spot_checks = {
        "Kota Bandung": 768,
        "Kota Jakarta Pusat": 8,
        "Kota Semarang": 2,
        "Kota Malang": 476,
        "Kota Surabaya": 5,
        "Kota Bogor": 265,
    }

    for city in cities:
        name = city["city_name"]
        if name in spot_checks:
            expected = spot_checks[name]
            actual = city["elevation"]
            delta = abs(actual - expected)
            status = "✓" if delta <= 100 else "⚠"
            print(f"  {status} {name}: {actual}m (expected ~{expected}m, delta={delta}m)")

    print("\nDone!")


if __name__ == "__main__":
    main()

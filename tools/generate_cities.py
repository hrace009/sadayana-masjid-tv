"""Generate cities.json from GitHub dataset.

Downloads provinces and regencies from yusufsyaifudin/wilayah-indonesia,
maps province_id to province_name, normalizes city names to Title Case,
and outputs the final cities.json for the Sadayana Masjid Display app.
"""
import json
import os
import urllib.request

BASE_URL = "https://raw.githubusercontent.com/yusufsyaifudin/wilayah-indonesia/master/data/list_of_area"

def title_case_city(name: str) -> str:
    """Convert 'KABUPATEN ACEH BARAT' to 'Kabupaten Aceh Barat'."""
    words = name.strip().split()
    result = []
    for word in words:
        if word.upper() == "DKI":
            result.append("DKI")
        elif word.upper() == "DI":
            result.append("DI")
        else:
            result.append(word.capitalize())
    return " ".join(result)

def main():
    # Download provinces
    print("Downloading provinces...")
    provinces_raw = urllib.request.urlopen(f"{BASE_URL}/provinces.json").read()
    provinces_list = json.loads(provinces_raw)
    province_map = {p["id"]: title_case_city(p["name"]) for p in provinces_list}
    print(f"  -> {len(province_map)} provinces")

    # Download regencies (kota/kabupaten)
    print("Downloading regencies...")
    regencies_raw = urllib.request.urlopen(f"{BASE_URL}/regencies.json").read()
    regencies_list = json.loads(regencies_raw)
    print(f"  -> {len(regencies_list)} regencies")

    # Transform to our format
    cities = []
    for r in regencies_list:
        province_name = province_map.get(r["province_id"], f"Unknown ({r['province_id']})")
        cities.append({
            "province_name": province_name,
            "city_name": title_case_city(r["name"]),
            "latitude": r["latitude"],
            "longitude": r["longitude"],
        })

    # Sort by province_name, then city_name
    cities.sort(key=lambda c: (c["province_name"], c["city_name"]))

    # Write output
    out_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "data")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "cities.json")

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(cities, f, indent=2, ensure_ascii=False)

    print(f"\nGenerated {len(cities)} cities -> {out_path}")
    print(f"File size: {os.path.getsize(out_path) / 1024:.1f} KB")

    # Validate
    provinces_in_data = set(c["province_name"] for c in cities)
    print(f"Provinces covered: {len(provinces_in_data)}")
    assert len(cities) >= 500, f"Expected >= 500 cities, got {len(cities)}"
    print("Validation passed!")

if __name__ == "__main__":
    main()

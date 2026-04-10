#!/usr/bin/env python3

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CATALOG_JSON = ROOT / "assets" / "data" / "catalog.json"
OUTPUT_JSON = ROOT / "assets" / "data" / "catalog_manifest.json"
APP_IMAGES = ROOT / "lib" / "core" / "constants" / "app_images.dart"
HOME_DATA = ROOT / "lib" / "features" / "home" / "home_data.dart"
RESTAURANT_DATA = ROOT / "lib" / "features" / "restaurant" / "restaurant_data.dart"
MARKET_DATA = ROOT / "lib" / "features" / "marketplace" / "market_store_screen.dart"


def _parse_images(text: str) -> dict[str, str]:
    values: dict[str, str] = {}
    aliases: list[tuple[str, str]] = []
    class_pattern = re.compile(r"class\s+(\w+)\s*\{(.*?)\n\}", re.S)

    for class_name, class_body in class_pattern.findall(text):
        for name, url in re.findall(
            r"static const String (\w+)\s*=\s*'([^']+)';",
            class_body,
            re.S,
        ):
            values[f"{class_name}.{name}"] = url

        for name, source in re.findall(
            r"static const String (\w+)\s*=\s*(\w+);",
            class_body,
            re.S,
        ):
            aliases.append((f"{class_name}.{name}", f"{class_name}.{source}"))

    changed = True
    while changed:
        changed = False
        for target, source in aliases:
            if target not in values and source in values:
                values[target] = values[source]
                changed = True
    return values


def _slugify(value: str) -> str:
    replacements = {
        "ç": "c",
        "ğ": "g",
        "ı": "i",
        "İ": "i",
        "ö": "o",
        "ş": "s",
        "ü": "u",
        "â": "a",
        "ê": "e",
        "î": "i",
        "ô": "o",
        "û": "u",
        "&": "ve",
    }
    for old, new in replacements.items():
        value = value.replace(old, new).replace(old.upper(), new.upper())
    normalized = re.sub(r"[^a-zA-Z0-9]+", "-", value.lower()).strip("-")
    return re.sub(r"-{2,}", "-", normalized)


def _parse_price(price_text: str) -> float:
    normalized = (
        price_text.replace("TL", "")
        .replace("₺", "")
        .replace(".", "")
        .replace(",", ".")
        .strip()
    )
    return float(normalized)


def _extract_string_field(block: str, name: str) -> str:
    match = re.search(rf"""{name}:\s*(?P<q>'|")(.*?)(?P=q),""", block, re.S)
    return match.group(2).replace("\n", " ").strip() if match else ""


def _extract_identifier_field(block: str, name: str) -> str:
    match = re.search(rf"{name}:\s*([^,\n]+),", block, re.S)
    return match.group(1).strip() if match else ""


def _build_home_manifest(home_text: str, image_map: dict[str, str]) -> dict[str, object]:
    hero_pattern = re.compile(
        r"""HomeHeroData\(
        \s*title:\s*(?P<q1>'|")(.*?)(?P=q1),
        \s*subtitle:\s*(?P<q2>'|")(.*?)(?P=q2),
        \s*badge:\s*(?P<q3>'|")(.*?)(?P=q3),
        \s*image:\s*([^,]+),
        \s*actionLabel:\s*(?P<q4>'|")(.*?)(?P=q4),
        \s*screen:\s*SpetoScreen\.([a-zA-Z0-9_]+),
        """,
        re.S | re.X,
    )
    quick_pattern = re.compile(
        r"""HomeQuickFilter\(
        \s*label:\s*'([^']*)',
        \s*icon:\s*Icons\.([a-zA-Z0-9_]+),
        \s*screen:\s*SpetoScreen\.([a-zA-Z0-9_]+),
        (?:\s*highlight:\s*(true|false),)?
        """,
        re.S | re.X,
    )

    heroes = []
    for display_order, match in enumerate(hero_pattern.finditer(home_text), start=1):
        image_key = match.group(7).strip()
        heroes.append(
            {
                "id": f"hero-{display_order}",
                "title": match.group(2),
                "subtitle": match.group(4),
                "badge": match.group(6),
                "image": image_map.get(image_key, image_key),
                "actionLabel": match.group(9),
                "screen": match.group(10),
                "displayOrder": display_order,
            }
        )

    quick_filters = []
    for display_order, (label, icon, screen, highlight) in enumerate(
        quick_pattern.findall(home_text),
        start=1,
    ):
        quick_filters.append(
            {
                "id": f"quick-filter-{display_order}",
                "label": label,
                "icon": icon,
                "screen": screen,
                "highlight": highlight == "true",
                "displayOrder": display_order,
            }
        )

    filter_block = re.search(
        r"const List<String> filterChips = <String>\[(.*?)\];",
        home_text,
        re.S,
    )
    discovery_filters = []
    for display_order, label in enumerate(re.findall(r"'([^']+)'", filter_block.group(1)), start=1):
        discovery_filters.append(
            {
                "id": f"discovery-filter-{display_order}",
                "label": label,
                "displayOrder": display_order,
            }
        )

    return {
        "heroes": heroes,
        "quickFilters": quick_filters,
        "discoveryFilters": discovery_filters,
    }


def _build_restaurant_sections(
    restaurant_text: str,
    image_map: dict[str, str],
) -> dict[str, list[dict[str, object]]]:
    section_pattern = re.compile(r"'([^']+)': <MenuListItem>\[(.*?)\],", re.S)
    item_pattern = re.compile(
        r"MenuListItem\(\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*([^,\)]+),\s*\)",
        re.S,
    )
    case_pattern = re.compile(
        r"case '([^']+)':\s*return const <String, List<MenuListItem>>\{(.*?)\n\s*\};",
        re.S,
    )

    def parse_sections(body: str, storefront_id: str) -> list[dict[str, object]]:
        sections = []
        seen_product_ids: set[str] = set()
        for section_order, (label, items_body) in enumerate(section_pattern.findall(body), start=1):
            products = []
            for product_order, (title, description, price_text, image_key) in enumerate(
                item_pattern.findall(items_body),
                start=1,
            ):
                base_id = f"product-{storefront_id}-{_slugify(title)}"
                product_id = base_id
                suffix = 2
                while product_id in seen_product_ids:
                    product_id = f"{base_id}-{suffix}"
                    suffix += 1
                seen_product_ids.add(product_id)
                products.append(
                    {
                        "id": product_id,
                        "title": title,
                        "description": description,
                        "priceText": price_text,
                        "unitPrice": _parse_price(price_text),
                        "image": image_map.get(image_key.strip(), image_key.strip()),
                        "displayOrder": product_order,
                    }
                )
            sections.append(
                {
                    "id": f"section-{storefront_id}-{_slugify(label)}",
                    "key": _slugify(label),
                    "label": label,
                    "displayOrder": section_order,
                    "products": products,
                }
            )
        return sections

    sections_by_storefront = {
        storefront_id: parse_sections(body, storefront_id)
        for storefront_id, body in case_pattern.findall(restaurant_text)
    }

    default_match = re.search(
        r"default:\s*return const <String, List<MenuListItem>>\{(.*?)\n\s*\};",
        restaurant_text,
        re.S,
    )
    sections_by_storefront["restaurant-burger-yiyelim"] = parse_sections(
        default_match.group(1),
        "restaurant-burger-yiyelim",
    )
    return sections_by_storefront


def _build_market_manifest(
    market_text: str,
    image_map: dict[str, str],
) -> list[dict[str, object]]:
    catalog_match = re.search(
        r"final Map<String, MenuListItem> _marketProductCatalog = <String, MenuListItem>\{(.*?)\n\};\n\nList<MenuListItem> marketProducts",
        market_text,
        re.S,
    )
    catalog_pattern = re.compile(
        r"'([^']+)': MenuListItem\(\s*'([^']+)',\s*(_marketExpiry\('([^']+)'\)|'([^']+)'),\s*'([^']+)',\s*([^,\)]+),\s*\),",
        re.S,
    )

    market_catalog: dict[str, dict[str, object]] = {}
    for key, title, _, expiry_date, description, price_text, image_key in catalog_pattern.findall(
        catalog_match.group(1)
    ):
        market_catalog[key] = {
            "title": title,
            "description": f"Son Tüketim Tarihi: {expiry_date}" if expiry_date else description,
            "priceText": price_text,
            "unitPrice": _parse_price(price_text),
            "image": image_map.get(image_key.strip(), image_key.strip()),
        }

    store_blocks = re.findall(r"MarketStoreData\((.*?)\n  \),", market_text, re.S)
    stores = []
    for display_order, block in enumerate(store_blocks, start=1):
        storefront_id = _extract_string_field(block, "id")
        sections = []
        for section_order, (label, titles_block) in enumerate(
            re.findall(r"'([^']+)': marketProducts\(<String>\[(.*?)\]\)", block, re.S),
            start=1,
        ):
            section_id = f"section-{storefront_id}-{_slugify(label)}"
            titles = re.findall(r"'([^']+)'", titles_block)
            products = []
            for product_order, title in enumerate(titles, start=1):
                product = market_catalog[title]
                products.append(
                    {
                        "id": f"market-product-{storefront_id}-{_slugify(title)}",
                        "title": product["title"],
                        "description": product["description"],
                        "priceText": product["priceText"],
                        "unitPrice": product["unitPrice"],
                        "image": product["image"],
                        "displayOrder": product_order,
                    }
                )
            sections.append(
                {
                    "id": section_id,
                    "key": _slugify(label),
                    "label": label,
                    "displayOrder": section_order,
                    "products": products,
                }
            )

        highlights = []
        for highlight_order, (label, icon) in enumerate(
            re.findall(r"StoreHighlightData\('([^']+)', Icons\.([a-zA-Z0-9_]+)\)", block),
            start=1,
        ):
            highlights.append(
                {
                    "id": f"highlight-{storefront_id}-{highlight_order}",
                    "label": label,
                    "icon": icon,
                    "displayOrder": highlight_order,
                }
            )

        stores.append(
            {
                "id": storefront_id,
                "vendorId": f"vendor-{storefront_id}",
                "title": _extract_string_field(block, "title"),
                "subtitle": _extract_string_field(block, "subtitle"),
                "meta": _extract_string_field(block, "meta"),
                "image": image_map.get(
                    _extract_identifier_field(block, "image"),
                    _extract_identifier_field(block, "image"),
                ),
                "badge": _extract_string_field(block, "badge"),
                "rewardLabel": _extract_string_field(block, "rewardLabel"),
                "ratingLabel": _extract_string_field(block, "ratingLabel"),
                "distanceLabel": _extract_string_field(block, "distanceLabel"),
                "etaLabel": _extract_string_field(block, "etaLabel"),
                "promoLabel": _extract_string_field(block, "promoLabel"),
                "workingHoursLabel": _extract_string_field(block, "workingHoursLabel"),
                "minOrderLabel": _extract_string_field(block, "minOrderLabel"),
                "deliveryWindowLabel": _extract_string_field(block, "deliveryWindowLabel"),
                "reviewCountLabel": _extract_string_field(block, "reviewCountLabel"),
                "announcement": _extract_string_field(block, "announcement"),
                "bundleTitle": _extract_string_field(block, "bundleTitle"),
                "bundleDescription": _extract_string_field(block, "bundleDescription"),
                "bundlePrice": _extract_string_field(block, "bundlePrice"),
                "heroTitle": _extract_string_field(block, "heroTitle"),
                "heroSubtitle": _extract_string_field(block, "heroSubtitle"),
                "displayOrder": display_order,
                "highlights": highlights,
                "sections": sections,
            }
        )
    return stores


def _build_manifest() -> dict[str, object]:
    image_map = _parse_images(APP_IMAGES.read_text())
    base_catalog = json.loads(CATALOG_JSON.read_text())
    restaurants = base_catalog["restaurants"]
    events = base_catalog["events"]
    restaurant_sections = _build_restaurant_sections(RESTAURANT_DATA.read_text(), image_map)

    normalized_restaurants = []
    for display_order, restaurant in enumerate(restaurants, start=1):
        storefront_id = restaurant["id"]
        normalized_restaurants.append(
            {
                "id": storefront_id,
                "vendorId": f"vendor-{storefront_id.replace('restaurant-', '')}",
                "title": restaurant["title"],
                "image": restaurant["image"],
                "cuisine": restaurant["cuisine"],
                "etaMin": restaurant["etaMin"],
                "etaMax": restaurant["etaMax"],
                "ratingValue": restaurant["ratingValue"],
                "promo": restaurant["promo"],
                "studentFriendly": restaurant["studentFriendly"],
                "displayOrder": display_order,
                "sections": restaurant_sections.get(storefront_id, []),
            }
        )

    normalized_events = []
    for display_order, event in enumerate(events, start=1):
        normalized_events.append({**event, "displayOrder": display_order})

    return {
        "contentVersion": "2026-04-09",
        "home": _build_home_manifest(HOME_DATA.read_text(), image_map),
        "restaurants": normalized_restaurants,
        "markets": _build_market_manifest(MARKET_DATA.read_text(), image_map),
        "events": normalized_events,
    }


def main() -> None:
    manifest = _build_manifest()
    OUTPUT_JSON.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    )
    print(f"Wrote {OUTPUT_JSON.relative_to(ROOT)}")


if __name__ == "__main__":
    main()

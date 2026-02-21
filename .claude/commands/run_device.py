#!/usr/bin/env python3
"""
Szybka Fucha - Flutter Device Runner
Automatycznie czyści build i uruchamia aplikację na fizycznym telefonie.
Użycie: python3 run_device.py [--server-url URL] [--device DEVICE_ID]
"""

import subprocess
import sys
import argparse
import os

FLUTTER = "/usr/local/share/flutter/bin/flutter"
MOBILE_DIR = os.path.join(os.path.dirname(__file__), "mobile")
DEFAULT_SERVER_URL = "http://192.168.1.104:3000"


def run(cmd, cwd=None, check=True):
    print(f"\n→ {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=cwd or MOBILE_DIR, check=check)
    return result.returncode


def list_devices():
    print("\nDostępne urządzenia:")
    subprocess.run([FLUTTER, "devices"], cwd=MOBILE_DIR)


def get_devices():
    result = subprocess.run(
        [FLUTTER, "devices", "--machine"],
        cwd=MOBILE_DIR,
        capture_output=True,
        text=True
    )
    import json
    try:
        devices = json.loads(result.stdout)
        return [d for d in devices if not d.get("emulator", True)]
    except Exception:
        return []


def clean_xcode_derived_data():
    derived = os.path.expanduser("~/Library/Developer/Xcode/DerivedData")
    runner_dirs = []
    if os.path.exists(derived):
        for d in os.listdir(derived):
            if d.startswith("Runner-"):
                runner_dirs.append(os.path.join(derived, d))

    if runner_dirs:
        print(f"\n→ Czyszczenie Xcode DerivedData ({len(runner_dirs)} folder/y)...")
        for d in runner_dirs:
            subprocess.run(["rm", "-rf", d], check=False)
        print("  DerivedData wyczyszczone.")
    else:
        print("\n  Brak Runner-* folderów w DerivedData (pomijam).")


def main():
    parser = argparse.ArgumentParser(description="Szybka Fucha - Flutter Device Runner")
    parser.add_argument("--server-url", default=DEFAULT_SERVER_URL,
                        help=f"URL serwera backendowego (domyślnie: {DEFAULT_SERVER_URL})")
    parser.add_argument("--device", default=None,
                        help="ID urządzenia (domyślnie: pierwszy fizyczny iPhone)")
    parser.add_argument("--no-clean", action="store_true",
                        help="Pomiń flutter clean (szybszy restart)")
    parser.add_argument("--list", action="store_true",
                        help="Wylistuj dostępne urządzenia i wyjdź")
    args = parser.parse_args()

    if args.list:
        list_devices()
        return

    print("=" * 55)
    print("  Szybka Fucha - Flutter Device Runner")
    print("=" * 55)
    print(f"  Server URL : {args.server_url}")

    # Wybór urządzenia
    device_id = args.device
    if not device_id:
        devices = get_devices()
        if not devices:
            print("\nNie znaleziono fizycznych urządzeń. Podłącz iPhone i odblokuj.")
            list_devices()
            sys.exit(1)
        device_id = devices[0]["id"]
        device_name = devices[0].get("name", device_id)
        print(f"  Urządzenie : {device_name} ({device_id})")
    else:
        print(f"  Urządzenie : {device_id}")

    print("=" * 55)

    # Krok 1: Wyczyść build
    if not args.no_clean:
        print("\n[1/4] Czyszczenie Flutter build...")
        run([FLUTTER, "clean"])

        print("\n[2/4] Czyszczenie Xcode DerivedData...")
        clean_xcode_derived_data()

        print("\n[3/4] Pobieranie zależności...")
        run([FLUTTER, "pub", "get"])
    else:
        print("\n[--no-clean] Pomijam czyszczenie, tylko pub get...")
        run([FLUTTER, "pub", "get"])

    # Krok 4: Uruchomienie na urządzeniu
    print(f"\n[4/4] Uruchamianie na urządzeniu...")
    exit_code = run([
        FLUTTER, "run",
        "-d", device_id,
        f"--dart-define=DEV_SERVER_URL={args.server_url}",
    ], check=False)

    if exit_code != 0:
        print("\nUruchomienie zakończone błędem. Sprawdź:")
        print("  1. Czy iPhone jest odblokowany i zaufany (Trust this computer)")
        print("  2. Czy masz ważny provisioning profile w Xcode")
        print("  3. Spróbuj otworzyć mobile/ios/Runner.xcworkspace w Xcode i uruchomić stamtąd")
        sys.exit(exit_code)


if __name__ == "__main__":
    main()

"""check_language_files.py"""

import os
import glob
import argparse


def read_properties(file_path):
    with open(file_path, "r", encoding="utf-8") as file:
        return file.read().splitlines()


def check_defference(reference_file, directory):
    reference_list = read_properties(reference_file)
    isDiff = False

    for file_path in glob.glob(os.path.join(directory, "messages_*.properties")):
        if file_path == reference_file or file_path.endswith("GB.properties"):
            continue
        current_list = read_properties(file_path)
        reference_list_len = len(reference_list)
        current_list_len = len(current_list)

        if reference_list_len != current_list_len:
            print(f"Differenz in der Datei: {os.path.basename(file_path)}")
            isDiff = True
        if reference_list_len > current_list_len:
            print(
                f"Es fehlen Zeilen! Entweder fehlen Kommentare, leere Zeilen oder Übersetzungstrings! {reference_list_len}:{current_list_len}"
            )
        elif reference_list_len < current_list_len:
            print("Es gibt zuviele Zeilen! Überprüfen sie deine Übersetzungs Dateien!")
    if isDiff:
        print("Check fail")
        exit(1)
    print("Check success")


if __name__ == "__main__":
    directory = os.getcwd() + "/src/main/resources"
    parser = argparse.ArgumentParser(description="Find missing Keys")
    parser.add_argument(
        "--reference-file",
        default=os.path.join(directory, "messages_en_GB.properties"),
        help="Pfad zur Referenzdatei aus dem main-Branch.",
    )
    args = parser.parse_args()

    check_defference(args.reference_file, directory)

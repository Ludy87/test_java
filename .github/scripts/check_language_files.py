import os
import argparse


def read_properties(file_path):
    with open(file_path, "r", encoding="utf-8") as file:
        return file.read().splitlines()


def check_difference(reference_file, file_list, branch):
    report = []
    report.append(
        f"Prüfung mit der Datei: {reference_file} - Überprüft wird der Branch: {branch}"
    )
    reference_list = read_properties(reference_file)
    is_diff = False

    for file_path in file_list:
        basename_current_file = os.path.basename(branch + "/" + file_path)
        if (
            branch + "/" + file_path == reference_file
            or not file_path.endswith(".properties")
            or not basename_current_file.startswith("messages_")
        ):
            report.append(f"Datei '{basename_current_file}' wird ignoriert.")
            continue

        report.append(f"Überprüfung der Sprachdatei '{basename_current_file}'...")
        current_list = read_properties(branch + "/" + file_path)
        reference_list_len = len(reference_list)
        current_list_len = len(current_list)

        if reference_list_len != current_list_len:
            report.append(
                f"{basename_current_file} - Test 1 nicht bestanden! Differenz in der Datei!"
            )
            is_diff = True
            if reference_list_len > current_list_len:
                report.append(
                    f"Es fehlen Zeilen! Entweder fehlen Kommentare, leere Zeilen oder Übersetzungstrings! {reference_list_len}:{current_list_len}"
                )
            elif reference_list_len < current_list_len:
                report.append(
                    f"Es gibt zuviele Zeilen! Überprüfen sie deine Übersetzungs Dateien! {reference_list_len}:{current_list_len}"
                )
        else:
            report.append("Test 1 bestanden")
            current_keys = []
            reference_keys = []
            for item in current_list:
                if not item.startswith("#") and item != "" and "=" in item:
                    key, _ = item.split("=", 1)
                    current_keys.append(key)
            for item in reference_list:
                if not item.startswith("#") and item != "" and "=" in item:
                    key, _ = item.split("=", 1)
                    reference_keys.append(key)
            current_set = set(current_keys)
            reference_set = set(reference_keys)
            set_test1 = current_set.difference(reference_set)
            set_test2 = reference_set.difference(current_set)
            set_test1_list = list(set_test1)
            set_test2_list = list(set_test2)
            if len(set_test1_list) > 0:
                is_diff = True
                report.append(f"{basename_current_file} - Test 2 nicht bestanden")
                report.append(
                    f"Es gibt keys in {basename_current_file} {set_test1_list} die in {reference_file} nicht vorhanden sind!"
                )
                report.append(
                    f"Es gibt keys in {reference_file} {set_test2_list} die in {basename_current_file} nicht vorhanden sind!"
                )
            else:
                report.append("Test 2 bestanden")

    if is_diff:
        report.append("Check fail")
        print("\n".join(report))
        # exit(1)
    else:
        print("Check success")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Find missing Keys")
    parser.add_argument(
        "--reference-file",
        required=True,
        help="Pfad zur Referenzdatei.",
    )
    parser.add_argument(
        "--branch",
        type=str,
        required=True,
        help="Branch Name.",
    )
    parser.add_argument(
        "--files",
        nargs="+",
        required=True,
        help="Liste der geänderten Dateien, durch Leerzeichen getrennt.",
    )
    args = parser.parse_args()

    file_list = args.files
    check_difference(args.reference_file, file_list, args.branch)

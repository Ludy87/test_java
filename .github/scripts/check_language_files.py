import glob
import os
import argparse
import re


def parse_properties_file(file_path):
    """Parst eine .properties-Datei und gibt eine Liste von Objekten (mit Kommentaren, leeren Zeilen und Zeilennummern) zurück."""
    properties_list = []
    with open(file_path, "r", encoding="utf-8") as file:
        for line_number, line in enumerate(file, start=1):
            stripped_line = line.strip()

            # Leere Zeilen
            if not stripped_line:
                properties_list.append(
                    {"line": line_number, "type": "empty", "content": ""}
                )
                continue

            # Kommentare
            if stripped_line.startswith("#"):
                properties_list.append(
                    {"line": line_number, "type": "comment", "content": stripped_line}
                )
                continue

            # Schlüssel-Wert-Paare
            match = re.match(r"^([^=]+)=(.*)$", line)
            if match:
                key, value = match.groups()
                properties_list.append(
                    {
                        "line": line_number,
                        "type": "entry",
                        "key": key.strip(),
                        "value": value.strip(),
                    }
                )

    return properties_list


def write_json_file(file_path, updated_current_json):
    updated_lines = {entry["line"]: entry for entry in updated_current_json}

    # Sortiere nach Zeilennummern und behalte Kommentare und leere Zeilen bei
    all_lines = sorted(set(updated_lines.keys()))

    original_format = []
    for line in all_lines:
        if line in updated_lines:
            entry = updated_lines[line]
        else:
            entry = None
        ref_entry = updated_lines[line]
        if ref_entry["type"] in ["comment", "empty"]:
            original_format.append(ref_entry)
        elif entry is None:
            # Füge fehlende Einträge aus der Referenzdatei hinzu
            original_format.append(ref_entry)
        elif entry["type"] == "entry":
            # Ersetze Einträge mit denen aus der aktuellen JSON
            original_format.append(entry)

    # Schreibe ins ursprüngliche Format zurück
    with open(file_path, "w", encoding="utf-8") as f:
        for entry in original_format:
            if entry["type"] == "comment":
                f.write(f"{entry['content']}\n")
            elif entry["type"] == "empty":
                f.write(f"{entry['content']}\n")
            elif entry["type"] == "entry":
                f.write(f"{entry['key']}={entry['value']}\n")


def push_difference_keys(reference_file, file_list, branch=""):
    reference_json = parse_properties_file(reference_file)

    for file_path in file_list:
        basename_current_file = os.path.basename(branch + file_path)
        if (
            branch + file_path == reference_file
            or not file_path.endswith(".properties")
            or not basename_current_file.startswith("messages_")
        ):
            continue

        current_json = parse_properties_file(branch + file_path)
        ref_json = []
        for reference in reference_json:
            for current in current_json:
                if current["type"] == "entry":
                    if reference["type"] != "entry":
                        continue
                    if reference["key"] == current["key"]:
                        reference["value"] = current["value"]
            ref_json.append(reference)
        write_json_file(branch + file_path, ref_json)


def check_difference_keys(reference_file, file_list, branch):
    push_difference_keys(reference_file, file_list, branch + "/")
    # reference_json = parse_properties_file(reference_file)

    # for file_path in file_list:
    #     basename_current_file = os.path.basename(branch + "/" + file_path)
    #     if (
    #         branch + "/" + file_path == reference_file
    #         or not file_path.endswith(".properties")
    #         or not basename_current_file.startswith("messages_")
    #     ):
    #         continue

    #     current_json = parse_properties_file(branch + "/" + file_path)
    #     ref_json = []
    #     for reference in reference_json:
    #         for current in current_json:
    #             if current["type"] == "entry":
    #                 if reference["type"] != "entry":
    #                     continue
    #                 if reference["key"] == current["key"]:
    #                     reference["value"] = current["value"]
    #         ref_json.append(reference)
    #     write_json_file(branch + "/" + file_path, ref_json)


def read_properties(file_path):
    with open(file_path, "r", encoding="utf-8") as file:
        return file.read().splitlines()


def check_difference(reference_file, file_list, branch):
    reference_branch = reference_file.split("/")[0]
    basename_reference_file = os.path.basename(reference_file)

    report = []
    report.append(
        f"#### Checking with the file `{basename_reference_file}` from the `{reference_branch}` - Checking the `{branch}`"
    )
    reference_list = read_properties(reference_file)
    is_diff = False

    only_ref_file = True

    for file_path in file_list:
        basename_current_file = os.path.basename(branch + "/" + file_path)
        if (
            branch + "/" + file_path == reference_file
            or not file_path.endswith(".properties")
            or not basename_current_file.startswith("messages_")
        ):
            # report.append(f"File '{basename_current_file}' is ignored.")
            continue
        only_ref_file = False
        report.append(f"Checking the language file `{basename_current_file}`...")
        current_list = read_properties(branch + "/" + file_path)
        reference_list_len = len(reference_list)
        current_list_len = len(current_list)

        if reference_list_len != current_list_len:
            report.append("")
            report.append("- ❌ Test 1 failed! Difference in the file!")
            is_diff = True
            if reference_list_len > current_list_len:
                report.append(
                    f"  - Missing lines! Either comments, empty lines, or translation strings are missing! {reference_list_len}:{current_list_len}"
                )
            elif reference_list_len < current_list_len:
                report.append(
                    f"  - Too many lines! Check your translation files! {reference_list_len}:{current_list_len}"
                )
            report.append("")
            report.append(f"#### ***{basename_current_file}*** wird korrigiert...")
            report.append("")
            check_difference_keys(reference_file, [file_path], branch)
        else:
            report.append("- ✅ Test 1 passed")
        if 1 == 1:
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

            if len(set_test1_list) > 0 or len(set_test2_list) > 0:
                is_diff = True
                set_test1_list = "`, `".join(set_test1_list)
                set_test2_list = "`, `".join(set_test2_list)
                report.append("- ❌ Test 2 failed")
                if len(set_test1_list) > 0:
                    report.append(
                        f"  - There are keys in ***{basename_current_file}*** `{set_test1_list}` that are not present in ***{basename_reference_file}***!"
                    )
                if len(set_test2_list) > 0:
                    report.append(
                        f"  - There are keys in ***{basename_reference_file}*** `{set_test2_list}` that are not present in ***{basename_current_file}***!"
                    )
                report.append("")
                report.append(f"#### ***{basename_current_file}*** wird korrigiert...")
                report.append("")
                check_difference_keys(reference_file, [file_path], branch)
            else:
                report.append("- ✅ Test 2 passed")
        report.append("")

    report.append("")
    if is_diff:
        report.append("## ❌ Check fail")
    else:
        report.append("## ✅ Check success")

    if not only_ref_file:
        print("\n".join(report))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Find missing keys")
    parser.add_argument(
        "--reference-file",
        required=True,
        help="Path to the reference file.",
    )
    parser.add_argument(
        "--branch",
        type=str,
        required=True,
        help="Branch name.",
    )
    parser.add_argument(
        "--files",
        nargs="+",
        required=False,
        help="List of changed files, separated by spaces.",
    )
    args = parser.parse_args()

    file_list = args.files
    print(file_list)
    if file_list is None:
        file_list = glob.glob(
            os.getcwd() + "/src/**/messages_*.properties", recursive=True
        )
        push_difference_keys(args.reference_file, file_list)
    else:
        check_difference(args.reference_file, file_list, args.branch)

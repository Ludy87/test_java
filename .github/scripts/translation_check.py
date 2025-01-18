import os
import pandas as pd
import sys


# Funktion zum Lesen der Properties-Datei und Speichern in einem Wörterbuch
def read_properties(file_path):
    with open(file_path, "r", encoding="utf-8") as file:
        properties = {}
        for line in file:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                properties[key.strip()] = value.strip()
        return properties


# Hauptsprache (en_GB) einlesen
en_gb_file_path = os.getcwd() + "/src/main/resources/messages_en_GB.properties"
en_gb_properties = read_properties(en_gb_file_path)
en_gb_keys = set(en_gb_properties.keys())

results = []

# Geänderte Dateien in der PR durchlaufen
for file_path in sys.argv[1:]:
    print(file_path)
    if (
        file_path.startswith(os.getcwd() + "/src/main/resources/messages_")
        and file_path.endswith(".properties")
        and file_path != os.getcwd() + "/src/main/resources/messages_en_GB.properties"
    ):
        language = file_path.split("_")[1].split(".")[0]

        properties = read_properties(file_path)
        keys = set(properties.keys())

        # Vergleich der Schlüssel
        missing_keys = keys - en_gb_keys
        language_keys_df = pd.DataFrame(keys, columns=[f"{language} Keys"])
        en_gb_keys_df = pd.DataFrame(en_gb_keys, columns=["en_GB Keys"])
        comparison_df = pd.concat([language_keys_df, en_gb_keys_df], axis=1)

        # Finden von fehlenden Werten
        missing_values = {key: value for key, value in properties.items() if not value}
        missing_values_df = pd.DataFrame(
            list(missing_values.items()),
            columns=["Key", f"Missing Value in {language}"],
        )

        results.append((language, comparison_df, missing_values_df))

        print(results)

# Ausgabe in eine Datei schreiben
with open("comparison_result.txt", "w", encoding="utf-8") as f:
    for language, comparison_df, missing_values_df in results:
        f.write(f"Comparison of Keys in {language} and en_GB:\n")
        f.write(comparison_df.to_string(index=False))
        f.write("\n\n")
        f.write(f"Missing Values in {language}:\n")
        f.write(missing_values_df.to_string(index=False))
        f.write("\n\n")

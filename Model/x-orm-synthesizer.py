import subprocess
import os
import xml.etree.ElementTree as ET

def run_alloy_model(als_path, alloy_jar_path, output_dir, max_solutions=5):
    """
    Runs the Alloy Analyzer on the given .als file and saves output XMLs.
    Requires Alloy JAR file and Java.
    """
    os.makedirs(output_dir, exist_ok=True)

    for i in range(max_solutions):
        out_file = os.path.join(output_dir, f"solution_{i+1}.xml")
        cmd = [
            "java", "-cp", alloy_jar_path,
            "edu.mit.csail.sdg.alloy4whole.ExampleUsingKodkod",
            als_path, str(i+1), out_file
        ]
        print(f"Running Alloy for solution {i+1}...")
        subprocess.run(cmd, check=True)

def parse_alloy_solution(xml_file):
    """
    Parses a simplified Alloy XML and extracts classes and relationships.
    This is an approximation — exact parsing depends on your Alloy instance signature.
    """
    tree = ET.parse(xml_file)
    root = tree.getroot()

    classes = []
    associations = []

    for sig in root.findall(".//sig"):
        sig_name = sig.attrib.get("label")
        if "Class" in sig_name and "$" not in sig_name:
            attr_list = []
            for field in sig.findall(".//field"):
                attr_list.append(field.attrib.get("label"))
            classes.append({
                "name": sig_name.replace("this/", ""),
                "attributes": attr_list,
                "primary_key": attr_list[0] if attr_list else "id"
            })

    for fact in root.findall(".//fact"):
        label = fact.attrib.get("label")
        if "Association" in label:
            parts = label.replace("this/", "").split("_")
            if len(parts) >= 2:
                src, dst = parts[0], parts[1]
                associations.append({
                    "src": src,
                    "dst": dst
                })

    return classes, associations

def generate_sql_from_alloy_object(object_model_name, classes, associations):
    sql_lines = []
    sql_lines.append(f"CREATE DATABASE {object_model_name};")
    sql_lines.append(f"USE {object_model_name};\n")

    for cls in classes:
        table_name = cls['name']
        attributes = cls['attributes']
        primary_key = cls['primary_key']

        sql_lines.append(f"-- Table structure for {table_name}")
        sql_lines.append(f"CREATE TABLE `{table_name}` (")
        for attr in attributes:
            datatype = "int" if "id" in attr.lower() else "varchar(64)"
            sql_lines.append(f"  `{attr}` {datatype},")
        sql_lines.append(f"  PRIMARY KEY (`{primary_key}`)")
        sql_lines.append(");\n")

    for assoc in associations:
        src = assoc['src']
        dst = assoc['dst']
        fk_name = f"FK_{src}_{dst}_idx"
        col_name = dst + "ID"
        sql_lines.append(f"ALTER TABLE `{src}`")
        sql_lines.append(f"  ADD CONSTRAINT `{fk_name}` FOREIGN KEY (`{col_name}`) REFERENCES `{dst}` (`{col_name}`) ON DELETE CASCADE ON UPDATE CASCADE;\n")

    return "\n".join(sql_lines)

def main(als_path, alloy_jar_path, output_sql_dir, temp_xml_dir):
    run_alloy_model(als_path, alloy_jar_path, temp_xml_dir)

    for i, xml_file in enumerate(sorted(os.listdir(temp_xml_dir))):
        full_path = os.path.join(temp_xml_dir, xml_file)
        classes, associations = parse_alloy_solution(full_path)
        schema_name = os.path.splitext(os.path.basename(als_path))[0] + f"_Sol_{i+1}"
        sql_text = generate_sql_from_alloy_object(schema_name, classes, associations)

        with open(os.path.join(output_sql_dir, f"{schema_name}.sql"), "w") as f:
            f.write(sql_text)
        print(f"✅ SQL schema written: {schema_name}.sql")

# Example usage
# main(
#     als_path="Bank.als",
#     alloy_jar_path="/path/to/alloy.jar",
#     output_sql_dir="./generated_sql",
#     temp_xml_dir="./alloy_solutions"
# )

# Recommended File Tree Layout
# x-orm-synthesizer/
# ├── Bank.als
# ├── ecommerce.als
# ├── alloy.jar
# ├── generate_sql.py
# ├── alloy_solutions/         <-- created by script
# │   ├── solution_1.xml
# │   ├── solution_2.xml
# │   └── ...
# ├── generated_sql/           <-- created by script
# │   ├── Bank_Sol_1.sql
# │   ├── Bank_Sol_2.sql
# │   └── ...

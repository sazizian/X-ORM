import random
import os
import pandas as pd

# Object models used in the paper
object_models = [
    "Customer-Order", "Online Store", "Bank", "Camping",
    "Flagship", "Decider", "Library Mgmt.", "CSOS", "E-commerce"
]

# Basic schema generation template
def generate_schema(model_name, schema_id):
    num_tables = random.randint(3, 8)
    tables = []
    for i in range(num_tables):
        table_name = f"{model_name.replace(' ', '_')}_Table_{schema_id}_{i}"
        columns = [f"col_{j} INT" for j in range(random.randint(2, 5))]
        table_def = f"CREATE TABLE {table_name} (\n  id INT PRIMARY KEY,\n  " + ",\n  ".join(columns) + "\n);\n"
        tables.append(table_def)

    # Generate random associations (foreign keys)
    associations = []
    for _ in range(random.randint(1, num_tables - 1)):
        t1 = random.choice(tables)
        t2 = random.choice(tables)
        if t1 != t2:
            table1 = t1.split()[2]
            table2 = t2.split()[2]
            fk_name = f"fk_{schema_id}_{random.randint(1, 100)}"
            assoc = f"ALTER TABLE {table1} ADD CONSTRAINT {fk_name} FOREIGN KEY (id) REFERENCES {table2}(id);\n"
            associations.append(assoc)

    return "\n".join(tables + associations)

# Generate schemas
output_dir = "/mnt/data/generated_schemas"
os.makedirs(output_dir, exist_ok=True)

records = []
for model in object_models:
    file_path = os.path.join(output_dir, f"{model.replace(' ', '_')}_schemas.sql")
    with open(file_path, "w") as f:
        for schema_id in range(1, 101):  # 100 schemas per object model
            schema = generate_schema(model, schema_id)
            f.write(f"-- Schema {schema_id} for {model}\n")
            f.write(schema + "\n\n")
    records.append({"Model": model, "File Path": file_path})

# Display result
df = pd.DataFrame(records)
import ace_tools as tools; tools.display_dataframe_to_user(name="Generated Schema Files", dataframe=df)

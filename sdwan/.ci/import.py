import json
import os
import subprocess
import re


CWD = "../"

IMPORT_TF_FILENAME = "import.tf"
IMPORT_TF_PATH = os.path.join(CWD, IMPORT_TF_FILENAME)
IMPORT_PLAN_FILENAME = "import_plan.tfplan"
IMPORT_PLAN_PATH = os.path.join(CWD, IMPORT_PLAN_FILENAME)
IMPORT_PLAN_JSON_FILENAME = "import_plan.json"
IMPORT_PLAN_JSON_PATH = os.path.join(CWD, IMPORT_PLAN_JSON_FILENAME)
SDWAN_JSON_FILENAME = "sdwan.json"
SDWAN_JSON_PATH = os.path.join(CWD, SDWAN_JSON_FILENAME)



def get_id_to_values(tf_file_resource, json_file_key, json_file_resource, to_dir_, child: bool = False, parent_id: str = '', parent_name: str = ''):
    changes = [
        item for item in tf_file_resource 
        if (json_file_key == 'feature_templates' and item.get("type").endswith('feature_template')) or
           (json_file_key != 'feature_templates' and item.get("type") == f'sdwan_{json_file_key}' and item.get('type').startswith('sdwan_')) or 
           (item.get("type") == 'sdwan_attach_feature_device_template')
    ]

    id_pattern = re.compile(r'"([^"]*Id)":\s*"([a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12})"')

    for change in changes:
        if change and change.get("module_address") == "module.sdwan" and change.get("type").startswith("sdwan"):
            to_ = '.'.join([change.get("module_address"), change.get("type"), change.get("name")])
            for element in json_file_resource:
                if change.get("name") == "attach_feature_device_template" and json_file_key == "cli_device_template":
                    name = f'{parent_name}/{element["data"].get("csv-deviceId")}' if child else element["data"].get("csv-deviceId")
                    if change.get("index") == name:
                        endpoint = element['endpoint']
                        id_ = endpoint.split('/')[-1]
                        id_ = f'{id_, [name]}'.translate(str.maketrans("", "", "'() "))
                        id_name_ = (id_, change.get("index"))
                        if id_name_ not in to_dir_:
                            to_dir_.setdefault(to_, []).append(id_name_)
                        break
                elif change.get("name").endswith(("feature_template", "device_template")) and not change.get("name").endswith(("attach_feature_device_template")):
                    name = f'{parent_name}/{element["data"].get("templateName")}' if child else element["data"].get("templateName")
                    id_ = element["data"].get("templateId")
                elif change.get("name") in {"localized_policy", "centralized_policy", "security_policy"}:
                    name = element["data"].get("policyName")
                    if change.get("index") == name:
                        endpoint = element['endpoint']
                        id_ = endpoint.split('/')[-1]
                        if element["data"].get("isPolicyActivated"):
                            id_name_ = (id_, "activated_policy")
                            to_centralizes = 'module.sdwan.sdwan_activate_centralized_policy.activate_centralized_policy'
                            to_dir_.setdefault(to_centralizes, []).append(id_name_)
                        id_name_ = (id_, change.get("index"))
                        if id_name_ not in to_dir_:
                            to_dir_.setdefault(to_, []).append(id_name_)
                        break
                else:
                    name = f'{parent_name}/{element["data"].get("name")}' if child else element["data"].get("name")

                if change.get("index") == name:
                    if not change.get("name").endswith(("feature_template", "device_template", "localized_policy")):
                        data_section = json.dumps(element["data"])
                        match = id_pattern.search(data_section)
                        id_ = match.group(2) if match else None
                    id_name_ = (id_, change.get("index"))
                    if id_name_ not in to_dir_:
                        to_dir_.setdefault(to_, []).append(id_name_)
                        

def tf_import():
    if os.path.exists(IMPORT_TF_PATH):
        os.remove(IMPORT_TF_PATH)

    # terraform init
    subprocess.run(["terraform", "init"], cwd=CWD)

    # terraform plan
    subprocess.run(
        ["terraform", "plan", "-out="+IMPORT_PLAN_FILENAME, "-input=false"], cwd=CWD
    )
    with open(IMPORT_PLAN_JSON_PATH, "w") as f:
        subprocess.run(
            ["terraform", "show", "-json", IMPORT_PLAN_FILENAME],
            stdout=f,
            cwd=CWD,
        )
    
    tf_plan = None
    with open(IMPORT_PLAN_JSON_PATH) as file:
        tf_plan = json.load(file)

    sdwan_json = None
    with open(SDWAN_JSON_PATH) as file:
        sdwan_json = json.load(file)

    to_dir_ = {}
    for json_file_key, json_file_resource in sdwan_json.items():
        tf_file_resource = tf_plan.get("resource_changes", [])
        if tf_file_resource:
            get_id_to_values(tf_file_resource, json_file_key, json_file_resource, to_dir_)

    terraform_imports = ""
    for k, v in to_dir_.items():
        for id, index in v:
            id_value = id if not "repository" in k else index
            if id != None or "repository" in k:
                terraform_imports += "import {\n"
                terraform_imports += f'  id = "{id_value}"\n'
                terraform_imports += f'  to = {k}[\"{index}\"]\n'
                terraform_imports += "}\n"
    
    with open(IMPORT_TF_PATH, "w") as file:
        file.write(terraform_imports)


    # cleanup
    if os.path.exists(IMPORT_PLAN_PATH):
        os.remove(IMPORT_PLAN_PATH)
    if os.path.exists(IMPORT_PLAN_JSON_PATH):
        os.remove(IMPORT_PLAN_JSON_PATH)


if __name__ == "__main__":
    tf_import()

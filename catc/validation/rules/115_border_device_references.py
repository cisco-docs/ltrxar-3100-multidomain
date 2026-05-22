class Rule:
    id = "115"
    description = "Verify if border device name is defined in inventory devices (by name or fqdn_name)"
    severity = "HIGH"

    @classmethod
    def match(cls, data):
        results = []
        try:
            all_inventory_device_names = []
            all_inventory_device_fqdns = []
            for device in data["catalyst_center"].get("inventory", {}).get("devices", []):
                all_inventory_device_names.append(device["name"])
                if device.get("fqdn_name"):
                    all_inventory_device_fqdns.append(device["fqdn_name"])

            for border_device in data["catalyst_center"].get("fabric", {}).get("border_devices", []):
                border_name = border_device.get("name")
                if border_name not in all_inventory_device_names and border_name not in all_inventory_device_fqdns:
                    results.append(f"catalyst_center.fabric.border_devices.name: {border_name} is not defined under catalyst_center.inventory.devices (checked name and fqdn_name)")

        except KeyError as e:
            print(f"KeyError: {e}")
        return results


## UNCOMMENT TO TEST RULE LOCALLY
# import os
# from yaml.loader import SafeLoader
# import yaml
# from collections import defaultdict

# data = defaultdict(dict)
# directory = "../data"
# #directory = "../../tests/integration/fixtures/catalystcenter/standard"
# a = Rule()

# for filename in os.listdir(directory):
#     if filename.endswith(".yaml"):      
#         with open(os.path.join(directory, filename)) as file:
#             file_data = yaml.load(file, Loader=SafeLoader)
#             if file_data is not None:
#                 for key, value in file_data.items():
#                     data[key].update(value)

# print(a.match(dict(data)))


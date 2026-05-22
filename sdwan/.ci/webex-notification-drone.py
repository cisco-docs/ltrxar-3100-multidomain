# -*- coding: utf-8 -*-

# Copyright: (c) 2022, Daniel Schmidt <danischm@cisco.com>

# Expects the following environment variables:
# - WEBEX_TOKEN
# - WEBEX_ROOM_ID
# - DRONE_BUILD_STATUS
# - DRONE_REPO_OWNER
# - DRONE_REPO_NAME
# - DRONE_BUILD_NUMBER
# - DRONE_BUILD_LINK
# - DRONE_COMMIT_MESSAGE
# - DRONE_COMMIT_LINK
# - DRONE_COMMIT_AUTHOR_NAME
# - DRONE_COMMIT_AUTHOR_EMAIL
# - DRONE_COMMIT_BRANCH
# - DRONE_BUILD_EVENT

import json
import os
import requests

TEMPLATE = """[**[{build_status}] {repo_owner}/{repo_name} #{build_number}**]({build_link})
* _Commit_: [{commit_message}]({commit_link})
* _Author_: {commit_author_name} {commit_author_email}
* _Branch_: {commit_branch}
* _Event_:  {build_event}
""".format(
    build_status=os.getenv("DRONE_BUILD_STATUS"),
    repo_owner=os.getenv("DRONE_REPO_OWNER"),
    repo_name=os.getenv("DRONE_REPO_NAME"),
    build_number=os.getenv("DRONE_BUILD_NUMBER"),
    build_link=os.getenv("DRONE_BUILD_LINK"),
    commit_message=os.getenv("DRONE_COMMIT_MESSAGE"),
    commit_link=os.getenv("DRONE_COMMIT_LINK"),
    commit_author_name=os.getenv("DRONE_COMMIT_AUTHOR_NAME"),
    commit_author_email=os.getenv("DRONE_COMMIT_AUTHOR_EMAIL"),
    commit_branch=os.getenv("DRONE_COMMIT_BRANCH"),
    build_event=os.getenv("DRONE_BUILD_EVENT"),
)

FMT_OUTPUT = """\n**Terraform FMT Errors**
```
"""

VALIDATE_OUTPUT = """\n**Validate Errors**
```
"""

PLAN_OUTPUT = """\n[**Terraform Plan**](https://engci-maven-master.cisco.com/artifactory/list/AS-release/Community/{}/{}/{}/plan.txt)
```
""".format(
    os.getenv("DRONE_REPO_OWNER"),
    os.getenv("DRONE_REPO_NAME"),
    os.getenv("DRONE_BUILD_NUMBER"),
)

TEST_OUTPUT = """\n[**Testing**](https://engci-maven-master.cisco.com/artifactory/list/AS-release/Community/{}/{}/{}/log.html)
```
""".format(
    os.getenv("DRONE_REPO_OWNER"),
    os.getenv("DRONE_REPO_NAME"),
    os.getenv("DRONE_BUILD_NUMBER"),
)


def main():
    message = TEMPLATE
    if os.path.isfile("./fmt_output.txt"):
        with open("./fmt_output.txt", "r") as fmt_file:
            fmt_output = fmt_file.read()
            if len(fmt_output.strip()):
                message += FMT_OUTPUT + fmt_output + "\n```\n"
    if os.path.isfile("./validate_output.txt"):
        with open("./validate_output.txt", "r") as validate_file:
            validate_output = validate_file.read()
            if len(validate_output.strip()):
                message += VALIDATE_OUTPUT + validate_output + "\n```\n"
    if os.path.isfile("./plan.txt"):
        with open("./plan.txt", "r") as in_file:
            plan = in_file.read()
        for line in plan.split("\n"):
            if line.startswith("Plan:"):
                message += PLAN_OUTPUT + line[6:-1] + "\n```\n"
    if os.path.isfile("./test_output.txt"):
        with open("./test_output.txt", "r") as in_file:
            tests = in_file.read()
        tests_line = ""
        for line in tests.split("\n"):
            if "tests, " in line:
                tests_line = line
        if tests_line:
            message += TEST_OUTPUT + tests_line[0:-1] + "\n```\n"

    body = {"roomId": os.getenv("WEBEX_ROOM_ID"), "markdown": message}
    headers = {
        "Authorization": "Bearer {}".format(os.getenv("WEBEX_TOKEN")),
        "Content-Type": "application/json",
    }
    resp = requests.post(
        "https://api.ciscospark.com/v1/messages", headers=headers, data=json.dumps(body)
    )
    if resp.status_code != 200:
        print(
            "Webex notification failed, status code: {}, response: {}.".format(
                resp.status_code, resp.text
            )
        )


if __name__ == "__main__":
    main()

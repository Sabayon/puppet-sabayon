#!/usr/bin/python3

import json
import os
import re
import subprocess
import sys

ENMAN = '/usr/bin/enman'
PUPPET = '/opt/puppetlabs/bin/puppet'
VALID_REPO_NAME = r'^[a-zA-Z0-9_-]+$'


def success(data={}):
    output = {
        "success": True,
    }
    output.update(data)
    json.dump(output, sys.stdout)
    sys.exit(0)


def fail(msg, details={}):
    json.dump({
        "success": False,
        "_error": {
            "msg": msg,
            "kind": "puppetlabs.tasks/task-error",
            "details": details,
        }
    }, sys.stdout)
    sys.exit(1)


def list_repos(mode):
    if mode == 'installed':
        return list_installed()
    else:
        return list_available()


def list_available():
    proc = subprocess.Popen([ENMAN, 'list', '-q', '--available'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = proc.communicate()
    if proc.returncode == 0:
        repos = stdout.decode('utf-8').split()
    else:
        fail(f'Enman list failed: {stderr}', {'exitcode': proc.returncode})

    return repos


def list_installed():
    proc = subprocess.Popen([ENMAN, 'list', '-q', '--installed'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = proc.communicate()
    if proc.returncode == 0:
        repos = stderr.decode('utf-8').split()
    else:
        fail(f'Enman list failed: {stderr}', {'exitcode': proc.returncode})

    return repos

def add_repo(name, url=None):
    if not re.match(VALID_REPO_NAME, name):
        fail(f"Enman add failed: invalid repo name {name}")

    cmd = [PUPPET, 'resource', 'enman_repo', name, 'ensure=present']
    if url:
        cmd.append(f'url={url}')

    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = proc.communicate()
    if proc.returncode == 0:
        success()
    else:
        fail(f'Enman add failed: {stderr}', {'exitcode': proc.returncode})


def remove_repo(name):
    if not re.match(VALID_REPO_NAME, name):
        fail(f"Enman add failed: invalid repo name {name}")

    cmd = [PUPPET, 'resource', 'enman_repo', name, 'ensure=absent']
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = proc.communicate()
    if proc.returncode == 0:
        success()
    else:
        fail(f'Enman remove failed: {stderr}', {'exitcode': proc.returncode})


def main():
    if os.environ['PT_action'] in ['list-installed', 'list-available']:
        mode = os.environ['PT_action'].split('-')[1]
        repos = list_repos(mode)
        success({'repos': repos})

    elif os.environ['PT_action'] == 'add':
        if 'PT_repo' not in os.environ:
            fail('repo parameter is required for remove operations')

        add_repo(os.environ['PT_repo'], url=os.environ.get('PT_url', None))

    elif os.environ['PT_action'] == 'remove':
        if 'PT_repo' not in os.environ:
            fail('repo parameter is required for remove operations')

        remove_repo(os.environ['PT_repo'])

if __name__ == '__main__':
    main()

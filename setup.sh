#!/bin/bash

ansible-playbook -c local -i localhost, setup.yaml --ask-become-pass

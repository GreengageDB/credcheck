#!/usr/bin/env bash

bash /home/gpadmin/credcheck/ci/install.bash
cd /home/gpadmin/credcheck
su gpadmin -c 'bash ci/test.bash'

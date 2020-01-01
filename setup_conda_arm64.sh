#!/bin/bash

# Note to the future: keep the conda scripts separate for each OS because many
# packages call ci-helpers with:
#
#   source ci-helpers/travis/setup_conda_$TRAVIS_OS_NAME.sh
#
# The present script was added later.

if [[ $DEBUG == True ]]; then
    set -x
fi

# First check: if the build should be run at all based on the event type

if [[ ! -z $EVENT_TYPE ]]; then
    for event in $EVENT_TYPE; do
        if [[ $TRAVIS_EVENT_TYPE = $event ]]; then
            allow_to_build=True
        fi
    done
    if [[ $allow_to_build != True ]]; then
        travis_terminate 0
    fi
fi

# Second check: if any of the custom tags are used to skip the build

TR_SKIP="\[(skip travis|travis skip)\]"
DOCS_ONLY="\[docs only|build docs\]"

# Travis doesn't provide the commit message of the top of the branch for
# PRs, only the commit message of the merge. Thus this ugly workaround is
# needed for now.

if [[ $TRAVIS_PULL_REQUEST == false ]]; then
    COMMIT_MESSAGE=${TRAVIS_COMMIT_MESSAGE}
else
    COMMIT_MESSAGE=$(git show -s $TRAVIS_COMMIT_RANGE | awk 'BEGIN{count=0}{if ($1=="Author:") count++; if (count==1) print $0}')
fi

# Skip build if the commit message contains [skip travis] or [travis skip]
# Remove workaround once travis has this feature natively
# https://github.com/travis-ci/travis-ci/issues/5032

if [[ ! -z $(echo ${COMMIT_MESSAGE} | grep -E "${TR_SKIP}") ]]; then
    echo "Travis was requested to be skipped by the commit message, exiting."
    travis_terminate 0
elif [[ ! -z $(echo ${COMMIT_MESSAGE} | grep -E "${DOCS_ONLY}") ]]; then
    if [[ ! $SETUP_CMD =~ build_docs|build_sphinx|pycodestyle|pylint|flake8|pep8 ]] && [[ ! $MAIN_CMD =~ pycodestyle|pylint|flake8|pep8 ]]; then
        # we also allow the style checkers to run here
        echo "Only docs build was requested by the commit message, exiting."
        travis_terminate 0
    fi
fi

echo "==================== Starting executing ci-helpers scripts ====================="
wget -q "https://github.com/Archiconda/build-tools/releases/download/0.2.3/Archiconda3-0.2.3-Linux-aarch64.sh" -O archiconda.sh
chmod +x archiconda.sh
mkdir $HOME/.conda
echo"bash archiconda.sh -b -p $HOME/miniconda"
bash archiconda.sh -b -p $HOME/miniconda
echo "export PATH=$HOME/miniconda/bin:$PATH"
export PATH="$HOME/miniconda/bin:$PATH"
sudo cp -r $HOME/miniconda/bin/* /usr/bin/
echo "sudo ln -s /home/travis/miniconda/etc/profile.d/conda.sh /etc/profile.d/conda.sh"
sudo ln -s /home/travis/miniconda/etc/profile.d/conda.sh /etc/profile.d/conda.sh
echo "conda activate" >> ~/.bashrc
source ~/.bashrc
sudo conda activate 
# Install common Python dependencies
source "$( dirname "${BASH_SOURCE[0]}" )"/setup_dependencies_common.sh

if [[ $SETUP_XVFB == True ]]; then
    export DISPLAY=:99.0
    /sbin/start-stop-daemon --start --quiet --pidfile /tmp/custom_xvfb_99.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :99 -screen 0 1920x1200x24 -ac +extension GLX +render -noreset
fi
echo "================= Returning executing local .travis.yml script ================="

set +x

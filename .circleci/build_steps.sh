#!/usr/bin/env bash

# PLEASE NOTE: This script has been automatically generated by conda-smithy. Any changes here
# will be lost next time ``conda smithy rerender`` is run. If you would like to make permanent
# changes to this script, consider a proposal to conda-smithy so that other feedstocks can also
# benefit from the improvement.

set -xeuo pipefail
export PYTHONUNBUFFERED=1

cat >~/.condarc <<CONDARC

channels:
 - conda-forge
 - defaults

conda-build:
 root-dir: /home/conda/staged-recipes/build_artifacts

show_channel_urls: true

CONDARC

# Copy the host recipes folder so we don't ever muck with it
cp -r /home/conda/staged-recipes/recipes ~/conda-recipes
cp -r /home/conda/staged-recipes/.ci_support ~/.ci_support

# Find the recipes from master in this PR and remove them.
echo "Pending recipes."
ls -la ~/conda-recipes
echo "Finding recipes merged in master and removing them from the build."
pushd /home/conda/staged-recipes/recipes > /dev/null
if [ "${AZURE}" == "True" ]; then
    git fetch --force origin master:master
fi
git ls-tree --name-only master -- . | xargs -I {} sh -c "rm -rf ~/conda-recipes/{} && echo Removing recipe: {}"
popd > /dev/null

# Unused, but needed by conda-build currently... :(
export CONDA_NPY='19'

# Make sure build_artifacts is a valid channel
conda index /home/conda/staged-recipes/build_artifacts

conda install --yes --quiet "conda!=4.6.1,<4.7.11a0" conda-forge-ci-setup=2.* conda-forge-pinning networkx=2.3 "conda-build>=3.16"
export FEEDSTOCK_ROOT="${FEEDSTOCK_ROOT:-/home/conda/staged-recipes}"
source run_conda_forge_build_setup

# yum installs anything from a "yum_requirements.txt" file that isn't a blank line or comment.
find ~/conda-recipes -mindepth 2 -maxdepth 2 -type f -name "yum_requirements.txt" \
    | xargs -n1 cat | { grep -v -e "^#" -e "^$" || test $? == 1; } | \
    xargs -r /usr/bin/sudo -n yum install -y

python ~/.ci_support/build_all.py ~/conda-recipes

touch "/home/conda/staged-recipes/build_artifacts/conda-forge-build-done"

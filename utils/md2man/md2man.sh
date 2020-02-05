#!/usr/bin/env bash
#
# Copyright 2020, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

#
# md2man.sh -- convert markdown to groff man pages
#
# usage: md2man.sh file template outfile
#
# This script converts markdown file into groff man page using pandoc.
# It performs some pre- and post-processing for better results:
# - parse input file for YAML metadata block and read man page title,
#   section and version
# - cut-off metadata block and license
# - unindent code blocks
#

set -e
set -o pipefail

filename=$1
template=$2
outfile=$3
version=$4
title=`sed -n 's/^title:\ _MP(*\([A-Za-z_-]*\).*$/\1/p' $filename`
section=`sed -n 's/^title:.*\([0-9]\))$/\1/p' $filename`
secondary_title=`sed -n 's/^secondary_title:\ *\(.*\)$/\1/p' $filename`

dt="$(date --utc --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%F)"
# since genereted docs are not kept in the repo the output dir may not exist
out_dir=`echo $outfile | sed 's/\(.*\)\/.*/\1/'`
mkdir -p $out_dir

cat $filename | sed -n -e '/# NAME #/,$p' |\
	pandoc -s -t man -o $outfile --template=$template \
	-V title=$title -V section=$section \
	-V date="$dt" -V version="$version" \
	-V year=$(date +"%Y") -V secondary_title="$secondary_title" |
sed '/^\.IP/{
N
/\n\.nf/{
	s/IP/PP/
    }
}'

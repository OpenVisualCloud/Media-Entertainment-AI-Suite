#!/usr/bin/python3

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024 Intel Corporation
# Media Communications Mesh

# Sphinx documentation build configuration file

# General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

from __future__ import annotations

import os
import sys

project = 'Media Communications Mesh'
copyright = '2025, Intel Corporation'
author = 'Intel Corporation'

extensions = [
    'myst_parser',
    'sphinx.ext.graphviz',
    'sphinxcontrib.mermaid',
    'sphinx_copybutton'
]

coverage_statistics_to_report = coverage_statistics_to_stdout = True

inline_highlight_respect_highlight = False
inline_highlight_literals = False

templates_path = ['_templates']
exclude_patterns = [
    '_build/*',
    'tests/*',
    'patches/*',
    'Thumbs.db',
    '.DS_Store',
    '**/CMakeLists.txt',
    '*CMakeLists.txt',
    '**/requirements.txt'
]

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_book_theme'
html_static_path = ['../_static']
language = "en_US"

# Options for myst_html_meta output -------------------------------------------------

myst_html_meta = {
    "description lang=en": "Media Entertainment AI Suite",
    "keywords": "Intel®, Intel, Media Entertainment AI Suite, AI, MCM, MTL, Tiber, st20, st22, ST 2110, ST2110",
    "property=og:locale":  "en_US"
}
myst_enable_extensions = [ "strikethrough" ]
myst_fence_as_directive = [ "mermaid" ]

suppress_warnings = ["myst.xref_missing", "myst.strikethrough"]

source_suffix = {
    '.rst': 'restructuredtext',
    '.md': 'markdown',
}

sys.path.insert(0, os.path.abspath('..'))
sys.path.insert(0, os.path.abspath('../../'))

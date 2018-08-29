#!/usr/bin/env python3

from argparse import ArgumentParser
from functools import reduce
import os
import re
import shutil
import yaml

TEMPLATE_SPECIAL_CONFIGS = [
    'packages',
    'pages'
]

STDLIB_PACKAGES = [
    'assert',
    'backpressure',
    'buffered',
    'builtin',
    'bureaucracy',
    'capsicum',
    'cli',
    'collections',
    'collections-persistent',
    'crypto',
    'debug',
    'encode-base64',
    'files',
    'format',
    'glob',
    'ini',
    'itertools',
    'json',
    'logger',
    'math',
    'net',
    'net-http',
    'net-ssl',
    'options',
    'ponybench',
    'ponytest',
    'process',
    'promises',
    'random',
    'regex',
    'serialise',
    'signals',
    'strings',
    'term',
    'time'
]


class MkdocsFixer(object):
    def __init__(self, docs, template):
        docs_file_path, docs_dir_path, template_path = self.validate_args(docs, template)
        docs_file_data, template_data = self.fetch_yaml(docs_file_path, template_path)
        packages = template_data['packages']
        new_docs_file_data = self.update_yaml_config(docs_file_data, template_data, packages)
        self.update_doc_files(docs_dir_path, packages)
        self.dump_yaml(docs_file_path, new_docs_file_data)

    def validate_args(self, docs, template):
        error_list = []

        # docs_dir must be a writeable directory with a "mkdocs.yml" file and a "docs" directory
        if os.path.isdir(docs):
            docs_file_path = os.path.join(docs, 'mkdocs.yml')
            if not os.path.isfile(docs_file_path) or not os.access(docs_file_path, os.W_OK):
                error_list.append(" - No valid mkdocs.yml file in {}".format(docs))
            docs_dir_path = os.path.join(docs, 'docs')
            if not os.path.isdir(docs_dir_path) or not os.access(docs_dir_path, os.W_OK):
                error_list.append(" - No valid docs directory in {}".format(docs))
        else:
            error_list.append(" - {} is not a valid Pony MkDocs directory".format(docs))

        # template must be a readable file
        if os.path.isfile(template):
            if os.access(template, os.R_OK):
                template_path = template
            else:
                error_list.append(" - {} must be readable".format(docs))
        else:
            error_list.append(" - {} is not a valid file".format(docs))

        if error_list:
            raise OSError("Found errors when validating args:\n{}".format('\n'.join(error_list)))

        return docs_file_path, docs_dir_path, template_path

    def fetch_yaml(self, docs_file_path, template_path):
        with open(docs_file_path, 'r') as f:
            docs_file_data = yaml.load(f.read())
        with open(template_path, 'r') as f:
            template_data = yaml.load(f.read())

        return docs_file_data, template_data

    def update_yaml_config(self, docs_file_data, template_data, packages):
        new_docs_file_data = docs_file_data.copy()
        for k, v in template_data.items():
            if k in TEMPLATE_SPECIAL_CONFIGS:
                continue
            new_docs_file_data[k] = v

        new_pages = []
        page_regex = re.compile(r'^package (.*)$')
        for page in new_docs_file_data['pages']:
            section = list(page)[0]

            # Remove non-package sources from YAML
            if section == "source":
                source_code_list = page[section]
                new_source_code_list = []
                source_regex = re.compile(r'^src/([^/]*)/.*$')
                for item in source_code_list:
                    source_name = list(item)[0]
                    source_file = item[source_name]
                    match = source_regex.search(source_file)
                    if match.group(1) in packages:
                        new_source_code_list.append(item)
                page[section] = new_source_code_list
                new_pages.append(page)

            # Remove non-package or non-default docs from YAML
            else:
                match = page_regex.search(section)
                if not match or match.group(1) in packages:
                    new_pages.append(page)

        new_docs_file_data['pages'] = new_pages
        return new_docs_file_data

    def update_doc_files(self, docs_dir_path, packages):
        stdlib_link_regex_list = list(map(
            (lambda x: re.compile(r'\[(.+?)\]\(({}-[^)]+)\)'.format(x))),
            STDLIB_PACKAGES))
        for file_name in os.listdir(docs_dir_path):

            # Remove non-package sources from dir
            if file_name == 'src':
                src_dir_path = os.path.join(docs_dir_path, 'src')
                for src_dir in os.listdir(src_dir_path):
                    if src_dir not in packages:
                        shutil.rmtree(os.path.join(src_dir_path, src_dir))

            # Remove links to other packages
            elif file_name == 'index.md':
                with open(os.path.join(docs_dir_path, file_name), 'r+') as f:
                    index_lines = []
                    for line in f:
                        if line.startswith('* ['):
                            is_package_line = reduce(
                                (lambda x, y: x or line.startswith('{}]('.format(y.replace('-', '/')), 3)),
                                packages,
                                False)
                            if is_package_line:
                                index_lines.append(line)
                        else:
                            index_lines.append(line)
                    f.seek(0)
                    f.truncate()
                    f.writelines(index_lines)

            # Remove non-package or non-default docs from dir, and update stdlib links
            else:
                file_path = os.path.join(docs_dir_path, file_name)
                is_package_file = reduce((lambda x, y: x or file_name.startswith(y)), packages, False)
                if is_package_file:
                    with open(file_path, 'r+') as f:
                        file_data = f.read()
                        new_file_data = reduce(
                            (lambda x, y: y.sub(r'[\g<1>](https://stdlib.ponylang.org/\g<2>)', x)),
                            stdlib_link_regex_list,
                            file_data)
                        f.seek(0)
                        f.truncate()
                        f.write(new_file_data)
                else:
                    os.remove(file_path)

    def dump_yaml(self, docs_file_path, new_docs_file_data):
        with open(docs_file_path, 'w') as f:
            f.write(yaml.dump(new_docs_file_data, default_flow_style = False))


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('-d', '--docs', dest='docs', required=True,
                        help="Pony MkDocs DIR to be fixed", metavar='DIR')
    parser.add_argument('-t', '--template', dest='template', required=True,
                        help="MkDocs template FILE with base configs", metavar='FILE')
    args = parser.parse_args()
    MkdocsFixer(args.docs, args.template)

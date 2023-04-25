import yaml
import sys


def has_dict_keys(d, keys):
    if isinstance(keys, list):
        for _ in keys:
            try:
                d = d[_]
            except:
                return False
            return True
    else:
        if keys in d.keys():
            return True, d[keys]
        return False


def set_nested(d, k, v):
    if len(k) <= 1:
        d[k[0]] = v
    else:
        ok = k[0]
        k = k[1:]
        set_nested(d[ok], k, v)


def read_and_modify_one_block_of_yaml_data(filename, key, filter_by, new_data):

    with open(f'{filename}', 'r') as f:
        data = yaml.safe_load_all(f)
        data_all = []
        for doc in data:
            doc_dict = doc
            if has_dict_keys(doc_dict, key):
                doc_ = doc_dict
                for k in key:
                    doc_ = doc_[k]
                if isinstance(doc_, list):
                    doc_ = doc_[0]
                if filter_by['key'] in doc_.keys() and doc_[filter_by['key']] == filter_by['value']:
                    doc_ = {**doc_, **new_data}
                set_nested(doc_dict,key,doc_)

            data_all.append(doc_dict)
    with open(f'new_{filename}', 'w') as file:
        yaml.dump_all(data_all, file)


# read_and_modify_one_block_of_yaml_data("checkov-job-test.yaml",
#                                        key=['spec', 'template', 'spec', 'containers'],
#                                        filter_by={'key': 'name', 'value': 'checkov'},
#                                        new_data={'resources': {
#                                            'requests': {'memory': '512Mi'},
#                                            'limits': {'memory': '1024Mi'}
#                                        }
#                                        })

read_and_modify_one_block_of_yaml_data(sys.argv[1],
                                       key=['spec', 'template', 'spec', 'containers'],
                                       filter_by={'key': 'name', 'value': 'checkov'},
                                       new_data={'resources': {
                                           'requests': {'memory': '512Mi'},
                                           'limits': {'memory': '1024Mi'}
                                       }
                                       })

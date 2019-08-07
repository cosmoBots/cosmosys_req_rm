#!/usr/bin/env python
# coding: utf-8

# In[ ]:

from cfg.configfile_req import *
from redminelib import Redmine
import json
import sys

# Preparamos el fichero JSON que usaremos para el árbol
def create_tree(current_issue,current_project):
    #print("issue: " + current_issue.subject)
    issue_url = req_server_url+'/issues/'+str(current_issue.id)
    issue_new_url = (req_server_url+'/projects/'+current_project.identifier+'/issues/new?issue[parent_issue_id]='+str(current_issue.id)+r'&issue[tracker_id]='+str(current_issue.tracker.id))
    tree_node = {'title': current_issue.custom_fields.get(req_chapter_cf_id).value + ": " + current_issue.subject + ": " + current_issue.custom_fields.get(req_title_cf_id).value,
             'subtitle': current_issue.description,
             'expanded': True,
             'id': str(current_issue.id),
             'return_url': req_server_url+'/cosmosys_reqs/'+str(current_issue.id)+'/tree.json',
             'issue_show_url': issue_url,
             'issue_new_url': issue_new_url,
             'issue_edit_url': issue_url+"/edit",
             'children': []
            }
    chlist = redmine.issue.filter(parent_id=current_issue.id)
    childrenitems = sorted(chlist, key=lambda k: k.custom_fields.get(req_chapter_cf_id).value)
    #print("children ",childrenitems)
    for c in childrenitems:
        child_issue = redmine.issue.get(c.id)
        child_node = create_tree(child_issue,current_project)
        tree_node['children'].append(child_node)
        
    return tree_node


if len(sys.argv)>1:
    my_issue_id = int(sys.argv[1])
    redmine = Redmine(req_server_url,key=req_key_txt)
    my_issue = redmine.issue.get(my_issue_id)
    my_project = redmine.project.get(my_issue.project.id)

    treedata = []
    tree_node = create_tree(my_issue,my_project)
    treedata.append(tree_node)

    filename = './plugins/cosmosys/assets/javascripts/reqtree/src/reqtreedata_' + str(my_issue.project.id) + '_' + str(my_issue_id) + '.json'
    #with open(filename, 'w') as outfile:  
    #    json.dump(treedata, outfile)

    json.dump(treedata,sys.stdout)


    #print("Acabamos")
#else:
#    print("Debe proporcionar un argumento")


# In[ ]:
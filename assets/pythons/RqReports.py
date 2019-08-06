#!/usr/bin/env python
# coding: utf-8

# In[ ]:

from cfg.configfile_req import *
from redminelib import Redmine

print(req_server_url)
print(req_key_txt)

import sys

print ("This is the name of the script: ", sys.argv[0])
print ("Number of arguments: ", len(sys.argv))
print ("The arguments are: " , str(sys.argv))

print(req_server_url)
print(req_key_txt)

#pr_id_str = req_project_id_str
pr_id_str = sys.argv[1]
print(pr_id_str)

#reporting_path = reporting_dir
reporting_path = sys.argv[2]
print(reporting_path)

#img_path = img_dir
img_path = sys.argv[3]
print(img_path)

redmine = Redmine(req_server_url,key=req_key_txt)
projects = redmine.project.all()

print("Proyectos:")
for p in projects:
    print ("\t",p.identifier," \t| ",p.name)

my_project = redmine.project.get(pr_id_str)
print ("Obtenemos proyecto: ",my_project.identifier," | ",my_project.name)    

# get_ipython().run_line_magic('run', './RqConnectNList.ipynb')
tmp = redmine.issue.filter(project_id=pr_id_str, tracker_id=req_rq_tracker_id)
my_project_issues = sorted(tmp, key=lambda k: k.custom_fields.get(req_chapter_cf_id).value)
tmp = redmine.issue.filter(project_id=pr_id_str, tracker_id=req_doc_tracker_id)
my_doc_issues = sorted(tmp, key=lambda k: k.custom_fields.get(req_chapter_cf_id).value)

# Ahora recorremos el proyecto y sacamos los diagramas completos de jerarquía y dependencias, y guardamos los ficheros de esos diagramas en la carpeta doc.

# In[ ]:


from graphviz import Digraph

diagrams_str_prefix = "{{graphviz_link()\n"
diagrams_str_suffix = "\n}} "
diagrams_h_str = ""
diagrams_d_str = ""
cfdiag = redmine.custom_field.get(reqprj_diagrams_cf_id)
diagrams_pattern = cfdiag.default_value

path_root = img_path + "/" + my_project.identifier+"_"

for doc in my_doc_issues:
    prj_graph_parent = Digraph(name=path_root+"h", format='svg', graph_attr={'ratio':'compress','size':'9,5,30', 'margin':'0'}, engine='dot', node_attr={'shape':'record', 'style':'filled','URL':req_server_url})
    prj_graph = Digraph(name="clusterH", graph_attr={'labeljust':'l','labelloc':'t','label':'Hierarchy','margin':'5'}, engine='dot', node_attr={'shape':'record', 'style':'filled','URL':req_server_url})
    prj_graphb_parent = Digraph(name=path_root+"d", format='svg', graph_attr={'ratio':'compress','size':'9.5,30', 'margin':'0'}, engine='dot', node_attr={'shape':'record', 'style':'filled','URL':req_server_url})
    prj_graphb = Digraph(name="clusterD", graph_attr={'labeljust':'l','labelloc':'t','label':'Dependences','margin':'5'}, engine='dot', node_attr={'shape':'record', 'style':'filled','URL':req_server_url})
    for i in my_project_issues:
        title_str = i.custom_fields.get(req_title_cf_id).value
        print("title: ",title_str)
        nodelabel = "{"+i.subject+"|"+title_str+"}"
        prj_graph.node(str(i.id),nodelabel,URL=req_server_url+'/issues/'+str(i.id),tooltip=i.description)
        print(i.id,": ",i.subject)
        for child in i.children:
            prj_graph.edge(str(i.id),str(child.id))

        my_issue_relations = redmine.issue_relation.filter(issue_id=i.id)
        #print(len(my_issue_relations))
        my_filtered_issue_relations = list(filter(lambda x: x.issue_to_id != i.id, my_issue_relations))
        #print(len(my_filtered_issue_relations))
        if (len(my_issue_relations)>0):
            nodelabel = "{"+i.subject+"|"+title_str+"}"
            prj_graphb.node(str(i.id),nodelabel,URL=req_server_url+'/issues/'+str(i.id),tooltip=i.description)
            for r in my_filtered_issue_relations:
                related_element = redmine.issue.get(r.issue_to_id)
                print("related_element: ",related_element," : ",related_element.tracker)
                if (related_element.tracker.id == req_rq_tracker_id):
                    #print("\t"+r.relation_type+"\t"+str(r.issue_id)+"\t"+str(r.issue_to_id))
                    prj_graphb.edge(str(i.id),str(r.issue_to_id),color="blue")

    
    prj_graph_parent.subgraph(prj_graph)
    prj_graph_parent.render()
    prj_graphb_parent.subgraph(prj_graphb)
    prj_graphb_parent.render()
    
    print("project hierarchy diagram file: ",path_root+"h.gv.svg")
    print("project dependence diagram file: ",path_root+"d.gv.svg")
    
    diagrams_h_str = diagrams_str_prefix + str(prj_graph_parent) + diagrams_str_suffix
    diagrams_d_str = diagrams_str_prefix + str(prj_graphb_parent) + diagrams_str_suffix
    
    diagrams_str = diagrams_pattern.replace('$$h',diagrams_h_str)
    diagrams_str = diagrams_str.replace('$$d',diagrams_d_str)    
    redmine.project.update(resource_id=my_project.id,
                     custom_fields=[{'id': reqprj_diagrams_cf_id,'value': diagrams_str}]
                     )    
    
    print("Acabamos")


# Ahora vamos a generar los diagramas de jerarquía y de dependencia para cada una de los requisitos, y los guardaremos en la carpeta doc.

# In[ ]:


from lib.csysrq_support import *
import os

diagrams_h_str = ""
diagrams_d_str = ""

cfdiag = redmine.custom_field.get(req_diagrams_cf_id)
diagrams_pattern = cfdiag.default_value

# Generamos los diagramas correspondientes a los requisitos del proyecto
for my_issue in my_doc_issues+my_project_issues:
    print("\n\n---------- Diagrama ----------",my_issue)
    path_root = img_path + "/" + str(my_issue.id)+"_"
    target_issue_id = my_issue.id
    prj_graphc_parent = Digraph(name=path_root+"h", format='svg', graph_attr={'ratio':'compress','size':'9.5,30', 'margin':'0'}, engine='dot', node_attr={'shape':'record', 'style':'filled','URL':req_server_url})
    prj_graphc = Digraph(name="clusterH", graph_attr={'labeljust':'l','labelloc':'t','label':'Hierarchy','margin':'5'}, engine='dot', node_attr={'shape':'record', 'style':'filled','URL':req_server_url})
    target_issue = draw_descendants(redmine,req_server_url,target_issue_id,prj_graphc,req_title_cf_id)
    current_parent = getattr(target_issue, 'parent', None)
    if current_parent is not None:    
        draw_ancestors(redmine,req_server_url,target_issue.parent,target_issue_id,prj_graphc,req_title_cf_id)

    title_str = target_issue.custom_fields.get(req_title_cf_id).value
    nodelabel = "{"+target_issue.subject+"|"+title_str+"}"
    prj_graphc.node(str(target_issue.id),nodelabel,URL=req_server_url+'/issues/'+str(target_issue.id),color='green',tooltip=target_issue.description)
    prj_graphc_parent.subgraph(prj_graphc)
    prj_graphc_parent.render()
    symlink_path = img_path + "/" + my_issue.subject+"_"+"h.gv.svg"
    print("file: ",path_root+"h.gv.svg")
    print("symlink: ",symlink_path)
    if (os.path.islink(symlink_path)):
        os.remove(symlink_path)

    os.symlink(path_root+"h.gv.svg",symlink_path)    
    
    diagrams_h_str = diagrams_str_prefix + str(prj_graphc_parent) + diagrams_str_suffix

    prj_graphd_parent = Digraph(name=path_root+"d", format='svg', graph_attr={'ratio':'compress','size':'9.5,30', 'margin':'0'}, engine='dot', node_attr={'shape':'record', 'style':'filled','URL':req_server_url})
    prj_graphd = Digraph(name="clusterD", graph_attr={'labeljust':'l','labelloc':'t','label':'Dependences','margin':'5'}, engine='dot', node_attr={'shape':'record', 'style':'filled','URL':req_server_url})
    my_issue = draw_postpropagation(redmine,req_server_url,target_issue_id,prj_graphd,req_rq_tracker_id,req_title_cf_id)
    #if (my_issue.tracker.id == req_rq_tracker_id):
    if (True):
        draw_prepropagation(redmine,req_server_url,target_issue_id,prj_graphd,req_rq_tracker_id,req_title_cf_id)
        title_str = my_issue.custom_fields.get(req_title_cf_id).value     
        nodelabel = "{"+my_issue.subject+"|"+title_str+"}"
        prj_graphd.node(str(my_issue.id),nodelabel,URL=req_server_url+'/issues/'+str(my_issue.id),color='green',tooltip=my_issue.description)
        prj_graphd_parent.subgraph(prj_graphd)
        prj_graphd_parent.render()
        symlink_path = img_path + "/" + my_issue.subject+"_"+"d.gv.svg"
        print("file: ",path_root+"d.gv.svg")
        print("symlink: ",symlink_path)
        if (os.path.islink(symlink_path)):
            os.remove(symlink_path)
        
        os.symlink(path_root+"d.gv.svg",symlink_path)
        #diagrams_str += "\n\n## Dependence\n\n"+diagrams_str_prefix
        diagrams_d_str = diagrams_str_prefix + str(prj_graphd_parent) + diagrams_str_suffix


    diagrams_str = diagrams_pattern.replace('$$h',diagrams_h_str)
    diagrams_str = diagrams_str.replace('$$d',diagrams_d_str)
    redmine.issue.update(resource_id=my_issue.id,
                     custom_fields=[{'id': req_diagrams_cf_id,'value': diagrams_str}]
                     )
        
        
print("Acabamos")


# Vamos a grabar el fichero JSON intermedio para generar los reportes

# In[ ]:


import json

# Preparamos el fichero JSON que usaremos de puente para generar la documentación

data = {}
data['docs'] = []
data['issues'] = []

tmp = redmine.issue.filter(project_id=pr_id_str, tracker_id=req_doc_tracker_id)
my_project_docs = sorted(tmp, key=lambda k: k.subject)

for my_doc in my_project_docs:
    json_issue = {
            'id': my_doc.id,
            'subject': my_doc.subject,
            'description': my_doc.description,
            'title': my_doc.custom_fields.get(req_title_cf_id).value,
            'docprefix': my_doc.custom_fields.get(req_prefix_cf_id).value,
            'chapter': my_doc.custom_fields.get(req_chapter_cf_id).value,
    }
    data['docs'].append(json_issue)

for i in my_project_issues:
    my_issue = redmine.issue.get(i.id)
    s = getattr(my_issue, 'status', None)
    if s is not None:
        status_name = s.name
    v = getattr(my_issue, 'fixed_version', None)
    if v is not None:
        target_name = v.name
    else:
        target_name = None
        
    
    json_issue = {
            'id': my_issue.id,
            'subject': my_issue.subject,
            'description': my_issue.description,
            'title': my_issue.custom_fields.get(req_title_cf_id).value,
            'type': my_issue.custom_fields.get(req_type_cf_id).value,
            'level': my_issue.custom_fields.get(req_level_cf_id).value,
            'sources': my_issue.custom_fields.get(req_sources_cf_id).value,
            'rationale': my_issue.custom_fields.get(req_rationale_cf_id).value,
            'rq_value': my_issue.custom_fields.get(req_value_cf_id).value,
            'rq_var': my_issue.custom_fields.get(req_var_cf_id).value,
            'chapter': my_issue.custom_fields.get(req_chapter_cf_id).value,
            'target': target_name,
            'state': status_name,
            'url_h': "./img/"+my_issue.subject+"_h.gv.svg",
            'url_d': "./img/"+my_issue.subject+"_d.gv.svg"
    }
    data['issues'].append(json_issue)
    
    
    
with open(reporting_path + '/doc/reqs.json', 'w') as outfile:  
    json.dump(data, outfile)
    
print("Acabamos")


# Lanzamos la herramienta Carbone en Node, para generar los reportes de documentación.

# In[ ]:


from Naked.toolshed.shell import execute_js

# js_command = 'node ' + file_path + " " + arguments

success = execute_js('./plugins/cosmosys/assets/pythons/lib/launch_carbone.js',reporting_path)
print(success)

if success:
    # handle success of the JavaScript
    print("Todo fue bien")

else:
    # handle failure of the JavaScript
    print("todo fue mal")


# Vamos a generar el archivo JSON para crear el árbol

# In[ ]:


import json

# Preparamos el fichero JSON que usaremos para el árbol

def create_tree(current_issue):
    print("issue: " + current_issue.subject)
    tree_node = {'title': current_issue.custom_fields.get(req_chapter_cf_id).value + ": " + current_issue.subject + ": " + current_issue.custom_fields.get(req_title_cf_id).value,
             'subtitle': current_issue.description,
             'expanded': True,
             'children': [],
            }
    chlist = redmine.issue.filter(project_id=pr_id_str, parent_id=current_issue.id)
    childrenitems = sorted(chlist, key=lambda k: k.custom_fields.get(req_chapter_cf_id).value)
    for c in childrenitems:
        child_issue = redmine.issue.get(c.id)
        child_node = create_tree(child_issue)
        tree_node['children'].append(child_node)
        
    return tree_node

treedata = []
for i in my_project_docs:
    current_parent = getattr(i, 'parent', None)
    if (current_parent == None):
        tree_node = create_tree(i)
        treedata.append(tree_node)


#with open('./plugins/cosmosys/assets/pythons/reqtree/src/reqtreedata.json', 'w') as outfile:  
#    json.dump(treedata, outfile)


print("Acabamos")


# In[ ]:





#!/usr/bin/env python
# coding: utf-8

# In[ ]:

from cfg.configfile_req import req_key_txt

import sys
import json

def tree_to_list(tree):
    result = []
    for node in tree:
        print(node['subject'])
        node['status'] = data['statuses'][str(node['status_id'])]
        node['target'] = data['targets'][str(node['fixed_version_id'])]
        node['tracker'] = data['statuses'][str(node['fixed_version_id'])]
        node['doc'] = data['reqdocs'][str(node['doc_id'])]['subject']
        purgednode = node.copy()
        purgednode['children'] = []
        #print(purgednode)
        result.append(purgednode)
        result += tree_to_list(node['children'])

    return result

def propagate_dependence_up(node,firstdependable,currentdependable,server_url,dependents):
    nodelabel = "{" + node['subject'] + "|" + node['title'] + "}"
    diagrams[str(currentdependable)]['self_d'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'])
    print(node['id']," <- ",firstdependable," <- ... <- ",currentdependable)
    if currentdependable != firstdependable:
        # Tebenos que añadirnos al diagraa del precursor
        diagrams[str(currentdependable)]['self_d'].edge(str(firstdependable), str(node['id']),color="blue")

    print(dependents)
    if str(currentdependable) in dependents.keys():
        print("entro")
        for dep in dependents[str(currentdependable)]:
            propagate_dependence_up(node,firstdependable,dep,server_url,dependents)


def propagate_dependence_down(node,firstdependent,currentdependent,server_url,reqlist):
    # Buscanos el nodo actual
    print("***************",currentdependent,"*****************")
    print("***************",firstdependent,"*****************")
    for n in reqlist:
        if n['id'] == currentdependent:
            break

    print(n)

    if (firstdependent != currentdependent):
        print("***************","entro!","*****************")
        nodelabel = "{" + node['subject'] + "|" + node['title'] + "}"
        diagrams[str(currentdependent)]['self_d'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'])
        print(node['id']," -> ",firstdependent," ->...-> ",currentdependent)
        # Tebenos que añadirnos al diagraa del precursor
        diagrams[str(currentdependent)]['self_d'].edge(str(node['id']),str(firstdependent),color="blue")
        print("entro")
    
    for dep in n['relations']:
        propagate_dependence_down(node,firstdependent,dep['issue_to_id'],server_url,reqlist)


def generate_diagrams(node,diagrams,ancestors,server_url,dependents):

    # Añadimos las URLs de los graficos del nodo al propio nodo
    node['url_h'] = diagrams[str(node['id'])]['url_h']
    node['url_d'] = diagrams[str(node['id'])]['url_d']
    # Get current graph
    print(str(node['id']),node['subject'])
    # Dibujamos el nodo actual en los grafos generales
    nodelabel = "{" + node['subject'] + "|" + node['title'] + "}"
    diagrams['project']['self_h'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'])
    # Si tiene padre, pintaremos el vertice entre el padre y él
    if (len(ancestors)>0):
        parentreq = ancestors[0]
        diagrams['project']['self_h'].edge(str(parentreq['id']), str(node['id']))
    else:
        parentreq = None

    # Si este grafo tiene relaciones o ha sido marcado como dependiente, lo añadimos en el grafo geneal
    if str(node['id']) in dependents.keys():
        dependables = dependents[str(node['id'])]
        print(dependables)
    else:
        dependables = None

    if (len(node['relations']) > 0) or (dependables is not None):
        diagrams['project']['self_d'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'])
        # En caso de tratarse de un nodo dependiente, lo añadiremos a los diagramas de los nodos precursores
        if (dependables is not None):
            for pr in dependables:
                print("propago ",node['id'],": ",node['subject'])
                # Debemos también recorrer de manera arbórea todos aquellos nodos en la cadena de depndencia
                propagate_dependence_up(node,pr,pr,server_url,dependents)

    # Para cada relación
    for r in node['relations']:
        # añadiremos un eje en el grafo general
        diagrams['project']['self_d'].edge(str(node['id']), str(r['issue_to_id']), color="blue")
        # En el grafo del dependiente añadiremos el nodo como precursor
        diagrams[str(r['issue_to_id'])]['self_d'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'])
        diagrams[str(r['issue_to_id'])]['self_d'].edge(str(node['id']), str(r['issue_to_id']), color="blue")
        # En nuestro propio grafo añadiremos una arista hacia el nodo dependiente
        diagrams[str(node['id'])]['self_d'].edge(str(node['id']), str(r['issue_to_id']), color="blue")
        # marcaremos la relación como dependiente
        if str(r['issue_to_id']) not in dependents.keys():
            dependents[str(r['issue_to_id'])] = []

        dependents[str(r['issue_to_id'])].append(node['id'])
        # Ahora propagaremos el cambio hacia abajo para que en los diagramas de los dependientes
        # a más de un nivel aparezca el nodo actual y la dependencia con la relacion de primer 
        # nivel
        propagate_dependence_down(node,r['issue_to_id'],r['issue_to_id'],server_url,reqlist)


            


    # Ahora pintamos el camino de los ancestros en el grafo correspondiente al nodo actual
    desc = node
    graph = diagrams[str(node['id'])]['self_h']
    for anc in ancestors:
        # Dibujamos el nodo del ancestro y el link a sus descendiente en el grafo actual
        nodelabel = "{"+anc['subject']+"|"+anc['title']+"}"
        graph.node(str(anc['id']),nodelabel,URL=server_url+'/issues/'+str(anc['id']),tooltip=anc['description'])
        graph.edge(str(anc['id']),str(desc['id']))
        print("en el grafo de ",node['subject']," meto un ancestro",anc['subject']," como padre de ",desc['subject'])
        # Dibujamos el nodo actual en el grafo del ancestro, con un vínculo a su padre
        graphanc = diagrams[str(anc['id'])]['self_h']
        graphanc.node(str(node['id']),nodelabel,URL=server_url+'/issues/'+str(node['id']),tooltip=node['description'])
        if (parentreq is not None):
            graphanc.edge(str(parentreq['id']),str(node['id']))
            print("En el grafo de ",anc['subject']," meto un nodo descendiente ",node['subject'],"conectado con su padre ",parentreq['subject'])
        
        # El ancestro actual pasa a ser el descendiente del ancestro siguiente 
        desc = anc

    for child in node['children']:
        #if ((parentreq is None) or (child['doc_id']!=parentreq['doc_id'])):
            # Solo vamos a generar diagramas cuando bajemos desde el documento que los contiene,
            # Esto lo detectamos cuando el doc al que pertenece el hijo es diferente al que pertenece el padre
            generate_diagrams(child,diagrams,[node]+ancestors,server_url,dependents)


'''
    descr = getattr(my_issue, 'description', my_issue.subject)
    # https://stackoverflow.com/questions/37543513/read-the-null-value-in-python-redmine-api
    # Short answer: Use getattr(id, 'assigned_to', None) instead of id.assigned_to.
    current_parent = getattr(my_issue, 'parent', None)
    #print("my_issue: "+str(my_issue))
    if current_parent is not None:
        #print("parent: "+str(current_parent))
        draw_ancestors(redmine,server_url,current_parent,issue_id,graph,req_title_cf_id)

    return my_issue
'''


print ("This is the name of the script: ", sys.argv[0])
print ("Number of arguments: ", len(sys.argv))
print ("The arguments are: ", str(sys.argv))

#my_project['url'] = 'http://localhost:5555'           # The Redmine URL
#req_key_txt = 'd32df1cc535477adb95998fb4633bc50e8e664e3'    # The API key of the user (or bot) in which name the actions are undertaken.


# pr_id_str = req_project_id_str
pr_id_str = sys.argv[1]
print("id: ",pr_id_str)

# reporting_path = reporting_dir
reporting_path = sys.argv[2]
print("reporting_path: ",reporting_path)

# img_path = img_dir
img_path = sys.argv[3]
print("img_path: ",img_path)

import json,urllib.request
datafromurl = urllib.request.urlopen("http://localhost:5555/cosmosys_reqs/"+pr_id_str+".json?key="+req_key_txt).read()
data = json.loads(datafromurl)

my_project = data['project']

print ("Obtenemos proyecto: ", my_project['id'], " | ", my_project['name'])

reqdocs = data['reqdocs']
reqs = data['reqs']
targets = data['targets']
statuses = data['statuses']

# Ahora vamos a generar los diagramas de jerarquía y de dependencia para cada una de los requisitos, y los guardaremos en la carpeta doc.
print("len(reqs)",len(reqs))
# Debemos preparar un diagrama para cada nodo
reqlist = tree_to_list(reqs)
data['reqlist'] = reqlist

data['reqclean'] = []

for r in reqlist:
    if 'type' in r.keys():
        if r['type'] != 'Info':
            data['reqclean'].append(r)


print("len(reqlist)",len(reqlist))

# Ahora recorremos el proyecto y sacamos los diagramas completos de jerarquía y dependencias, y guardamos los ficheros de esos diagramas en la carpeta doc.

# In[ ]:
diagrams = {}

from graphviz import Digraph

path_root = img_path + "/" + my_project['identifier'] + "_"

parent_g_h = Digraph(name=path_root + "h", format='svg',
                           graph_attr={'ratio': 'compress', 'size': '9,5,30', 'margin': '0'}, engine='dot',
                           node_attr={'shape': 'record', 'style': 'filled', 'URL': my_project['url']})
self_g_h = Digraph(name="clusterH",
                    graph_attr={'labeljust': 'l', 'labelloc': 't', 'label': 'Hierarchy', 'margin': '5'}, engine='dot',
                    node_attr={'shape': 'record', 'style': 'filled', 'URL': my_project['url']})
parent_g_d = Digraph(name=path_root + "d", format='svg',
                            graph_attr={'ratio': 'compress', 'size': '9.5,30', 'margin': '0'}, engine='dot',
                            node_attr={'shape': 'record', 'style': 'filled', 'URL': my_project['url']})
self_g_d = Digraph(name="clusterD",
                     graph_attr={'labeljust': 'l', 'labelloc': 't', 'label': 'Dependences', 'margin': '5'},
                     engine='dot', node_attr={'shape': 'record', 'style': 'filled', 'URL': my_project['url']})

url_base = "./img/" + my_project['identifier'] + "_"
url_sufix = ".gv.svg"
url_h = url_base +"h"+url_sufix
url_d = url_base +"h"+url_sufix
my_project['url_h'] = url_h
my_project['url_d'] = url_d
diagrams['project'] = {'url_h':url_h, 'url_d':url_d, 'parent_h': parent_g_h, 'self_h': self_g_h, 'parent_d': parent_g_d, 'self_d': self_g_d, }

from lib.csysrq_support import *
import os

#print(reqlist)
# Generamos los diagramas correspondientes a los requisitos del proyecto
for my_issue in reqlist:
    print("\n\n---------- Diagrama ----------", my_issue['subject'])
    path_root = img_path + "/" + str(my_issue['id']) + "_"

    parent_h = Digraph(name=path_root + "h", format='svg',
                                graph_attr={'ratio': 'compress', 'size': '9.5,30', 'margin': '0'}, engine='dot',
                                node_attr={'shape': 'record', 'style': 'filled', 'URL': my_project['url']})

    self_h = Digraph(name="clusterH",
                         graph_attr={'labeljust': 'l', 'labelloc': 't', 'label': 'Hierarchy', 'margin': '5'},
                         engine='dot', node_attr={'shape': 'record', 'style': 'filled', 'URL': my_project['url']})
    
    parent_d = Digraph(name=path_root + "d", format='svg',
                                graph_attr={'ratio': 'compress', 'size': '9.5,30', 'margin': '0'}, engine='dot',
                                node_attr={'shape': 'record', 'style': 'filled', 'URL': my_project['url']})
    self_d = Digraph(name="clusterD",
                         graph_attr={'labeljust': 'l', 'labelloc': 't', 'label': 'Dependences', 'margin': '5'},
                         engine='dot', node_attr={'shape': 'record', 'style': 'filled', 'URL': my_project['url']})
    url_base = "./img/" + str(my_issue['id']) + "_"
    url_sufix = ".gv.svg"
    url_h = url_base +"h"+url_sufix
    url_d = url_base +"h"+url_sufix
    my_issue['url_h'] = url_h
    my_issue['url_d'] = url_d

    # Pinto cada nodo en su diagrama
    print("Creo los diagrama con id ",my_issue['id'])
    diagrams[str(my_issue['id'])] = {'url_h':url_h, 'url_d':url_d, 'parent_h': parent_h, 'self_h': self_h, 'parent_d': parent_d, 'self_d': self_d, }

    nodelabel = "{" + my_issue['subject'] + "|" + my_issue['title'] + "}"
    self_h.node(str(my_issue['id']), nodelabel, URL=my_project['url'] + '/issues/' + str(my_issue['id']),
                    color='green', tooltip=my_issue['description'])
    
    '''
    my_issue = draw_postpropagation(redmine, my_project['url'], my_issue['id'], prj_graphd, req_rq_tracker_id,
                                    req_title_cf_id)

    draw_prepropagation(redmine, my_project['url'], my_issue['id'], prj_graphd, req_rq_tracker_id, req_title_cf_id)
    '''

    title_str = my_issue['title']
    nodelabel = "{" + my_issue['subject'] + "|" + title_str + "}"
    self_d.node(str(my_issue['id']), nodelabel, URL=my_project['url'] + '/issues/' + str(my_issue['id']), color='green',
                    tooltip=my_issue['description'])

# Ahora recorrere todo el arbol rellenando los nodos en cada diagrama

#print(diagrams)

for rq in reqs:
    generate_diagrams(rq,diagrams,[],my_project['url'],{})
    #-----------------------------

    '''
    target_issue = draw_descendants(redmine, my_project['url'], my_issue['id'], prj_graphc, req_title_cf_id)
    current_parent = getattr(target_issue, 'parent', None)
    if current_parent is not None:
        draw_ancestors(redmine, my_project['url'], target_issue.parent, my_issue['id'], prj_graphc, req_title_cf_id)

    '''

    #-----------------------------
for my_issue in reqlist:
    prj_graphc_parent = diagrams[str(my_issue['id'])]['parent_h']
    prj_graphc = diagrams[str(my_issue['id'])]['self_h']
    prj_graphc_parent.subgraph(prj_graphc)
    prj_graphc_parent.render()
    '''
    symlink_path = img_path + "/" + my_issue['subject'] + "_" + "h.gv.svg"
    print("file: ", path_root + "h.gv.svg")
    print("symlink: ", symlink_path)
    if (os.path.islink(symlink_path)):
        os.remove(symlink_path)

    os.symlink(path_root + "h.gv.svg", symlink_path)
    '''

    prj_graphd_parent = diagrams[str(my_issue['id'])]['parent_d']
    prj_graphd = diagrams[str(my_issue['id'])]['self_d']
    prj_graphd_parent.subgraph(prj_graphd)
    prj_graphd_parent.render()

    '''
    symlink_path = img_path + "/" + my_issue['subject'] + "_" + "d.gv.svg"
    print("file: ", path_root + "d.gv.svg")
    print("symlink: ", symlink_path)
    if (os.path.islink(symlink_path)):
        os.remove(symlink_path)

    os.symlink(path_root + "d.gv.svg", symlink_path)
    '''

parent_g_h.subgraph(self_g_h)
parent_g_h.render()
parent_g_d.subgraph(self_g_d)
parent_g_d.render()

print("project hierarchy diagram file: ", path_root + "h.gv.svg")
print("project dependence diagram file: ", path_root + "d.gv.svg")

print("Acabamos")

# Vamos a grabar el fichero JSON intermedio para generar los reportes

# In[ ]:


import json

# Preparamos el fichero JSON que usaremos de puente para generar la documentación

with open(reporting_path + '/doc/reqs.json', 'w') as outfile:
    json.dump(data, outfile)

print("Acabamos")

# Lanzamos la herramienta Carbone en Node, para generar los reportes de documentación.

# In[ ]:


from Naked.toolshed.shell import execute_js

# js_command = 'node ' + file_path + " " + arguments
print(reqdocs.keys())
for doc in reqdocs.keys():
    print(reqdocs[doc])
    success = execute_js('./plugins/cosmosys_req/assets/pythons/lib/launch_carbone.js', reporting_path+" "+str(reqdocs[doc]['id'])+" "+reqdocs[doc]['subject'])
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
    #print("issue: " + current_issue['subject'])
    descr = getattr(current_issue, 'description', current_issue['subject'])
    tree_node = {'title': current_issue.custom_fields.get(
        req_chapter_cf_id).value + ": " + current_issue['subject'] + ": " + current_issue.custom_fields.get(
        req_title_cf_id).value,
                 'subtitle': descr,
                 'expanded': True,
                 'children': [],
                 }
    chlist = redmine.issue.filter(project_id=pr_id_str, parent_id=current_issue['id'], status_id='*')
    childrenitems = sorted(chlist, key=lambda k: k['chapter'])
    for c in childrenitems:
        child_issue = redmine.issue.get(c['id'])
        child_node = create_tree(child_issue)
        tree_node['children'].append(child_node)

    return tree_node


print("Acabamos")

# In[ ]:

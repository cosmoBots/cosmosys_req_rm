#!/usr/bin/env python
# coding: utf-8

# In[ ]:

from cfg.configfile_req import req_key_txt

import sys
import json

def tree_to_list(tree,parentNode):
    result = []
    #print("\n\n\n******ARBOL******* len= ",len(tree))
    for node in tree:
        node['chapters'] = []
        node['reqs'] = []
        #print("\n\n\n******NODO*******",node['id'])
        if (node['id']) == (node['doc_id']):
            #print("\n\n\n******DOCUMENTO*******",node['id'])
            # Nos encontramos en un documento, vamos a "enriquecer" el nodo de reqdocs 
            # con la información de "children" para que el generador de informes pueda 
            # partir de los documentos en forma de árbol
            data['reqdocs'][str(node['doc_id'])]['children'] = node['children']
            data['reqdocs'][str(node['doc_id'])]['chapters'] = []
            data['reqdocs'][str(node['doc_id'])]['reqs'] = []

        if 'type' in node.keys():
            if (node['type'] == "Info"):
                # Nos encontramos en un nodo del tipo informacion, para el que no vamos a 
                # querer, posiblemente, generar tablas de atributos.  Para que Carbone
                # pueda filtrar facilmente este tipo de datos, le anyadiremos la propiedad
                # infoType = 1.
                node['infoType'] = 1
                if (parentNode != None):
                    parentNode['chapters'].append(node)
                    if (parentNode['id'] == parentNode['doc_id']):
                        data['reqdocs'][str(node['doc_id'])]['chapters'].append(node)
            else:
                node['infoType'] = 0
                if (parentNode != None):
                    parentNode['reqs'].append(node)
                    if (parentNode['id'] == parentNode['doc_id']):
                        data['reqdocs'][str(node['doc_id'])]['reqs'].append(node)

        else:
            node['infoType'] = 0
            if (parentNode != None):
                parentNode['reqs'].append(node)
                if (parentNode['id'] == parentNode['doc_id']):
                    data['reqdocs'][str(node['doc_id'])]['reqs'].append(node)


        #print(node['subject'])
        node['status'] = data['statuses'][str(node['status_id'])]
        if 'fixed_version_id' in node.keys():
            if (node['fixed_version_id'] is not None):
                node['target'] = data['targets'][str(node['fixed_version_id'])]

        node['tracker'] = data['trackers'][str(node['tracker_id'])]
        node['doc'] = data['reqdocs'][str(node['doc_id'])]['subject']
        purgednode = node.copy()
        purgednode['children'] = []

        # Rellenamos la tabla de dependencias inversa, para que 
        # los nodos encuentren aquellos de los que dependen
        for r in node['relations']:
            if str(r['issue_to_id']) not in data['dependents'].keys():
                data['dependents'][str(r['issue_to_id'])] = []

            data['dependents'][str(r['issue_to_id'])].append(node['id'])     

        #print(purgednode)
        result.append(purgednode)
        result += tree_to_list(node['children'],node)

    return result

def propagate_dependence_up(node,firstdependable,currentdependable,server_url,dependents):
    if (node['valid']):
        colorstr = "black"
    else:
        colorstr = "red"

    if node['doc_id'] == node['id']:
        nodelabel = node['subject'] + "\n----\n" + node['title']
        diagrams[str(currentdependable)]['self_d'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'], fillcolor='grey', color=colorstr, shape="note")
    else:
        nodelabel = "{" + node['subject'] + "|" + node['title'] + "}"
        diagrams[str(currentdependable)]['self_d'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'], fillcolor='grey', color=colorstr)

    #print("Up: ",node['id']," <- ",firstdependable," <- ... <- ",currentdependable)
    if currentdependable != firstdependable:
        # Tebenos que añadirnos al diagraa del precursor
        diagrams[str(currentdependable)]['self_d'].edge(str(firstdependable), str(node['id']),color="blue")

    #print(dependents)
    if str(currentdependable) in dependents.keys():
        #print("entro")
        for dep in dependents[str(currentdependable)]:
            propagate_dependence_up(node,firstdependable,dep,server_url,dependents)


def propagate_dependence_down(node,firstdependent,currentdependent,server_url,reqlist):
    # Buscanos el nodo actual
    #print("Down: ",node['id']," -> ",firstdependent," -> ... -> ",currentdependent)
    for n in reqlist:
        if n['id'] == currentdependent:
            break

    #print(n)

    if (firstdependent != currentdependent):
        if (node['valid']):
            colorstr = "black"
        else:
            colorstr = "red"

        #print("***************","entro!","*****************")
        if node['doc_id'] == node['id']:
            nodelabel = node['subject'] + "\n----\n" + node['title']
            diagrams[str(currentdependent)]['self_d'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'], fillcolor='grey',color=colorstr, shape="note")
        else:
            nodelabel = "{" + node['subject'] + "|" + node['title'] + "}"
            diagrams[str(currentdependent)]['self_d'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'], fillcolor='grey',color=colorstr)

        #print(node['id']," -> ",firstdependent," ->...-> ",currentdependent)
        # Tebenos que añadirnos al diagraa del precursor
        diagrams[str(currentdependent)]['self_d'].edge(str(node['id']),str(firstdependent),color="blue")
        #print("entro")
    
    for dep in n['relations']:
        propagate_dependence_down(node,firstdependent,dep['issue_to_id'],server_url,reqlist)


def generate_diagrams(node,diagrams,ancestors,server_url,dependents):

    # Añadimos las URLs de los graficos del nodo al propio nodo
    node['url_h'] = diagrams[str(node['id'])]['url_h']
    node['url_d'] = diagrams[str(node['id'])]['url_d']
    # Get current graph
    #print(str(node['id']),node['subject'])
    # Dibujamos el nodo actual en los grafos generales
    if (node['valid']):
        colorstr = "black"
    else:
        colorstr = "red"

    if node['doc_id'] == node['id']:
        nodelabel = node['subject'] + "\n----\n" + node['title']
        diagrams['project']['self_h'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'], fillcolor='grey',color=colorstr, shape="note")
    else:
        nodelabel = "{" + node['subject'] + "|" + node['title'] + "}"
        diagrams['project']['self_h'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'], fillcolor='grey',color=colorstr)

    # Si tiene padre, pintaremos el vertice entre el padre y él
    if (len(ancestors)>0):
        parentreq = ancestors[0]
        diagrams['project']['self_h'].edge(str(parentreq['id']), str(node['id']))
    else:
        parentreq = None

    # Si este nodo tiene relaciones o ha sido marcado como dependiente, lo añadimos en el grafo geneal
    if str(node['id']) in dependents.keys():
        dependables = dependents[str(node['id'])]
        #print(dependables)
    else:
        dependables = None

    if (len(node['relations']) > 0) or (dependables is not None):
        if (node['valid']):
            colorstr = "black"
        else:
            colorstr = "red"

        if node['doc_id'] == node['id']:
            diagrams['project']['self_d'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'], shape="note", fillcolor='grey', color=colorstr)
        else:
            diagrams['project']['self_d'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'], fillcolor='grey', color=colorstr)

        # En caso de tratarse de un nodo dependiente, lo añadiremos a los diagramas de los nodos precursores
        #print("Relaciones tiene")
        if (dependables is not None):
            for pr in dependables:
                #print("propago ",node['id'],": ",node['subject'])
                # Debemos también recorrer de manera arbórea todos aquellos nodos en la cadena de depndencia
                propagate_dependence_up(node,pr,pr,server_url,dependents)

    # Para cada relación
    for r in node['relations']:
        # añadiremos un eje en el grafo general
        diagrams['project']['self_d'].edge(str(node['id']), str(r['issue_to_id']), color="blue")
        # En el grafo del dependiente añadiremos el nodo como precursor
        if (node['valid']):
            colorstr = "black"
        else:
            colorstr = "red"

        if node['doc_id'] == node['id']:
            diagrams[str(r['issue_to_id'])]['self_d'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'], fillcolor='grey', color=colorstr, shape="note")
        else:
            diagrams[str(r['issue_to_id'])]['self_d'].node(str(node['id']), nodelabel, URL=server_url+'/issues/'+str(node['id']), tooltip=node['description'], fillcolor='grey', color=colorstr)

        diagrams[str(r['issue_to_id'])]['self_d'].edge(str(node['id']), str(r['issue_to_id']), color="blue")
        # En nuestro propio grafo añadiremos una arista hacia el nodo dependiente
        diagrams[str(node['id'])]['self_d'].edge(str(node['id']), str(r['issue_to_id']), color="blue")

        # Ahora propagaremos el cambio hacia abajo para que en los diagramas de los dependientes
        # a más de un nivel aparezca el nodo actual y la dependencia con la relacion de primer 
        # nivel
        propagate_dependence_down(node,r['issue_to_id'],r['issue_to_id'],server_url,reqlist)


    # Ahora pintamos el camino de los ancestros en el grafo correspondiente al nodo actual
    desc = node
    graph = diagrams[str(node['id'])]['self_h']
    for anc in ancestors:
        # Dibujamos el nodo del ancestro y el link a sus descendiente en el grafo actual
        if (anc['valid']):
            colorstr = "black"
        else:
            colorstr = "red"

        if anc['doc_id'] == anc['id']:
            nodelabel = anc['subject']+"\n----\n"+anc['title']
            graph.node(str(anc['id']),nodelabel,URL=server_url+'/issues/'+str(anc['id']),tooltip=anc['description'], fillcolor='grey', color=colorstr, shape="note")
        else:
            nodelabel = "{"+anc['subject']+"|"+anc['title']+"}"
            graph.node(str(anc['id']),nodelabel,URL=server_url+'/issues/'+str(anc['id']),tooltip=anc['description'], fillcolor='grey', color=colorstr)

        graph.edge(str(anc['id']),str(desc['id']))
        #print("en el grafo de ",node['subject']," meto un ancestro",anc['subject']," como padre de ",desc['subject'])
        # Dibujamos el nodo actual en el grafo del ancestro, con un vínculo a su padre
        graphanc = diagrams[str(anc['id'])]['self_h']

        if (node['valid']):
            colorstr = "black"
        else:
            colorstr = "red"

        if node['doc_id'] == node['id']:
            nodelabel = node['subject'] + "\n----\n" + node['title']
            graphanc.node(str(node['id']),nodelabel,URL=server_url+'/issues/'+str(node['id']),tooltip=node['description'], fillcolor='grey', color=colorstr, shape="note")
        else:
            nodelabel = "{" + node['subject'] + "|" + node['title'] + "}"
            graphanc.node(str(node['id']),nodelabel,URL=server_url+'/issues/'+str(node['id']),tooltip=node['description'], fillcolor='grey', color=colorstr)


        if (parentreq is not None):
            graphanc.edge(str(parentreq['id']),str(node['id']))
            #print("En el grafo de ",anc['subject']," meto un nodo descendiente ",node['subject'],"conectado con su padre ",parentreq['subject'])
        
        # El ancestro actual pasa a ser el descendiente del ancestro siguiente 
        desc = anc

    for child in node['children']:
        #if ((parentreq is None) or (child['doc_id']!=parentreq['doc_id'])):
            # Solo vamos a generar diagramas cuando bajemos desde el documento que los contiene,
            # Esto lo detectamos cuando el doc al que pertenece el hijo es diferente al que pertenece el padre
            generate_diagrams(child,diagrams,[node]+ancestors,server_url,dependents)


#print ("This is the name of the script: ", sys.argv[0])
#print ("Number of arguments: ", len(sys.argv))
#print ("The arguments are: ", str(sys.argv))

#my_project['url'] = 'http://localhost:5555'           # The Redmine URL
#req_key_txt = 'd32df1cc535477adb95998fb4633bc50e8e664e3'    # The API key of the user (or bot) in which name the actions are undertaken.


# pr_id_str = req_project_id_str
pr_id_str = sys.argv[1]
#print("id: ",pr_id_str)

# reporting_path = reporting_dir
reporting_path = sys.argv[2]
#print("reporting_path: ",reporting_path)

# img_path = img_dir
img_path = sys.argv[3]
#print("img_path: ",img_path)

# root_url = req_server_url
root_url = sys.argv[4]
#print("root_url: ",root_url)

tmpfilepath = None
if (len(sys.argv) > 5):
    # tmpfilepath
    tmpfilepath = sys.argv[5]
    #print("tmpfilepath: ",tmpfilepath)

if (tmpfilepath is None):
    import json,urllib.request
    urlfordata = root_url+"/cosmosys_reqs/"+pr_id_str+".json?key="+req_key_txt
    #print("urlfordata: ",urlfordata)
    datafromurl = urllib.request.urlopen(urlfordata).read().decode('utf-8')
    data = json.loads(datafromurl)

else:
    import json
    with open(tmpfilepath, 'r', encoding="utf-8") as tmpfile:
        data = json.load(tmpfile)


my_project = data['project']

#print ("Obtenemos proyecto: ", my_project['id'], " | ", my_project['name'])

reqdocs = data['reqdocs']
reqs = data['reqs']
targets = data['targets']
statuses = data['statuses']
# Ahora vamos a generar los diagramas de jerarquía y de dependencia para cada una de los requisitos, y los guardaremos en la carpeta doc.
#print("len(reqs)",len(reqs))
# Debemos preparar un diagrama para cada nodo
#print("#####Vamos con los documentos!!!!")
data['dependents'] = {}
reqlist = tree_to_list(reqs,None)
data['reqlist'] = reqlist

data['reqclean'] = []

for r in reqlist:
    if 'type' in r.keys():
        if r['type'] != 'Info':
            data['reqclean'].append(r)


#print("len(reqlist)",len(reqlist))

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

url_base = root_url+"/projects/"+pr_id_str+"/repository/rq/revisions/master/raw/reporting/doc/"+"./img/" + my_project['identifier'] + "_"
url_sufix = ".gv.svg"
url_h = url_base +"h"+url_sufix
url_d = url_base +"h"+url_sufix
my_project['url_h'] = url_h
my_project['url_d'] = url_d
diagrams['project'] = {'url_h':url_h, 'url_d':url_d, 'parent_h': parent_g_h, 'self_h': self_g_h, 'parent_d': parent_g_d, 'self_d': self_g_d, }

import os

#print(reqlist)
# Generamos los diagramas correspondientes a los requisitos del proyecto
for my_issue in reqlist:
    #print("\n\n---------- Diagrama ----------", my_issue['subject'])
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
    url_base = root_url+"/projects/"+pr_id_str+"/repository/rq/revisions/master/raw/reporting/doc/"+"./img/" + str(my_issue['id']) + "_"
    url_sufix = ".gv.svg"
    url_h = url_base +"h"+url_sufix
    url_d = url_base +"h"+url_sufix
    my_issue['url_h'] = url_h
    my_issue['url_d'] = url_d

    # Pinto cada nodo en su diagrama
    #print("Creo los diagrama con id ",my_issue['id'])
    diagrams[str(my_issue['id'])] = {'url_h':url_h, 'url_d':url_d, 'parent_h': parent_h, 'self_h': self_h, 'parent_d': parent_d, 'self_d': self_d, }

    if (my_issue['valid']):
        colorstr = "black"
    else:
        colorstr = "red"

    if my_issue['doc_id'] == my_issue['id']:
        nodelabel = my_issue['subject'] + "\n----\n" + my_issue['title']
        self_h.node(str(my_issue['id']), nodelabel, URL=my_project['url'] + '/issues/' + str(my_issue['id']),
                        fillcolor='green', tooltip=my_issue['description'], color=colorstr, shape = "note")
    else:
        nodelabel = "{" + my_issue['subject'] + "|" + my_issue['title'] + "}"
        self_h.node(str(my_issue['id']), nodelabel, URL=my_project['url'] + '/issues/' + str(my_issue['id']),
                        fillcolor='green', tooltip=my_issue['description'], color=colorstr)
    

    title_str = my_issue['title']

    if my_issue['doc_id'] == my_issue['id']:
        nodelabel = my_issue['subject'] + "\n----\n" + title_str
        self_d.node(str(my_issue['id']), nodelabel, URL=my_project['url'] + '/issues/' + str(my_issue['id']), fillcolor='green',
                        tooltip=my_issue['description'], color=colorstr, shape = "note")
    else:
        nodelabel = "{" + my_issue['subject'] + "|" + title_str + "}"
        self_d.node(str(my_issue['id']), nodelabel, URL=my_project['url'] + '/issues/' + str(my_issue['id']), fillcolor='green',
                        tooltip=my_issue['description'], color=colorstr)


# Ahora recorrere todo el arbol rellenando los nodos en cada diagrama

#print(diagrams)

for rq in reqs:
    generate_diagrams(rq,diagrams,[],my_project['url'],data['dependents'])


for my_issue in reqlist:
    prj_graphc_parent = diagrams[str(my_issue['id'])]['parent_h']
    prj_graphc = diagrams[str(my_issue['id'])]['self_h']
    prj_graphc_parent.subgraph(prj_graphc)
    prj_graphc_parent.render()
    '''
    symlink_path = img_path + "/" + my_issue['subject'] + "_" + "h.gv.svg"
    #print("file: ", path_root + "h.gv.svg")
    #print("symlink: ", symlink_path)
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
    #print("file: ", path_root + "d.gv.svg")
    #print("symlink: ", symlink_path)
    if (os.path.islink(symlink_path)):
        os.remove(symlink_path)

    os.symlink(path_root + "d.gv.svg", symlink_path)
    '''

parent_g_h.subgraph(self_g_h)
parent_g_h.render()
parent_g_d.subgraph(self_g_d)
parent_g_d.render()

#print("project hierarchy diagram file: ", path_root + "h.gv.svg")
#print("project dependence diagram file: ", path_root + "d.gv.svg")

#print("Acabamos")

# Vamos a grabar el fichero JSON intermedio para generar los reportes

# In[ ]:


datadoc = data

import json

# Preparamos el fichero JSON que usaremos de puente para generar la documentación

with open(reporting_path + '/doc/reqs.json', 'w') as outfile:
    json.dump(datadoc, outfile)

#print("Acabamos")

# Lanzamos la herramienta Carbone en Node, para generar los reportes de documentación.

# In[ ]:


from Naked.toolshed.shell import execute_js

# js_command = 'node ' + file_path + " " + arguments
#print(reqdocs.keys())
for doc in reqdocs.keys():
    #print(reqdocs[doc])
    success = execute_js('./plugins/cosmosys_req/assets/pythons/lib/launch_carbone.js', reporting_path+" "+str(reqdocs[doc]['id'])+" "+reqdocs[doc]['subject'])
    #print(success)

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


#print("Acabamos")

# In[ ]:

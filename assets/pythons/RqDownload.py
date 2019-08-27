#!/usr/bin/env python
# coding: utf-8

from cfg.configfile_req import *
#from redminelib import Redmine

import sys
#print("This is the name of the script: ", sys.argv[0])
#print("Number of arguments: ", len(sys.argv))
#print("The arguments are: " , str(sys.argv))

#print(req_server_url)
#print(req_key_txt)

def tree_to_dict_list(tree,parentNode):
    result = {}
    result2 = []
    result3 = []
    #print("\n\n\n******ARBOL******* len= ",len(tree))
    for node in tree:
        node['chapters'] = []
        node['reqs'] = []
        #print("\n\n\n******NODO*******",node['id'])
        if (node['id']) == (node['doc_id']):
            result3.append(node)
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
        #print(purgednode)
        result[str(purgednode['id'])] = purgednode
        result2.append(purgednode)
        r,r2,r3 = tree_to_dict_list(node['children'],node)
        result.update(r)
        result2 += r2
        result3 += r3

    return result,result2,result3



# pr_id_str = req_project_id_str
pr_id_str = sys.argv[1]
#print("id: ",pr_id_str)

# reporting_path = reporting_dir
download_filepath = sys.argv[2]
#print("download_filepath: ",download_filepath)

# root_url = req_server_url
root_url = sys.argv[3]
#print("root_url: ",root_url)

# tmpfilepath
tmpfilepath = sys.argv[4]
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
reqdict,reqlist,my_doc_issues = tree_to_dict_list(reqs,None)
#print("ACABAMOS!!!!!!!!!!!!!!!!!!!!!!!!!!!")

# Conectaremos con nuestra instancia de PYOO
# https://github.com/seznam/pyoo

# In[ ]:


import pyoo
desktop = pyoo.Desktop('localhost', 2002)


# Copiamos el template del fichero de exportación al nombre de exportación

# In[ ]:


from shutil import copyfile

copyfile('./plugins/cosmosys_req/assets/pythons/templates/RqDownload.ods', download_filepath)


# Hemos de cargar los RqTarget

# In[ ]:


# Conectamos con la hoja
doc = desktop.open_spreadsheet(download_filepath)

# La lista de RqTarget empieza en B7, hacia abajo
rq_target_column = 2
rq_target_row = 8


# In[ ]:


#print(dir(doc))
#print(len(doc.sheets))
doc_dict = doc.sheets['Dict']
#print(doc_dict)
#print(doc_dict[rq_target_row,rq_target_column].address)
#doc_dict[rq_target_row,rq_target_column].value = 5


# In[ ]:
#print("ACABAMOS2!!!!!!!!!!!!!!!!!!!!!!!!!!!")

doc_dict[req_download_url_row,req_download_url_column].value = req_server_url+'/'
rowindex = req_upload_version_startrow

#print("ACABAMOS3!!!!!!!!!!!!!!!!!!!!!!!!!!")
for v in targets:
    #print(v)
    doc_dict[rowindex,req_upload_version_column].value = targets[v]
    rowindex += 1

#print("ACABAMOS4!!!!!!!!!!!!!!!!!!!!!!!!!!!")
# Ahora generaremos los documentos a partir de los reqdoc

# In[ ]:


tabnumber = 3
for my_issue in my_doc_issues:
    #print("********** ",my_issue['subject'])
    prefix = my_issue['prefix']
    mysheet = doc.sheets.copy('Template', my_issue['subject'], tabnumber)
    tabnumber += 1
    mysheet[req_download_doc_row,req_download_doc_name_column].value = my_issue['description']
    mysheet[req_download_doc_row,req_download_doc_prefix_column].value = prefix
    current_parent = my_issue['parent_id']
    if current_parent is not None:
        parent_issue = reqdocs[str(current_parent)]
        #print("parent: ",parent_issue.subject)
        # Rellenamos la celda del padre
        mysheet[req_download_doc_row,req_download_doc_parent_column].value = parent_issue['subject']
    
    current_version = my_issue['fixed_version_id']
          
# Ahora crearemos los requisitos "hijos" dentro de cada documento

# In[ ]:


def find_doc(this_issue):
    #print("find_doc: ",this_issue)
    if this_issue['tracker'] == 'ReqDoc':
        #print("retorno this", this_issue.subject)
        return this_issue['subject'],this_issue['prefix'] 

    # not do found yet
    current_parent = this_issue['parent_id']
    if current_parent is None:
        #print("retorno none")
        return "",""
    
    else:
        parent_issue = reqdict[str(current_parent)]
        #print("Llamo al padre")
        return find_doc(parent_issue)
    
current_row = {}
for my_issue in my_doc_issues:
    current_row[my_issue['subject']] = req_upload_first_row
    

#print(current_row)
#print(len(reqlist))
for my_issue in reqlist:
    if my_issue['tracker'] == 'Req':
        reqname = my_issue['subject']
        #print("reqname: ",reqname)
        current_parent = my_issue['parent_id']
        if current_parent is not None:
            #print("current_parent 1: ",current_parent)
            parent_issue = reqdict[str(current_parent)]
            if parent_issue['tracker'] != 'Req':
                current_parent = None
            #else:
                #print("parent: ",parent_issue['subject'])
        
        thisdoc,thisprefix = find_doc(parent_issue)
        #print("thisdoc:",thisdoc)
        #print("thisprefix:",thisprefix)
        thistab = doc.sheets[thisdoc]
        currrow = current_row[thisdoc]
        #print("add the req to the row ",currrow," of the tab ",thistab)
        if 'target' in my_issue.keys():
            current_version = my_issue['target']
        else:
            current_version = None
        idstr = my_issue['subject'].replace(thisprefix,'')

        thistab[currrow,req_upload_id_column].value = my_issue['subject']
        thistab[currrow,req_upload_title_column].value = my_issue['title']
        descr = my_issue['description']
        if descr is None:
            descr = ""
        thistab[currrow,req_upload_descr_column].value = descr
        sources = my_issue['sources']
        #print("*********************************************** SOURCES ")
        #print(sources)
        if sources is None:
            sources = ""
        thistab[currrow,req_upload_source_column].value = sources
        typestr = my_issue['type']
        if typestr is None:
            typestr = ""
        thistab[currrow,req_upload_type_column].value = typestr
        level = my_issue['level']
        if level is None:
            level = ""
        thistab[currrow,req_upload_level_column].value = level
        rationale = my_issue['rationale']
        if rationale is None:
            rationale = ""
        thistab[currrow,req_upload_rationale_column].value = rationale
        var = my_issue['var']
        if var is None:
            var = ""
        thistab[currrow,req_upload_var_column].value = var
        value = my_issue['value']
        if value is None:
            value = ""        
        thistab[currrow,req_upload_value_column].value = value
        thistab[currrow,req_upload_chapter_column].value = my_issue['chapter'].replace(thisprefix,'')
        thistab[currrow,req_upload_status_column].value = my_issue['status']
        thistab[currrow,req_download_rqid_column].value = my_issue['id']
        thistab[currrow,req_download_bdid_column].value = int(idstr)
        
        if (current_version is not None):
            thistab[currrow,req_upload_target_column].value = current_version

        if current_parent is not None:
            thistab[currrow,req_upload_parent_column].value = parent_issue['subject']

            
        # Busco las relaciones en las que es destinatario
        my_filtered_issue_relations =  my_issue['relations_back']

        # Recorro las relaciones creando los links
        relstr = ""
        firstrel = True
        for rel in my_filtered_issue_relations:
            # Obtenemos la incidencia y el item doorstop del objeto que es origen de la relación de Redmine,
            # que significa que es destinatario de la relación de doorstop, ya que es el elemento que está
            # condicionando al actual (el actual depende de él)
            relissue = reqdict[str(rel['issue_from_id'])]
            #print("Relacionado: ",rel," de ",relissue.subject," a ",my_issue.subject)
            if firstrel:
                firstrel = False
            else:
                relstr += " "
                
            relstr += relissue['subject']
            
        if not firstrel:
            thistab[currrow,req_upload_related_column].value = relstr

        current_row[thisdoc] = currrow + 1    
            
        '''
        if (prefix is not None):
            print("prefix: ",prefix)        
            #newitem = tree.add_item(prefix)
            #newitem.text = my_issue.description
            document = tree.find_document(prefix)
            newitem = Item.new(tree, document,
                    document.path, document.root, my_issue.subject,
                    auto=False)
            newitem.set('BDID', str(my_issue.id))
            newitem.set('BDURL', req_server_url+"/issues/"+str(my_issue.id))
            newitem.set('RqSubject', my_issue.subject)
            newitem.set('RqTitle', my_issue.custom_fields.get(req_title_cf_id).value)
            if (parent_issue is not None):
                newitem.set('RqParent', parent_issue.subject)
            
            else:
                newitem.set('RqParent', '')

            newitem.set('RqRationale', my_issue.custom_fields.get(req_rationale_cf_id).value)
            newitem.set('RqLevel', my_issue.custom_fields.get(req_level_cf_id).value)
            newitem.set('RqType', my_issue.custom_fields.get(req_type_cf_id).value)
            newitem.set('RqSources', my_issue.custom_fields.get(req_sources_cf_id).value)
            newitem.set('RqChapter', my_issue.custom_fields.get(req_chapter_cf_id).value)
            newitem.set('RqTarget', version_name)
            newitem.set('text', my_issue.description)
            newitem.save()
            print("---->",newitem)'''


# In[ ]:


# del doc.sheets['Template']


# In[ ]:


doc.save()


# In[ ]:


doc.close()


# In[ ]:





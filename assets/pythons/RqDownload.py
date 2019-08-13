#!/usr/bin/env python
# coding: utf-8

from cfg.configfile_req import *
from redminelib import Redmine

import sys
#print("This is the name of the script: ", sys.argv[0])
#print("Number of arguments: ", len(sys.argv))
#print("The arguments are: " , str(sys.argv))

#print(req_server_url)
#print(req_key_txt)

#pr_id_str = req_project_id_str
pr_id_str = sys.argv[1]
#print(pr_id_str)

#download_filepath = req_download_file_name
download_filepath = sys.argv[2]
#print(download_filepath)

redmine = Redmine(req_server_url,key=req_key_txt)
projects = redmine.project.all()

#print("Proyectos:")
#for p in projects:
#    print("\t",p.identifier," \t| ",p.name)

my_project = redmine.project.get(pr_id_str)
print("Obtenemos proyecto: ",my_project.identifier," | ",my_project.name)    


tmp = redmine.issue.filter(project_id=pr_id_str, tracker_id=req_rq_tracker_id, status_id='*')
my_project_issues = sorted(tmp, key=lambda k: k.custom_fields.get(req_chapter_cf_id).value)
tmp = redmine.issue.filter(project_id=pr_id_str, tracker_id=req_doc_tracker_id, status_id='*')
my_doc_issues = sorted(tmp, key=lambda k: k.custom_fields.get(req_chapter_cf_id).value)

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


doc_dict[req_download_url_row,req_download_url_column].value = req_server_url+'/'
rowindex = req_upload_version_startrow
for v in my_project.versions:
    doc_dict[rowindex,req_upload_version_column].value = v.name
    rowindex += 1


# Ahora generaremos los documentos a partir de los reqdoc

# In[ ]:


tabnumber = 3
for my_issue in my_doc_issues:
    print("********** ",my_issue)
    prefix = my_issue.custom_fields.get(req_prefix_cf_id).value
    mysheet = doc.sheets.copy('Template', my_issue.subject, tabnumber)
    tabnumber += 1
    mysheet[req_download_doc_row,req_download_doc_name_column].value = my_issue.description
    mysheet[req_download_doc_row,req_download_doc_prefix_column].value = prefix
    current_parent = getattr(my_issue, 'parent', None)
    if current_parent is not None:
        parent_issue = redmine.issue.get(current_parent.id)
        #print("parent: ",parent_issue.subject)
        # Rellenamos la celda del padre
        mysheet[req_download_doc_row,req_download_doc_parent_column].value = parent_issue.subject
        
    current_version = getattr(my_issue, 'fixed_version', None)
    
'''
    # De momento en el Excel los docs no tienen versión ni muchas otras informaciones,
    # que deberemos incorporar, como la BD ID, la BD URL, etc...
    # Dejamos este código aquí, proviniente de la exportación a DOORSTOP, hasta que 
    # enriquezcamos el formato LibreOffice para guardar toda esa info.
    current_version = getattr(my_issue, 'fixed_version', None)
    if (current_version is not None):
        print("target:",current_version)
        print(dir(current_version))
        version_name = current_version.name
    else:
        version_name = ''

    doc.set('BDID', str(my_issue.id))
    doc.set('BDURL', req_server_url+"/issues/"+str(my_issue.id))
    doc.set('RqSubject', my_issue.subject)
    doc.set('RqTitle', my_issue.custom_fields.get(req_title_cf_id).value)
    if (parent_issue is not None):
        doc.set('RqParent', parent_issue.subject)
    else:
        doc.set('RqParent', '')
    doc.set('RqRationale', my_issue.custom_fields.get(req_rationale_cf_id).value)
    doc.set('RqLevel', my_issue.custom_fields.get(req_level_cf_id).value)
    doc.set('RqType', my_issue.custom_fields.get(req_type_cf_id).value)
    doc.set('RqSources', my_issue.custom_fields.get(req_sources_cf_id).value)
    doc.set('RqChapter', my_issue.custom_fields.get(req_chapter_cf_id).value)
    doc.set('RqTarget', version_name)
    doc.set('text', my_issue.description)
    
    # Ahora grabamos un requisito cero:
    newitem = Item.new(tree, doc,
        doc.path, doc.root, my_issue.subject+"-0000",
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
'''        


# Ahora crearemos los requisitos "hijos" dentro de cada documento

# In[ ]:


def find_doc(this_issue):
    #print("find_doc: ",this_issue)
    if this_issue.tracker.id == req_doc_tracker_id:
        #print("retorno this", this_issue.subject)
        return this_issue.subject,this_issue.custom_fields.get(req_prefix_cf_id).value 

    # not do found yet
    current_parent = getattr(this_issue, 'parent', None)
    if current_parent is None:
        #print("retorno none")
        return "",""
    
    else:
        parent_issue = redmine.issue.get(current_parent.id)
        #print("Llamo al padre")
        return find_doc(parent_issue)
    
current_row = {}
for my_issue in my_doc_issues:
    current_row[my_issue.subject] = req_upload_first_row
    
#print(current_row)


for my_issue in my_project_issues:
    reqname = my_issue.subject
    print("reqname: ",reqname)
    current_parent = getattr(my_issue, 'parent', None)
    if current_parent is not None:
        #print("current_parent 1: ",current_parent)
        parent_issue = redmine.issue.get(current_parent.id)
        if parent_issue.tracker.id != req_rq_tracker_id:
            current_parent = None
        else:
            print("parent: ",parent_issue.subject)
    
    thisdoc,thisprefix = find_doc(parent_issue)
    #print("thisdoc:",thisdoc)
    #print("thisprefix:",thisprefix)
    thistab = doc.sheets[thisdoc]
    currrow = current_row[thisdoc]
    #print("add the req to the row ",currrow," of the tab ",thistab)
    current_version = getattr(my_issue, 'fixed_version', None)
    idstr = my_issue.subject.replace(thisprefix,'')

    thistab[currrow,req_upload_id_column].value = my_issue.subject
    thistab[currrow,req_upload_title_column].value = my_issue.custom_fields.get(req_title_cf_id).value
    descr = getattr(my_issue, 'description', "")
    thistab[currrow,req_upload_descr_column].value = descr
    thistab[currrow,req_upload_source_column].value = my_issue.custom_fields.get(req_sources_cf_id).value
    thistab[currrow,req_upload_type_column].value = my_issue.custom_fields.get(req_type_cf_id).value
    thistab[currrow,req_upload_level_column].value = my_issue.custom_fields.get(req_level_cf_id).value
    thistab[currrow,req_upload_rationale_column].value = my_issue.custom_fields.get(req_rationale_cf_id).value
    thistab[currrow,req_upload_var_column].value = my_issue.custom_fields.get(req_var_cf_id).value
    thistab[currrow,req_upload_value_column].value = my_issue.custom_fields.get(req_value_cf_id).value
    thistab[currrow,req_upload_chapter_column].value = my_issue.custom_fields.get(req_chapter_cf_id).value.replace(thisprefix,'')
    thistab[currrow,req_upload_status_column].value = my_issue.status
    thistab[currrow,req_download_rqid_column].value = my_issue.id
    thistab[currrow,req_download_bdid_column].value = int(idstr)
    
    if (current_version is not None):
        thistab[currrow,req_upload_target_column].value = current_version.name

    if current_parent is not None:
        thistab[currrow,req_upload_parent_column].value = parent_issue.subject

        
    # Busco las relaciones en las que es destinatario
    my_issue_relations = redmine.issue_relation.filter(issue_id=my_issue.id)
    my_filtered_issue_relations = list(filter(lambda x: x.issue_id != my_issue.id, my_issue_relations))

    # Recorro las relaciones creando los links
    relstr = ""
    firstrel = True
    for rel in my_filtered_issue_relations:
        # Obtenemos la incidencia y el item doorstop del objeto que es origen de la relación de Redmine,
        # que significa que es destinatario de la relación de doorstop, ya que es el elemento que está
        # condicionando al actual (el actual depende de él)
        relissue = redmine.issue.get(rel.issue_id)
        #print("Relacionado: ",rel," de ",relissue.subject," a ",my_issue.subject)
        if firstrel:
            firstrel = False
        else:
            relstr += " "
            
        relstr += relissue.subject
        
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





#!/usr/bin/env python
# coding: utf-8

from cfg.configfile_req import *
from redminelib import Redmine

import sys
print ("This is the name of the script: ", sys.argv[0])
print ("Number of arguments: ", len(sys.argv))
print ("The arguments are: " , str(sys.argv))

print(req_server_url)
print(req_key_txt)

#pr_id_str = req_project_id_str
pr_id_str = sys.argv[1]
print(pr_id_str)

#upload_filepath = req_upload_file_name
upload_filepath = sys.argv[2]
print(upload_filepath)

redmine = Redmine(req_server_url,key=req_key_txt)
projects = redmine.project.all()

print("Proyectos:")
for p in projects:
    print ("\t",p.identifier," \t| ",p.name)

my_project = redmine.project.get(pr_id_str)
print ("Obtenemos proyecto: ",my_project.identifier," | ",my_project.name)    

# Vamos a recorrer la hoja de calculo con los datos de carga especificada en la variable const_file_name del fichero configfile_req.py.  Listaremos los datos cargados.

# In[ ]:


from pyexcel_ods import get_data

file_path = upload_filepath

data = get_data(file_path, start_column=req_upload_start_column, column_limit=(req_upload_end_column-req_upload_start_column+1),
                start_row=req_upload_start_row, row_limit=(req_upload_end_row - req_upload_start_row+1))
data


# Recorreremos ahora las diferentes pestañas para sacar los documentos de requisitos que debemos crear

# In[ ]:


my_project_versions = []
for v in my_project.versions:
    my_project_versions += [v]

for t in data:
    print("********************"+t)
    #primero filtramos la pestaña Intro y la Template
    if (t!='Intro') and (t!='Template'):
        if (t=='Dict'):
            # Cargamos las versiones
            # TODO
            dataimport = data[t]
            rowindex = req_upload_version_startrow
            while (rowindex <= req_upload_version_endrow):
                d = dataimport[rowindex]
                rowindex += 1
                thisversion = d[req_upload_version_column]
                if (len(thisversion)>0):
                    print(rowindex,": ",thisversion)
                    findVersionSuccess = False
                    thisVersionId = None
                    for v in my_project_versions:
                        if not(findVersionSuccess):
                            if (v.name == thisversion):
                                findVersionSuccess = True
                                print("la version ",thisversion," ya existe")
                    
                    if not findVersionSuccess:
                        print("la version ",thisversion," no existe")
                        version = redmine.version.create(
                            project_id = my_project.identifier,
                            name = thisversion,
                            status = 'open',
                            sharing = 'hierarchy',
                            description = thisversion,
                        )
                        my_project_versions += [version]
                        thisVersionId = version.id
                        print("he creado la version con nombre ",version.name)

        else:
            # Obtenemos el contenido de esa pestaña
            dataimport = data[t]
            # Como identificador del documento y "subject", tomamos el nombre de la pestaña
            docidstr = t
            print("DocID: "+docidstr)
            # Obtenemos la informacion de la fila donde estan los datos adicionales del documento de requisito
            d = dataimport[req_upload_doc_row]
            # Como nombre del documento y "description", tomamos la columna de docname
            docname = d[req_upload_doc_name_column]
            print("DocName: ",docname)
            # Como prefijo de los codigos generados por el documento, tomamos la columna de prefijo
            prefixstr = d[req_upload_doc_prefix_column]
            # Usando el identificador del documento, determinamos si este ya existe o hay que crearlo
            doclist = redmine.issue.filter(project_id=pr_id_str, subject=docidstr, tracker_id=req_doc_tracker_id)
            if(len(doclist)==0):
                # no existe el requisito asociado a la pestaña, lo creo
                print ("Creando documento ",docidstr)
                thisreq = redmine.issue.create(project_id = pr_id_str,
                                               tracker_id = req_doc_tracker_id,
                                               subject = docidstr,
                                               description = docname,
                                               custom_fields=[{'id': req_title_cf_id,'value': docname},
                                                              {'id': req_prefix_cf_id, 'value': prefixstr},
                                                              {'id': req_chapter_cf_id, 'value': prefixstr}
                                                             ]
                                              )
            else:
                # existe el requisito, asi que lo actualizo
                print ("actualizando documento", doclist[0].id)
                redmine.issue.update(resource_id=doclist[0].id,
                                     description = docname,
                                     custom_fields=[{'id': req_title_cf_id,'value': docname},
                                                    {'id': req_prefix_cf_id, 'value':prefixstr},
                                                    {'id': req_chapter_cf_id, 'value': prefixstr}
                                                   ]
                                     )


# Vamos a buscar los documentos padre de los documentos ya existentes

# In[ ]:


for t in data:
    print("********************"+t)
    # No vamos a tratar la pestaña "Intro"
    if (t!='Intro') and (t!='Dict') and (t!='Template'):
        # importamos los datos 
        dataimport = data[t]
        # Buscamos el documento que representa a la pestaña
        doclist = redmine.issue.filter(project_id=pr_id_str, subject=t, tracker_id=req_doc_tracker_id)
        if(len(doclist)>0):
            # Existe el documento asociado a la pestaña, puedo tratarlo
            thisdoc = doclist[0]
            print("rqid: "+thisdoc.subject)
            d = dataimport[0]
            parentdocstr = d[req_upload_doc_parent_column]
            print("parent str: " + parentdocstr)
            if (len(parentdocstr)>0):
                # Se ha especificado un documento padre
                parentdoclist = redmine.issue.filter(project_id=pr_id_str,subject=parentdocstr, tracker_id=req_doc_tracker_id)
                if len(parentdoclist)>0:
                    # Existe el documento padre, puedo tratarlo
                    parentdoc = parentdoclist[0]
                    print("parent: ",parentdoc)
                    print("parent id:",parentdoc.id)
                    redmine.issue.update(resource_id=thisdoc.id, parent_issue_id = parentdoc.id)
                else:
                    print("error, no encontramos el padre")


# Ya tenemos los documentos de requisitos (pestañas) cargados como requisitos padres.  Ahora puedo recorrer los requisitos de cada una de las pestañas y crear los requisitos que falten.

# In[ ]:


for t in data:
    print("********************"+t)
    if (t!='Intro') and (t!='Dict') and (t!='Template'):
        dataimport = data[t]
        reqdoclist = redmine.issue.filter(project_id=pr_id_str, status_id='*',subject=t)
        print(t, "len list: ",len(reqdoclist))
        if(len(reqdoclist)>0):
            reqDoc = reqdoclist[0]
            print("reqDocId:", reqDoc.id)
            reqDocPrefix = reqDoc.custom_fields.get(req_prefix_cf_id).value
            print("reqDocPrefix:",reqDocPrefix)
            # Obtendremos en un bucle todos los requisitos, saltandonos las 2 lineas iniciales
            current_row = 0
            for r in dataimport:
                if current_row < req_upload_first_row:
                    current_row += 1
                else:
                    title_str = r[req_upload_title_column]
                    print("title: ",title_str)
                    if len(title_str) <= 0:
                        print("Saltamos una fila que no tiene suficientes celdas")
                    else:
                        # Estamos procesando las lineas de requisitos
                        rqidstr = r[req_upload_id_column]
                        print("rqid: "+rqidstr)
                        related_str = r[req_upload_related_column]
                        print("related: "+related_str)
                        title_str = r[req_upload_title_column]
                        print("title: ",title_str)
                        descr = r[req_upload_descr_column]
                        print("description: ",descr)
                        reqsource = r[req_upload_source_column]
                        print("reqsource: ",reqsource)
                        reqtype = r[req_upload_type_column]
                        print("reqtype: ",reqtype)
                        reqlevel = r[req_upload_level_column]
                        print("reqlevel: ",reqlevel)
                        reqrationale = r[req_upload_rationale_column]
                        print("reqrationale: ",reqrationale)
                        reqvar = r[req_upload_var_column]
                        print("reqvar: ",reqvar)
                        reqvalue = r[req_upload_value_column]
                        print("reqvalue: ",reqvalue)
                        rqchapter = reqDocPrefix+str(r[req_upload_chapter_column])
                        print("rqchapter: ",rqchapter)
                        rqtarget = r[req_upload_target_column]
                        print("rqtarget: ",rqtarget)
                        findVersionSuccess = False
                        thisVersionId = None
                        print("num versiones: ",len(my_project_versions))
                        for v in my_project_versions:
                            print("version: ",v)
                            if not(findVersionSuccess):
                                print("--->",v.name,":",rqtarget)
                                if (v.name == rqtarget):
                                    print("LO ENCONTRE!!")
                                    findVersionSuccess = True
                                    thisVersionId = v.id
                                else:
                                    print("NO.....")
                                
                            else:
                                print("this version succes????:",findVersionSuccess)

                        print("thisVersionId: ",thisVersionId)
                        # A partir del nombre del requisito, miramos si el requisito ya existe
                        reqlist = redmine.issue.filter(project_id=pr_id_str,subject=rqidstr, tracker_id=req_rq_tracker_id)
                        if(len(reqlist)==0):
                            # no existe el requisito, lo creo
                            print ("creando requisito")
                            thisreq = redmine.issue.create(project_id = pr_id_str,
                                                           tracker_id = req_rq_tracker_id,
                                                           subject = rqidstr,
                                                           description = descr,
                                                           fixed_version_id = thisVersionId,
                                                           custom_fields=[{'id': req_title_cf_id,'value': title_str},
                                                                          {'id': req_sources_cf_id,'value': reqsource},
                                                                          {'id': req_type_cf_id,'value': reqtype},
                                                                          {'id': req_level_cf_id,'value': reqlevel},
                                                                          {'id': req_rationale_cf_id,'value': reqrationale},
                                                                          {'id': req_var_cf_id,'value': reqvar},
                                                                          {'id': req_value_cf_id,'value': reqvalue},
                                                                          {'id': req_chapter_cf_id, 'value':rqchapter}
                                                                         ]
                                                          )


                        else:
                            # existe el requisito, asi que lo actualizo
                            print ("actualizando requisito", reqlist[0].id)
                            redmine.issue.update(resource_id=reqlist[0].id,
                                                 description = descr,
                                                 fixed_version_id = thisVersionId,
                                                 custom_fields=[{'id': req_title_cf_id,'value': title_str},
                                                                {'id': req_sources_cf_id,'value': reqsource},
                                                                {'id': req_type_cf_id,'value': reqtype},
                                                                {'id': req_level_cf_id,'value': reqlevel},
                                                                {'id': req_rationale_cf_id,'value': reqrationale},
                                                                {'id': req_var_cf_id,'value': reqvar},
                                                                {'id': req_value_cf_id,'value': reqvalue},
                                                                {'id': req_chapter_cf_id, 'value':rqchapter}
                                                                ]
                                                )



# Ahora buscamos las relaciones entre requisitos padres e hijos, y de dependencia.

# In[ ]:


for t in data:
    print("********************"+t)
    if (t!='Intro') and (t!='Dict') and (t!='Template'):
        dataimport = data[t]
        reqdoclist = redmine.issue.filter(project_id=pr_id_str, status_id='*',subject=t, tracker_id=req_doc_tracker_id)
        print(t, "len list: ",len(reqdoclist))
        if(len(reqdoclist)>0):
            reqDoc = reqdoclist[0]
            print("reqDocId:", reqDoc.id)
            # Obtendremos en un bucle todos los requisitos, saltandonos las 2 lineas iniciales
            current_row = 0
            for r in dataimport:
                if current_row < req_upload_first_row:
                    current_row += 1
                else:
                    title_str = r[req_upload_title_column]
                    if len(title_str) <= 0:
                        #print("Saltamos una fila que no tiene suficientes celdas")
                        aux = 1
                    else:
                        # Estamos procesando las lineas de requisitos
                        rqidstr = r[req_upload_id_column]
                        print("rqid: "+rqidstr)
                        related_str = r[req_upload_related_column]
                        print("related: "+related_str)
                        parent_str = r[req_upload_parent_column]
                        print("parent_str: ",parent_str)
                        # Accedo al objeto requisito
                        reqlist = redmine.issue.filter(project_id=pr_id_str,subject=rqidstr, tracker_id=req_rq_tracker_id)
                        if(len(reqlist)>0):
                            # El requisito existe, lo tomo como requisito actual
                            current_req = reqlist[0];
                            if (len(parent_str)>0):
                                # Buscamos el requisito padre para enlazarlo
                                parentlist = redmine.issue.filter(project_id=pr_id_str,subject=parent_str)
                                if len(parentlist)>0:
                                    # Existe el documento padre, puedo tratarlo
                                    parentreq = parentlist[0]
                                    print("parent: ",parentreq)
                                    print("parent id:",parentreq.id)
                                    redmine.issue.update(resource_id=current_req.id, parent_issue_id = parentreq.id)                                    
                                else:
                                    print("ERROR: No encontramos el requisito padre!!!")

                            else:
                                # El requisito no tiene padre, asi que su padre sera el documento
                                redmine.issue.update(resource_id=current_req.id, parent_issue_id = reqDoc.id)                                    
                                
                            # Exploramos ahora las relaciones de dependencia
                            # Busco las relaciones existences con este requisito
                            my_req_relations = redmine.issue_relation.filter(issue_id=current_req.id)
                            # Como voy a tratar las que tienen el requisito como destino, las filtro
                            my_filtered_req_relations = list(filter(lambda x: x.issue_to_id == current_req.id, my_req_relations))
                            # Al cargar requisitos puede ser que haya antiguas relaciones que ya no existan.  Al finalizar la carga
                            # deberemos eliminar los remanentes, asi que meteremos la lista de relaciones en una lista de remanentes
                            residual_relations = [] + my_filtered_req_relations
                            print("residual_relations BEFORE",residual_relations)
                            if (len(related_str)>0):
                                if (related_str[0]!='-'):
                                    # Ahora saco todos los ID de los requisitos del otro lado (en el lado origen de la relacion)
                                    related_req = related_str.split()
                                    # Y voy a recorrer uno a uno
                                    for rreq in related_req:
                                        print("related to: ",rreq)
                                        # Busco ese requisito
                                        blocking_reqlist = redmine.issue.filter(project_id=pr_id_str,subject=rreq, tracker_id=req_rq_tracker_id)
                                        if (len(blocking_reqlist)>0):
                                            blocking_req = blocking_reqlist[0]
                                            # Veo si ya existe algun tipo de relacion con el
                                            preexistent_relations = list(filter(lambda x: x.issue_id == blocking_req.id, my_filtered_req_relations))
                                            print(preexistent_relations)
                                            if (len(preexistent_relations)>0):
                                                print("Ya existe la relacion ",preexistent_relations[0])
                                                residual_relations.remove(preexistent_relations[0])
                                            else:
                                                print("Creo una nueva relacion")
                                                relation = redmine.issue_relation.create(
                                                    issue_id=blocking_req.id,
                                                    issue_to_id=current_req.id,
                                                    relation_type='blocks'
                                                )
                                            
                            # Hay que eliminar todas las relaciones preexistentes que no hayan sido "reescritas"
                            print("residual_relations AFTER",residual_relations)
                            print(residual_relations)
                            for r in residual_relations:
                                print("Destruyo la relacion", r)
                                redmine.issue_relation.delete(r.id)
                                
print("Acabamos")


# In[ ]:





# In[ ]:





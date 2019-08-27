class CosmosysReqsController < ApplicationController
  before_action :find_project#, :authorize, :except => [:tree]

  @@chapterdigits = 3
  @@reqdoctracker = Tracker.find_by_name('ReqDoc')
  @@reqtracker = Tracker.find_by_name('Req')
  @@cfchapter = IssueCustomField.find_by_name('RqChapter')
  @@cfprefix = IssueCustomField.find_by_name('RqPrefix')
  @@cftitle = IssueCustomField.find_by_name('RqTitle')
  @@cfsources = IssueCustomField.find_by_name('RqSources')
  @@cftype = IssueCustomField.find_by_name('RqType')
  @@cflevel = IssueCustomField.find_by_name('RqLevel')
  @@cfrationale = IssueCustomField.find_by_name('RqRationale')
  @@cfvar = IssueCustomField.find_by_name('RqVar')
  @@cfvalue = IssueCustomField.find_by_name('RqValue')
  @@cfdiag = IssueCustomField.find_by_name('RqDiagrams')
  @@cfdiagpr = ProjectCustomField.find_by_name('RqDiagrams')

  def index
    @cosmosys_reqs = CosmosysReq.all
  end 

  def create_repo
    print("\n\n\n\n\n\n") 
    if request.get? then
      print("GET!!!!!")
    else
      print("POST!!!!!")
      @output = ""
      # First we check if the setting for the local repo is set
      if (Setting.plugin_cosmosys_req['repo_local_path'].blank?) then
        # If it is not set, we can not continue
        @output += "Error: the local repos path template is not defined\n"
      else
        # First, we need to know if the setting to locate the repo template is set
        if (Setting.plugin_cosmosys_req['repo_template_id'].blank?) then
          @output += "Error: the template id setting is not set\n"
        else
          # The setting exists, so we can create the origin and destination paths
          destdir = "#{Setting.plugin_cosmosys_req['repo_local_path']}"
          destdir["%project_id%"]= @project.identifier
          origdir = "#{Setting.plugin_cosmosys_req['repo_local_path']}"
          origdir["%project_id%"]= Setting.plugin_cosmosys_req['repo_template_id']

          # Now we have to know if the destination directory already exists
          if (File.directory?(destdir)) then
            @output += "Error: the destination repo already exists\n"  
            print(destdir)            
          else
            if (File.directory?(origdir)) then
              comando = "cp -r #{origdir} #{destdir}"
              print("\n\n #{comando}")
              `#{comando}`
              comando = "cd #{destdir}; git init"
              print("\n\n #{comando}")
              `#{comando}`
              git_commit_repo(@project,"[reqbot] project creation")
              if (Setting.plugin_cosmosys_req['repo_redmine_sync']) then
                # The setting says we must sync with a remote server
                if (Setting.plugin_cosmosys_req['repo_redmine_path'].blank?) then
                  # The setting is not set, so we can not sync with the remote server
                  @output += "Error: the redmine repo path template is not defined\n"
                else
                  redminerepodir = "#{Setting.plugin_cosmosys_req['repo_redmine_path']}"
                  redminerepodir["%project_id%"] = @project.identifier
                  #git clone --bare demo demo.git
                  comando = "git clone --mirror #{destdir} #{redminerepodir}"
                  print("\n\n #{comando}")
                  `#{comando}`
                  # Now we link the repo to the project
                  repo = Repository::Git.new
                  repo.is_default = true
                  repo.project = @project
                  repo.url = redminerepodir
                  repo.identifier = "rq"
                  repo.extra_info =  {"extra_report_last_commit"=>"1"}
                  repo.save
                end
              else
                @output += "Info: redmine sync not enabled\n"          
              end
            else
              @output += "Error: the template repo does not exist\n"
              print(origdir)
            end
          end
        end 
      end
      if @output.size <= 255 then 
          flash[:notice] = @output.to_s
      else
          flash[:notice] = "Message too long\n"
      end
      print(@output)
    end
  end

  def project_menu
  end

  def show_as_tree
    require 'json'

    splitted_url = request.fullpath.split('/cosmosys_reqs')
    root_url = request.base_url+splitted_url[0]

    if request.get? then
      print("GET!!!!!")
      if (params[:node_id]) then
        print("NODO!!!\n")
        thisnode = @project.issues.find(params[:node_id])
        roots = [thisnode]
      else
        print("PROYECTO!!!\n")     
        roots = @project.issues.where(:parent => nil)
      end

      treedata = {}

      treedata[:project] = @project.attributes.slice("id","name","identifier")
      treedata[:project][:url] = root_url
      treedata[:targets] = {}
      treedata[:statuses] = {}
      treedata[:trackers] = {}
      treedata[:reqdocs] = {}
      treedata[:reqs] = []

      reqdocs = @project.issues.where(:tracker => @@reqdoctracker).sort_by {|obj| obj.custom_values.find_by_custom_field_id(@@cfchapter.id).value}

      IssueStatus.all.each { |st| 
        treedata[:statuses][st.id.to_s] = st.name
      }

      Tracker.all.each { |tr| 
        treedata[:trackers][tr.id.to_s] = tr.name
      }

      @project.versions.each { |v| 
        treedata[:targets][v.id.to_s] = v.name
      }

      reqdocs.each { |r|
        tree_node = r.attributes.slice("id","tracker_id","subject","description","status_id","fixed_version_id","parent_id","root_id")
        tree_node[:chapter] = r.custom_values.find_by_custom_field_id(@@cfchapter.id).value
        tree_node[:title] = r.custom_values.find_by_custom_field_id(@@cftitle.id).value
        tree_node[:prefix] = r.custom_values.find_by_custom_field_id(@@cfprefix.id).value
        treedata[:reqdocs][r.id.to_s] = tree_node
      }


      roots.each { |r|
        thisnode=r
        tree_node = create_json(thisnode,root_url,true,nil)
        treedata[:reqs] << tree_node
      }


      respond_to do |format|
        format.html {
          @to_json = treedata.to_json
        }
        format.json { 
          require 'json'
          ActiveSupport.escape_html_entities_in_json = false
          render json: treedata
          ActiveSupport.escape_html_entities_in_json = true        
        }
      end
    else

      print("POST!!!!!")
      structure = params[:structure]
      json_params_wrapper = JSON.parse(request.body.read())
      structure = json_params_wrapper['structure']
      #print ("structure: \n\n")
      #print structure
      rootnode = structure[0]
      structure.each { |n|
        update_node(n,nil,"",1)
      }
      redirect_to :action => 'tree', :method => :get, :id => @project.id 
    end
  end

def show_as_table
    require 'json'

    splitted_url = request.fullpath.split('/cosmosys_reqs')
    root_url = request.base_url+splitted_url[0]

    if request.get? then
      print("GET!!!!!")
      reqdocs = @project.issues.where(:tracker => @@reqdoctracker).sort_by {|obj| obj.custom_values.find_by_custom_field_id(@@cfchapter.id).value}

      treedata = {}

      treedata[:project] = @project.attributes.slice("id","name","identifier")
      treedata[:project][:url] = root_url
      treedata[:targets] = {}
      treedata[:statuses] = {}
      treedata[:reqdocs] = {}

      IssueStatus.all.each { |st| 
        treedata[:statuses][st.id.to_s] = st.name
      }

      @project.versions.each { |v| 
        treedata[:targets][v.id.to_s] = v.name
      }

      reqdocs.each { |r|
        thisnode=r
        tree_node = create_json(thisnode,root_url,false,nil)
        treedata[:reqdocs][r.id.to_s] = tree_node
      }

      respond_to do |format|
        format.html {
          @to_json = treedata.to_json
        }
        format.json { 
          require 'json'
          ActiveSupport.escape_html_entities_in_json = false
          render json: treedata
          ActiveSupport.escape_html_entities_in_json = true        
        }
      end
    else

      print("POST!!!!!")
      structure = params[:structure]
      json_params_wrapper = JSON.parse(request.body.read())
      structure = json_params_wrapper['structure']
      #print ("structure: \n\n")
      #print structure
      rootnode = structure[0]
      structure.each { |n|
        update_node(n,nil,"",1)
      }
      redirect_to :action => 'tree', :method => :get, :id => @project.id 
    end
  end

  def show
    show_as_tree
  end

  def upload

    # This section defines the connection between the CosmoSys_Req tools and the OpenDocument spreadsheet used for importing requirements
    req_upload_start_column = 0
    req_upload_end_column = 16
    req_upload_start_row = 0
    req_upload_end_row = 199

    #This section defines the document information cell indexes to retrieve information for the documents from the upload file
    req_upload_doc_row = 0
    req_upload_doc_name_column = 1
    req_upload_doc_prefix_column = 10 # 5
    req_upload_doc_parent_column = 8 # 3

    #This section defines the requirements information cell indexes to retrieve information for the requirements from the upload file
    req_upload_first_row = 2
    req_upload_column_number = req_upload_end_column + 1
    req_upload_id_column = 4
    req_upload_related_column = 10
    req_upload_title_column = 5
    req_upload_descr_column = 6
    req_upload_source_column = 11
    req_upload_type_column = 9
    req_upload_level_column = 8
    req_upload_rationale_column = 15
    req_upload_var_column = 13
    req_upload_value_column = 14
    req_upload_chapter_column = 0
    req_upload_target_column = 12
    req_upload_parent_column = 7
    req_upload_status_column = 16

    req_upload_version_column = 5
    req_upload_version_startrow = 1
    req_upload_version_endrow = 25


    print("\n\n\n\n\n\n")

    my_project_versions = []
    @project.versions.each { |v| 
      my_project_versions << v
    }
    print my_project_versions

    if request.get? then
      print("GET!!!!!")
    else
      print("POST!!!!!")


      git_pull_repo(@project)
      @output = ""
      # First we check if the setting for the local repo is set
      if (Setting.plugin_cosmosys_req['repo_local_path'].blank?) then
        # If it is not set, we can not continue
        @output += "Error: the local repos path template is not defined\n"
      else
        # The setting exists, so we can create the origin and destination paths
        repodir = "#{Setting.plugin_cosmosys_req['repo_local_path']}"
        repodir["%project_id%"]= @project.identifier
        # Now we have to know if the destination directory already exists
        if (File.directory?(repodir)) then
          if (Setting.plugin_cosmosys_req['relative_uploadfile_path'].blank?) then
            # If it is not set, we can not continue
            @output += "Error: the relative path to upload file is not set\n"
          else
            uploadfilepath = repodir + "/" + Setting.plugin_cosmosys_req['relative_uploadfile_path']
            if (File.exists?(uploadfilepath)) then

              # Process Dict
              book = Rspreadsheet.open(uploadfilepath)
              dictsheet = book.worksheets('Dict')
              introsheet = book.worksheets('Intro')
              templatesheet = book.worksheets('Template')

              # Import versions
              rowindex = req_upload_version_startrow+1
              while (rowindex <= req_upload_version_endrow+1) do
                d = dictsheet.row(rowindex)
                rowindex += 1
                thisversion = d[req_upload_version_column+1]
                if (thisversion!=nil) then
                  #print(rowindex.to_s + ": " + thisversion)
                  findVersionSuccess = false
                  thisVersionId = nil
                  my_project_versions.each { |v|  
                      if not(findVersionSuccess) then
                          if (v.name == thisversion) then
                              findVersionSuccess = true
                              #print("la version ",thisversion," ya existe")
                          end
                      end
                  }
                  if not findVersionSuccess then
                      #print("la version " + thisversion + " no existe")
                      nv = @project.versions.new
                      nv.name = thisversion
                      nv.status = 'open'
                      nv.sharing = 'hierarchy'
                      nv.description = thisversion
                      nv.save
                      my_project_versions << nv
                      #print("\nhe creado la version " + nv.name + "con id " + nv.id.to_s)
                  end
                end
              end

              sheetindex = 1
              thissheet = book.worksheets(sheetindex)
              while (thissheet != nil) do
                if ((thissheet != dictsheet) and (thissheet != introsheet) and (thissheet != templatesheet)) then
                    # Tratamos la hoja en concreto
                    docidstr = thissheet.name
                    #print("DocID: "+docidstr)
                    # Obtenemos la informacion de la fila donde estan los datos adicionales del documento de requisito
                    d = thissheet.row(req_upload_doc_row+1)
                    # Como nombre del documento y "description", tomamos la columna de docname
                    docname = d[req_upload_doc_name_column+1]
                    #print("DocName: ",docname)
                    # Como prefijo de los codigos generados por el documento, tomamos la columna de prefijo
                    prefixstr = d[req_upload_doc_prefix_column+1]
                    #print("\nprefijo: "+ prefixstr)
                    #print("\ndatos:",d)
                    # Usando el identificador del documento, determinamos si este ya existe o hay que crearlo
                    thisdoc = @project.issues.find_by_subject(docidstr)
                    if (thisdoc == nil) then
                      # no existe el reqdoc asociado a la pestaña, lo creo
                      #print("Creando documento " + docidstr)
                      thisdoc = @project.issues.new
                      thisdoc.author = User.current
                      thisdoc.tracker = @@reqdoctracker
                      thisdoc.subject = docidstr
                      thisdoc.description = docname
                      thisdoc.save
                    else                      
                      #print("si existe el documento")
                      thisdoc.description = docname
                    end
                      cft = thisdoc.custom_values.find_by_custom_field_id(@@cftitle.id)
                      cft.value = docname
                      cft.save                      
                      cfp = thisdoc.custom_values.find_by_custom_field_id(@@cfprefix.id)
                      cfp.value = prefixstr
                      cfp.save
                      cfc = thisdoc.custom_values.find_by_custom_field_id(@@cfchapter.id)
                      cfc.value = prefixstr
                      cfc.save
                      thisdoc.save
                      #print("He actualizado o creado el documento con id "+thisdoc.id.to_s)
                end
                sheetindex += 1
                thissheet = book.worksheets(sheetindex)
              end

              # Vamos a buscar los documentos padre de los documentos ya existentes
              sheetindex = 1
              thissheet = book.worksheets(sheetindex)
              while (thissheet != nil) do
                if ((thissheet != dictsheet) and (thissheet != introsheet) and (thissheet != templatesheet)) then
                    # Tratamos la hoja en concreto
                    docidstr = thissheet.name
                    #print("DocID: "+docidstr)
                    # Usando el identificador del documento, determinamos si este ya existe o hay que crearlo
                    thisdoc = @project.issues.find_by_subject(docidstr)
                    #print("rqid: "+thisdoc.subject)
                    d = thissheet.row(req_upload_doc_row+1)
                    parentdocstr = d[req_upload_doc_parent_column+1]
                    if (parentdocstr != nil) then
                      #print("parent str: " + parentdocstr)
                      parentdoc = @project.issues.find_by_subject(parentdocstr)
                      #print("parent: ",parentdoc)
                      #print("parent id:",parentdoc.id)
                      thisdoc.parent = parentdoc
                      thisdoc.save
                    else
                      print("No encontramos el padre de "+docidstr)
                    end
                end
                sheetindex += 1
                thissheet = book.worksheets(sheetindex)
              end


# Ya tenemos los documentos de requisitos (pestañas) cargados como requisitos padres.  Ahora puedo recorrer los requisitos de cada una de las pestañas y crear los requisitos que falten.

# In[ ]:

              status_dict = {}
              IssueStatus.all.each{|st|
                  status_dict[st.name] = st.id
              }
              sheetindex = 1
              thissheet = book.worksheets(sheetindex)
              while (thissheet != nil) do
                if ((thissheet != dictsheet) and (thissheet != introsheet) and (thissheet != templatesheet)) then
                  # Tratamos la hoja en concreto
                  docidstr = thissheet.name
                  #print("DocID: "+docidstr)
                  # Usando el identificador del documento, determinamos si este ya existe o hay que crearlo
                  thisdoc = @project.issues.find_by_subject(docidstr)
                  if (thisdoc != nil) then
                    cfp = thisdoc.custom_values.find_by_custom_field_id(@@cfprefix.id)
                    reqDocPrefix = cfp.value
                    #print("reqDocPrefix:",reqDocPrefix)
                    current_row = req_upload_first_row+1
                    while (current_row <= req_upload_end_row) do
                      r = thissheet.row(current_row)
                      #print("\nTrato la fila "+ current_row.to_s)
                      title_str = r[req_upload_title_column+1]
                      if (title_str != nil) then
                        #print("title: ",title_str)
                        # Estamos procesando las lineas de requisitos
                        rqidstr = r[req_upload_id_column+1]
                        #print("rqid: "+rqidstr)
                        descr = r[req_upload_descr_column+1]
                        reqsource = r[req_upload_source_column+1]
                        reqtype = r[req_upload_type_column+1]
                        reqlevel = r[req_upload_level_column+1]
                        reqrationale = r[req_upload_rationale_column+1]
                        reqvar = r[req_upload_var_column+1]
                        reqvalue = r[req_upload_value_column+1]
                        rqchapterstr = r[req_upload_chapter_column+1].to_s
                        rqchapterarray = rqchapterstr.split('.')
                        #print(rqchapterarray)
                        rqchapterstring = ""
                        rqchapterarray.each { |e|
                          rqchapterstring += e.to_i.to_s.rjust(@@chapterdigits, "0")+"."
                        }
                        rqchapter = reqDocPrefix + rqchapterstring
                        #print(rqchapter)
                        rqstatus = status_dict[r[req_upload_status_column+1]]
                        rqtarget = r[req_upload_target_column+1]

                        # Usando el identificador del documento, determinamos si este ya existe o hay que crearlo
                        thisreq = @project.issues.find_by_subject(rqidstr)
                        if (thisreq == nil) then
                          # no existe el req asociado a la fila, lo creo
                          print ("Creando requisito " + rqidstr)
                          thisreq = @project.issues.new
                          thisreq.author = User.current
                          thisreq.tracker = @@reqtracker
                          thisreq.subject = rqidstr
                          if (descr != nil) then
                            #print("description: ",descr)
                            thisreq.description = descr
                          end
                          thisreq.save
                        else                      
                          #print("si existe el requisito")
                          thisreq.tracker = @@reqtracker
                          if (descr != nil) then
                            #print("description: ",descr)
                            thisreq.description = descr
                          end
                        end
                        if (rqstatus != nil) then
                          #print("rqstatus: ",rqstatus)
                          thisreq.status = IssueStatus.find(rqstatus)
                        end
                        if (rqtarget != nil) then
                          #print("rqtarget: ",rqtarget)
                          findVersionSuccess = false
                          thisVersion = nil
                          #print("num versiones: ",@project.versions.size)
                          @project.versions.each { |v|  
                            if not(findVersionSuccess) then
                              if (v.name == rqtarget) then
                                #print("LO ENCONTRE!!")
                                findVersionSuccess = true
                                thisVersion = v
                              else
                                #print("NO.....")
                              end                                
                            end
                          }
                          if (findVersionSuccess) then
                            #print("this version succes????:",findVersionSuccess)
                            #print("thisVersionId: ",thisVersion.id)
                            thisreq.fixed_version = thisVersion
                          end
                        end                        
                        if (title_str != nil) then
                          cft = thisreq.custom_values.find_by_custom_field_id(@@cftitle.id)
                          cft.value = title_str
                          cft.save
                        end
                        if (rqchapter != nil) then
                          #print("rqchapter: ",rqchapter)
                          cfc = thisreq.custom_values.find_by_custom_field_id(@@cfchapter.id)
                          cfc.value = rqchapter
                          cfc.save
                        end
                        if (reqsource != nil) then
                          #print("reqsource: ",reqsource)
                          cfs = thisreq.custom_values.find_by_custom_field_id(@@cfsources.id)
                          cfs.value = reqsource
                          cfs.save
                        end
                        if (reqtype != nil) then
                          #print("reqtype: ",reqtype)
                          cfty = thisreq.custom_values.find_by_custom_field_id(@@cftype.id)
                          cfty.value = reqtype
                          cfty.save
                        end
                        if (reqlevel != nil) then
                          #print("reqlevel: ",reqlevel)
                          cfl = thisreq.custom_values.find_by_custom_field_id(@@cflevel.id)
                          cfl.value = reqlevel
                          cfl.save
                        end
                        if (reqrationale != nil) then
                          #print("reqrationale: ",reqrationale)
                          cfr = thisreq.custom_values.find_by_custom_field_id(@@cfrationale.id)
                          cfr.value = reqrationale
                          cfr.save
                        end
                        if (reqvar != nil) then
                          #print("reqvar: ",reqvar)
                          cfv = thisreq.custom_values.find_by_custom_field_id(@@cfvar.id)
                          cfv.value = reqvar
                          cfv.save
                        end
                        if (reqvalue != nil) then
                          #print("reqvalue: ",reqvalue)
                          cfvl = thisreq.custom_values.find_by_custom_field_id(@@cfvalue.id)
                          cfvl.value = reqvalue
                          cfvl.save
                        end

                        thisreq.save
                        #print("He actualizado o creado el requisito con id "+thisreq.id.to_s)


                      end
                      current_row += 1
                    end        
                  else
                    print("Error, no existe el documento!!!")
                  end
                end
                sheetindex += 1
                thissheet = book.worksheets(sheetindex)
              end




# Ahora buscamos las relaciones entre requisitos padres e hijos, y de dependencia.
              sheetindex = 1
              thissheet = book.worksheets(sheetindex)
              while (thissheet != nil) do
                if ((thissheet != dictsheet) and (thissheet != introsheet) and (thissheet != templatesheet)) then
                  # Tratamos la hoja en concreto
                  docidstr = thissheet.name
                  print("DocID: "+docidstr)
                  # Usando el identificador del documento, determinamos si este ya existe o hay que crearlo
                  thisdoc = @project.issues.find_by_subject(docidstr)
                  if (thisdoc != nil) then
                    cfp = thisdoc.custom_values.find_by_custom_field_id(@@cfprefix.id)
                    reqDocPrefix = cfp.value
                    #print("reqDocPrefix:",reqDocPrefix)
                    current_row = req_upload_first_row+1
                    while (current_row <= req_upload_end_row) do
                      r = thissheet.row(current_row)
                      #print("\nTrato la fila "+ current_row.to_s)
                      title_str = r[req_upload_title_column+1]
                      if (title_str != nil) then
                        #print("title: ",title_str)
                        # Estamos procesando las lineas de requisitos
                        rqidstr = r[req_upload_id_column+1]
                        #print("rqid: "+rqidstr)
                        thisreq = @project.issues.find_by_subject(rqidstr)
                        if (thisreq != nil) then

                          parent_str = r[req_upload_parent_column+1]
                          related_str = r[req_upload_related_column+1]


                          if (parent_str != nil) then
                            #print("parent_str: ",parent_str)
                            parentissue = @project.issues.find_by_subject(parent_str)
                            if (parentissue != nil) then 
                              #print("parent: ",parentissue)
                              #print("parent id:",parentissue.id)
                              thisreq.parent = parentissue
                            else
                              print("ERROR: No encontramos el requisito padre!!!")
                            end
                          else
                            # El requisito no tiene padre, asi que su padre sera el documento
                            thisreq.parent = thisdoc
                          end

                          # Exploramos ahora las relaciones de dependencia
                          # Busco las relaciones existences con este requisito
                          # Como voy a tratar las que tienen el requisito como destino, las filtro
                          my_filtered_req_relations = thisreq.relations_to
                          # Al cargar requisitos puede ser que haya antiguas relaciones que ya no existan.  Al finalizar la carga
                          # deberemos eliminar los remanentes, asi que meteremos la lista de relaciones en una lista de remanentes
                          residual_relations = [] 
                          my_filtered_req_relations.each { |e|
                            if (e.relation_type == 'blocks') then
                              residual_relations << e
                            end
                          }
                          #print("residual_relations BEFORE",residual_relations)

                          if (related_str != nil) then
                            #print("related: "+related_str)
                            if (related_str[0]!='-') then
                              # Ahora saco todos los ID de los requisitos del otro lado (en el lado origen de la relacion)
                              related_req = related_str.split()
                              related_req.each { |rreq|
                                #print("related to: ",rreq)
                                # Busco ese requisito
                                blocking_req = @project.issues.find_by_subject(rreq)
                                if (blocking_req != nil) then
                                  # Veo si ya existe algun tipo de relacion con el
                                  preexistent_relations = thisreq.relations_to.where(issue_from: blocking_req)
                                  #print(preexistent_relations)
                                  already_exists = false
                                  if (preexistent_relations.size>0) then
                                    preexistent_relations.each { |rel|
                                      if (rel.relation_type == 'blocks') then
                                        #print("Ya existe la relacion ",rel)
                                        residual_relations.delete(rel)
                                        already_exists = true
                                      end
                                    }
                                  end
                                  if not(already_exists) then
                                    #print("Creo una nueva relacion")
                                    relation = blocking_req.relations_from.new
                                    relation.issue_to=thisreq
                                    relation.relation_type='blocks'
                                    relation.save
                                  end

                                else
                                  print("Error, no existe el requisito bloqueante")
                                end
                              }
                            end
                          end

                          # Hay que eliminar todas las relaciones preexistentes que no hayan sido "reescritas"
                          #print("residual_relations AFTER",residual_relations)
                          residual_relations.each { |r|  
                              #print("Destruyo la relacion", r)
                              r.issue_from.relations_from.delete(r)
                              r.destroy
                          }
                          thisreq.save
                          #print("He actualizado o creado el requisito con id "+thisreq.id.to_s)
                        else
                          print("Error, el requisito no pudo ser encontrado")
                        end

                      end
                      current_row += 1
                    end        
                  else
                    print("Error, no existe el documento!!!")
                  end
                end
                sheetindex += 1
                thissheet = book.worksheets(sheetindex)
              end
              @output += "UPLOAD successful\n"   
            else
              @output += "Error: the upload file is not found\n"
              print(uploadfilepath)
            end
          end
        else
          @output += "Error: the repo does not exists\n"  
          print(repodir)            
        end
      end
      if @output.size <= 255 then 
          @output += "Ok: Requirements uploaded.\n"
          flash[:notice] = @output.to_s
      else
          flash[:notice] = "Message too long\n"
      end
      print(@output)
    end
  end

  def report
    print("\n\n\n\n\n\n")
    if request.get? then
      print("GET!!!!!")
    else
      print("POST!!!!!")
      splitted_url = request.fullpath.split('/cosmosys_reqs')
      root_url = request.base_url+splitted_url[0]      
      @output = ""
      # First we check if the setting for the local repo is set
      if (Setting.plugin_cosmosys_req['repo_local_path'].blank?) then
        # If it is not set, we can not continue
        @output += "Error: the local repos path template is not defined\n"
      else
        # The setting exists, so we can create the origin and destination paths
        repodir = "#{Setting.plugin_cosmosys_req['repo_local_path']}"
        repodir["%project_id%"] = @project.identifier
        # Now we have to know if the destination directory already exists
        if (File.directory?(repodir)) then
          if (Setting.plugin_cosmosys_req['relative_reporting_path'].blank?) then
            # If it is not set, we can not continue
            @output += "Error: the relative path to upload file is not set\n"
          else
            reportingpath = repodir + "/" + Setting.plugin_cosmosys_req['relative_reporting_path']
            if (File.directory?(reportingpath)) then
              imgpath = repodir + "/" + Setting.plugin_cosmosys_req['relative_img_path']
              if (File.directory?(imgpath)) then
                comando = "python3 plugins/cosmosys_req/assets/pythons/RqReports.py #{@project.id} #{reportingpath} #{imgpath} #{root_url}"
                print(comando)
		            #`#{comando}`
                require 'open3'

                stdin, stdout, stderr = Open3.popen3("#{comando}")
                stdin.close
                stdout.each do |ele|
                  print ("->"+ele+"\n")
                  @output += ele
                end
                diagrams_pattern = @@cfdiag.default_value
                diagrams_str_prefix = "{{graphviz_link()\n"
                diagrams_str_suffix = "\n}} "
                # Now we have to update all the diagrams
                # The projects diagram
                filepath = imgpath + "/" + @project.identifier.to_s
                d_filepath = filepath + "_d.gv"
                print d_filepath
                if (File.exists?(d_filepath)) then
                  diagrams_d_str = diagrams_str_prefix + IO.read(d_filepath) + diagrams_str_suffix
                  #print diagrams_d_str
                  h_filepath = filepath + "_h.gv"
                  print d_filepath
                  if (File.exists?(h_filepath)) then
                    diagrams_h_str = diagrams_str_prefix + IO.read(h_filepath) + diagrams_str_suffix
                    pattern = diagrams_pattern.dup                    
                    pattern['$$h'] = diagrams_h_str
                    pattern['$$d'] = diagrams_d_str
                    cf = @project.custom_values.find_by_custom_field_id(@@cfdiagpr.id)
                    cf.value = pattern
                    cf.save
                  else
                    print("h image file does not exist")
                  end
                else
                  print("d image file does not exist")
                end

                # And the issues diagram
                @project.issues.each{|i|
                  filepath = imgpath + "/" + i.id.to_s
                  d_filepath = filepath + "_d.gv"
                  print d_filepath
                  if (File.exists?(d_filepath)) then
                    diagrams_d_str = diagrams_str_prefix + IO.read(d_filepath) + diagrams_str_suffix
                    #print diagrams_d_str
                    h_filepath = filepath + "_h.gv"
                    print d_filepath
                    if (File.exists?(h_filepath)) then
                      diagrams_h_str = diagrams_str_prefix + IO.read(h_filepath) + diagrams_str_suffix
                      pattern = diagrams_pattern.dup                    
                      pattern['$$h'] = diagrams_h_str
                      pattern['$$d'] = diagrams_d_str
                      cf = i.custom_values.find_by_custom_field_id(@@cfdiag.id)
                      cf.value = pattern
                      cf.save
                    else
                      print("h image file does not exist")
                    end
                  else
                    print("d image file does not exist")
                  end
                }

                git_commit_repo(@project,"[reqbot] reports generated")
                git_pull_rm_repo(@project)
                @output += "Ok: reports generated and diagrams updated.\n"
              else
                @output += "Error: the img path is not found\n"
                print(imgpath)
              end
            else
              @output += "Error: the reporting path is not found\n"
              print(reportingpath)
            end
          end
        else
          @output += "Error: the repo does not exists\n"  
          print(repodir)            
        end
      end
      if @output.size <= 255 then 
        flash[:notice] = @output.to_s
      else
        flash[:notice] = "Message too long\n"
      end
      print(@output)
    end
  end

  def download
    print("\n\n\n\n\n\n")
    if request.get? then
      print("GET!!!!!")
    else
      print("POST!!!!!")
      git_pull_repo(@project)
      @output = ""
      # First we check if the setting for the local repo is set
      if (Setting.plugin_cosmosys_req['repo_local_path'].blank?) then
        # If it is not set, we can not continue
        @output += "Error: the local repos path template is not defined\n"
      else
        # The setting exists, so we can create the origin and destination paths
        repodir = "#{Setting.plugin_cosmosys_req['repo_local_path']}"
        repodir["%project_id%"]= @project.identifier
        # Now we have to know if the destination directory already exists
        if (File.directory?(repodir)) then
          if (Setting.plugin_cosmosys_req['relative_downloadfile_path'].blank?) then
            # If it is not set, we can not continue
            @output += "Error: the relative path to the downnload file is not set\n"
          else
            splitted_url = request.fullpath.split('/cosmosys_reqs')
            root_url = request.base_url+splitted_url[0]            
            downloadfilepath = repodir + "/" + Setting.plugin_cosmosys_req['relative_downloadfile_path']
            comando = "python3 plugins/cosmosys_req/assets/pythons/RqDownload.py #{@project.id} #{downloadfilepath} #{root_url}"
            require 'open3'
            print(comando)
            stdin, stdout, stderr = Open3.popen3("#{comando} &")
            stdin.close
            stdout.each do |ele|
              print ("->"+ele+"\n")
              @output += ele
            end
            print("acabo el comando")

            #`#{comando}`
            #p output
            git_commit_repo(@project,"[reqbot] downloadfile generated")
            git_pull_rm_repo(@project)
          end
        else
          @output += "Error: the repo does not exists\n"  
          print(repodir)            
        end
      end
      if @output.size <= 255 then 
          flash[:notice] = @output.to_s
      else
          flash[:notice] = "Message too long\n"
      end
      print(@output)
    end
  end

  def dstopimport
  end

  def dstopexport
  end

  def validate
  end

  def propagate
  end

  def tree
    require 'json'

    if request.get? then
      print("GET!!!!!")
      if (params[:node_id]) then
        print("NODO!!!\n")
        thisnodeid = params[:node_id]
      else
        print("PROYECTO!!!\n")     
        res = @project.issues.where(:parent => nil).limit(1)
        thisnodeid = res.first.id
      end
      thisnode=Issue.find(thisnodeid)

      splitted_url = request.fullpath.split('/cosmosys_reqs')
      print("\nsplitted_url: ",splitted_url)
      root_url = splitted_url[0]
      print("\nroot_url: ",root_url)
      print("\nbase_url: ",request.base_url)
      print("\nurl: ",request.url)
      print("\noriginal: ",request.original_url)
      print("\nhost: ",request.host)
      print("\nhost wp: ",request.host_with_port)
      print("\nfiltered_path: ",request.filtered_path)
      print("\nfullpath: ",request.fullpath)
      print("\npath_translated: ",request.path_translated)
      print("\noriginal_fullpath ",request.original_fullpath)
      print("\nserver_name ",request.server_name)
      print("\noriginal_fullpath ",request.original_fullpath)
      print("\npath ",request.path)
      print("\nserver_addr ",request.server_addr)
      print("\nhost ",request.host)
      print("\nremote_host ",request.remote_host)

      treedata = []

      tree_node = create_tree(thisnode,root_url)

      treedata << tree_node

      #print treedata


      respond_to do |format|
        format.html {
          if @output then 
            if @output.size <= 500 then
              flash[:notice] = "Reqtree:\n" + @output.to_s
            else
              flash[:notice] = "Reqtree too long response\n"
            end
          end
        }
        format.json { 
          require 'json'
          ActiveSupport.escape_html_entities_in_json = false
          render json: treedata
          ActiveSupport.escape_html_entities_in_json = true        
        }
      end
    else

      print("POST!!!!!")
      structure = params[:structure]
      json_params_wrapper = JSON.parse(request.body.read())
      structure = json_params_wrapper['structure']
      #print ("structure: \n\n")
      #print structure
      rootnode = structure[0]
      structure.each { |n|
        update_node(n,nil,"",1)
      }
      redirect_to :action => 'tree', :method => :get, :id => @project.id 
    end

  end


  # -------------------------- Filters and actions --------------------
  def update_node(n,p,prefix,ord)
    # n is node, p is parent
    node = Issue.find(n['id'])
    if (node != nil) then
      if (node.tracker == @@reqdoctracker) then
        nodechapter = node.custom_values.find_by_custom_field_id(@@cfchapter.id).value
      else
        nodechapter = prefix+ord.to_s.rjust(@@chapterdigits, "0")+"."
      end
      cfc = node.custom_values.find_by_custom_field_id(@@cfchapter.id)
      cfc.value = nodechapter
      cfc.save      
      if (p != nil) then
        parent = Issue.find(p)
        node.parent = parent
        node.save
      end
      ch = n['children']
      chord = 1
      if (ch != nil) then
         ch.each { |c| 
          update_node(c,node.id,nodechapter,chord)
          chord += 1
        }
      end
    end
  end


  def git_commit_repo(pr,a_message)
    @output = ""
    # First we check if the setting for the local repo is set
    if (Setting.plugin_cosmosys_req['repo_local_path'].blank?) then
      # If it is not set, we can not continue
      @output += "Error: the local repos path template is not defined\n"
    else
      # The repo local path is defined
      destdir = "#{Setting.plugin_cosmosys_req['repo_local_path']}"
      destdir["%project_id%"]= pr.identifier
      comando = "cd #{destdir}; git add ."
      print("\n\n #{comando}")
      `#{comando}`
      comando = "cd #{destdir}; git commit -m \"#{a_message}\""
      print("\n\n #{comando}")
      `#{comando}`

      # Now we have to push to a server repo
      # We must check if we have tu sync with a remote server
      if (Setting.plugin_cosmosys_req['repo_server_sync']) then
        # The setting says we must sync with a remote server
        if (Setting.plugin_cosmosys_req['repo_server_path'].blank?) then
          # The setting is not set, so we can not sync with the remote server
          @output += "Error: the remote server URL template is not defined\n"
        else
          remote_url = "#{Setting.plugin_cosmosys_req['repo_server_path']}"
          remote_url["%project_id%"] = pr.identifier
          comando = "cd #{destdir}; git remote add origin #{remote_url}"
          print("\n\n #{comando}")
          `#{comando}`
          comando = "cd #{destdir}; git pull origin master"
          print("\n\n #{comando}")
          `#{comando}`
          comando = "cd #{destdir}; git push -u origin --all; git push -u origin --tags"
          print("\n\n #{comando}")
          `#{comando}`
        end
      else
        # If the sync is not active, we can conclude that we must create the local repo
        @output += "Info: remote sync not enabled\n"
      end

    end
  end

  def git_pull_rm_repo(pr)
    # NOTE: ANOTHER ALTERNATIVE IS TO PUSH FROM THE NORMAL REPO
    # EXAMPLE: git push --mirror ../../redmine_repos/req_demo.git/
    if (Setting.plugin_cosmosys_req['repo_redmine_sync']) then
      # The setting says we must sync with a remote server
      if not(Setting.plugin_cosmosys_req['repo_redmine_path'].blank?) then
        redminerepodir = "#{Setting.plugin_cosmosys_req['repo_redmine_path']}"
        redminerepodir["%project_id%"] = pr.identifier
        comando = "cd #{redminerepodir}; git fetch --all"
        print("\n\n #{comando}")
        `#{comando}`
      end
    end                
  end

  def git_pull_repo(pr)
    @output = ""
    # First we check if the setting for the local repo is set
    if (Setting.plugin_cosmosys_req['repo_local_path'].blank?) then
      # If it is not set, we can not continue
      @output += "Error: the local repos path template is not defined\n"
    else
      # The repo local path is defined
      destdir = "#{Setting.plugin_cosmosys_req['repo_local_path']}"
      destdir["%project_id%"]= pr.identifier

      # Now we have to push to a server repo
      # We must check if we have tu sync with a remote server
      if (Setting.plugin_cosmosys_req['repo_server_sync']) then
        # The setting says we must sync with a remote server
        if (Setting.plugin_cosmosys_req['repo_server_path'].blank?) then
          # The setting is not set, so we can not sync with the remote server
          @output += "Error: the remote server URL template is not defined\n"
        else
          remote_url = "#{Setting.plugin_cosmosys_req['repo_server_path']}"
          remote_url["%project_id%"] = pr.identifier
          comando = "cd #{destdir}; git pull origin master"
          print("\n\n #{comando}")
          `#{comando}`
          git_pull_rm_repo(pr)
        end
      else
        # If the sync is not active, we can conclude that we must create the local repo
        @output += "Info: remote sync not enabled\n"
      end
    end
  end

def create_json(current_issue, root_url, include_doc_children,currentdoc)
    tree_node = current_issue.attributes.slice("id","tracker_id","subject","description","status_id","fixed_version_id","parent_id","root_id")

    tree_node[:chapter] = current_issue.custom_values.find_by_custom_field_id(@@cfchapter.id).value
    tree_node[:title] = current_issue.custom_values.find_by_custom_field_id(@@cftitle.id).value
    if (current_issue.tracker == @@reqdoctracker) then
    tree_node[:prefix] = current_issue.custom_values.find_by_custom_field_id(@@cfprefix.id).value
    else
    tree_node[:level] = current_issue.custom_values.find_by_custom_field_id(@@cflevel.id).value
    tree_node[:type] = current_issue.custom_values.find_by_custom_field_id(@@cftype.id).value
    tree_node[:sources] = current_issue.custom_values.find_by_custom_field_id(@@cfsources.id).value
    tree_node[:var] = current_issue.custom_values.find_by_custom_field_id(@@cfvar.id).value
    tree_node[:value] = current_issue.custom_values.find_by_custom_field_id(@@cfvalue.id).value
    tree_node[:rationale] = current_issue.custom_values.find_by_custom_field_id(@@cfrationale.id).value
    end
    if (current_issue.tracker == @@reqdoctracker) then
      currentdoc = current_issue
    end
    tree_node[:doc_id] = currentdoc.id
    tree_node[:children] = []

    childrenitems = current_issue.children.sort_by {|obj| obj.custom_values.find_by_custom_field_id(@@cfchapter.id).value}
    childrenitems.each{|c|
      if (c.tracker != @@reqdoctracker or include_doc_children) then
        child_node = create_json(c,root_url,include_doc_children,currentdoc)
        tree_node[:children] << child_node
      end
    }
    tree_node[:relations] = []
    current_issue.relations_from.where(:relation_type => 'blocks').each{|rl|
      tree_node[:relations] << rl.attributes.slice("issue_to_id")
    }
    tree_node[:relations_back] = []
    current_issue.relations_to.where(:relation_type => 'blocks').each{|rl|
      tree_node[:relations_back] << rl.attributes.slice("issue_id")
    }

    return tree_node
end

def create_tree(current_issue, root_url)
    output = ""
    output += ("\nissue: " + current_issue.subject)
    issue_url = root_url + '/issues/' + current_issue.id.to_s
    output += ("\nissue_url: " + issue_url.to_s)
    issue_new_url = root_url + '/projects/' + current_issue.project.identifier.to_s + '/issues/new?issue[parent_issue_id]=' + current_issue.id.to_s + '&issue[tracker_id]=' + @@reqtracker.id.to_s
    output += ("\nissue_new_url: " + issue_new_url.to_s)
    if (current_issue.tracker == @@reqdoctracker) then
      issue_new_doc_url = root_url + '/projects/' + current_issue.project.identifier.to_s + '/issues/new?issue[parent_issue_id]=' + current_issue.id.to_s + '&issue[tracker_id]=' + @@reqdoctracker.id.to_s
    else
      issue_new_doc_url = nil
    end
    output += ("\nissue_new_url: " + issue_new_doc_url.to_s)

    cftitlevalue = current_issue.custom_values.find_by_custom_field_id(@@cftitle.id).value
    cfchaptervalue = current_issue.custom_values.find_by_custom_field_id(@@cfchapter.id).value
    separator_idx = cfchaptervalue.rindex('-')
    cfchapterarraywrapper = [cfchaptervalue.slice(0..separator_idx), cfchaptervalue.slice((separator_idx+1)..-1)]
    #print(cfchapterarraywrapper)
    cfchapterstring = cfchapterarraywrapper[0]
    if (cfchapterarraywrapper[1] != nil) then 
      cfchapterarray = cfchapterarraywrapper[1].split('.')
      cfchapterarray.each { |e|
        cfchapterstring += e.to_i.to_s + "."
      }
    end
    tree_node = {'title':  cfchapterstring + " " + current_issue.subject + ": " + cftitlevalue,
             'subtitle': current_issue.description,
             'expanded': true,
             'id': current_issue.id.to_s,
             'return_url': root_url+'/cosmosys_reqs/'+current_issue.project.id.to_s+'/tree.json',
             'issue_show_url': issue_url,
             'issue_new_url': issue_new_url,
             'issue_new_doc_url': issue_new_doc_url,
             'issue_edit_url': issue_url+"/edit",
             'children': []
            }

    #print tree_node
    #print "children: " + tree_node[:children].to_s + "++++\n"

    childrenitems = current_issue.children.sort_by {|obj| obj.custom_values.find_by_custom_field_id(@@cfchapter.id).value}
    childrenitems.each{|c|
        child_node = create_tree(c,root_url)
        tree_node[:children] << child_node
    }

    return tree_node
  end



  def find_project
    # @project variable must be set before calling the authorize filter
    if (params[:node_id]) then
      @issue = Issue.find(params[:node_id])
      @project = @issue.project
    else
      if(params[:id]) then
        @project = Project.find(params[:id])
      else
        @project = Project.first
      end
    end
    #print("Project: "+@project.to_s+"\n")
  end

end

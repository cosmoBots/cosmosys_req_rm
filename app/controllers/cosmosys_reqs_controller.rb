class CosmosysReqsController < ApplicationController
  before_action :find_project#, :authorize, :except => [:tree]

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

  def show
  end

  def upload
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
          if (Setting.plugin_cosmosys_req['relative_uploadfile_path'].blank?) then
            # If it is not set, we can not continue
            @output += "Error: the relative path to upload file is not set\n"
          else
            uploadfilepath = repodir + "/" + Setting.plugin_cosmosys_req['relative_uploadfile_path']
            if (File.exists?(uploadfilepath)) then
              comando = "python3 plugins/cosmosys_req/assets/pythons/RqUpload.py #{@project.id} #{uploadfilepath}"
              output = `#{comando}`
              p output
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
                comando = "python3 plugins/cosmosys_req/assets/pythons/RqReports.py #{@project.id} #{reportingpath} #{imgpath}"
                @output = `#{comando}`
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
            downloadfilepath = repodir + "/" + Setting.plugin_cosmosys_req['relative_downloadfile_path']
            comando = "python3 plugins/cosmosys_req/assets/pythons/RqDownload.py #{@project.id} #{downloadfilepath}"
            output = `#{comando}`
            p output
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
      comando = "python3 plugins/cosmosys_req/assets/pythons/RqTree.py #{thisnodeid}"
      print(comando)
      require 'open3'
      require 'json'

      stdin, stdout, stderr = Open3.popen3("#{comando}")
      stdout.each do |ele|
        print ("ELE"+ele+"\n")
        @output = ele
        @jsonoutput = JSON.parse(ele)
      end

      respond_to do |format|
        format.html {
          if @output then 
            if @output.size <= 255 then
              flash[:notice] = "Reqtree:\n" + @output.to_s
            else
              flash[:notice] = "Reqtree too long response\n"
            end
          end
        }
        format.json { 
          require 'json'
          ActiveSupport.escape_html_entities_in_json = false
          render json: @jsonoutput
          ActiveSupport.escape_html_entities_in_json = true        
        }
      end
    else
      print("POST!!!!!")
      structure_vector = params[:structure].to_s
      st = structure_vector
      #structure_vector.each { |st|
        print("\n\n")
        print(st)
        structure = JSON.parse(st) 
        structure_node(structure,nil)
      #}
      
    end

  end



  # -------------------------- Filters and actions --------------------

  def structure_node(node_vector, parent_node)
      node_vector.each{|node|
        print(node.to_s+"\n")
        my_issue = Issue.find(node['id'].to_i)
        if (parent_node != nil) then
          my_issue.parent_issue = parent_node
        end
        node['children'].each{|c|
          structure_node(c,my_issue)
        }
      } 
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
    print("Project: "+@project.to_s+"\n")
  end

end

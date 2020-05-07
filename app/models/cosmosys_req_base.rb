class CosmosysReqBase < ActiveRecord::Base

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

  def self.word_wrap(text, line_width: 80, break_sequence: "\n")
    text.split("\n").collect! do |line|
      line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1#{break_sequence}").rstrip : line
    end * break_sequence
  end

  def self.cfchapter
    @@cfchapter
  end
  def self.cftitle
    @@cftitle
  end
  def self.cftype
    @@cftype
  end
  def self.reqtracker
    @@reqtracker
  end
  def self.reqdoctracker
    @@reqdoctracker
  end

  @@req_status_maturity = {
    'RqDraft': 1,
    'RqStable': 2,
    'RqApproved': 3,
    'RqIncluded': 3,
    'RqValidated': 3,
    'RqRejected': 0,
    'RqErased': 1,
    'RqZombie': 0
  }

  def self.get_descendents(n)
    result = []
    n.children.each{|c|
      result.append(c)
      result += self.get_descendents(c)
    }
    return result
  end

  @@req_maturity_propagation = ['RqZombie','RqDraft','RqStable','RqApproved']

  def self.dependence_validation(i)
    result = true
    if (i.tracker == @@reqtracker) then
      i.relations_to.each{|r|
        rel_issue = r.issue_from
        result = self.dependence_validation(rel_issue)
        if (result) then
          if (@@req_status_maturity[rel_issue.status.name.to_sym] < 
                @@req_status_maturity[i.status.name.to_sym]) then
            #print("\n\n**************")
            #print(i.id,": ",i.subject,": ",i.status,":",@@req_status_maturity[i.status.name].to_s)
            #print("\t-",r.relation_type,"-> ",rel_issue.subject," : ",rel_issue.status,":",@@req_status_maturity[rel_issue.status.name].to_s)
            #print("xxxxxxxxxxxx: Error.  el requisito dependiente está en estado ",i.status," mientras el requisito del que depende está en estado ",rel_issue.status)
            result = false
          end
        end
      }
    end
    #print("\n\nResult: "+result.to_s)
    return result 
  end

  def self.dependence_validation_from_id(id)
    i = Issue.find(id)
    self.dependence_validation(i)
  end

  def self.create_json(current_issue, root_url, include_doc_children,currentdoc)
    tree_node = current_issue.attributes.slice("id","tracker_id","subject","description","status_id","fixed_version_id","parent_id","root_id")
    tree_node[:valid] = self.dependence_validation(current_issue)
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
      tree_node[:relations_back] << rl.attributes.slice("issue_from_id")
    }

    return tree_node
  end



  def self.show_as_json(thisproject, node_id,root_url)
    require 'json'

    if (node_id != nil) then
      thisnode = thisproject.issues.find(node_id)
      roots = [thisnode]
    else    
      roots = thisproject.issues.where(:parent => nil)
    end

    treedata = {}

    treedata[:project] = thisproject.attributes.slice("id","name","identifier")
    treedata[:project][:url] = root_url
    treedata[:targets] = {}
    treedata[:statuses] = {}
    treedata[:trackers] = {}
    treedata[:reqdocs] = {}
    treedata[:reqs] = []

    reqdocs = thisproject.issues.where(:tracker => @@reqdoctracker).sort_by {|obj| obj.custom_values.find_by_custom_field_id(@@cfchapter.id).value}

    IssueStatus.all.each { |st| 
      treedata[:statuses][st.id.to_s] = st.name
    }

    Tracker.all.each { |tr| 
      treedata[:trackers][tr.id.to_s] = tr.name
    }

    thisproject.versions.each { |v| 
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
    return treedata
  end

  def self.update_node(n,p,prefix,ord)
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

  # -----------------------------------

  def self.to_graphviz_depupn(cl,n_node,n,upn,isfirst,torecalc,root_url,invocation_counter,force_end)
    if not (force_end) then
      if (self.dependence_validation(upn)) then
        colorstr = 'black'
      else
        colorstr = 'red'
      end
      upn_node = cl.add_nodes( upn.id.to_s, :label => "{ "+upn.subject+"|"+word_wrap(upn.custom_values.find_by_custom_field_id(@@cftitle.id).value, line_width: 12) + "}",
        :style => 'filled', :color => colorstr, :fillcolor => 'grey', :shape => 'record',
        :URL => root_url + "/issues/" + upn.id.to_s)
    else
      colorstr = 'blue'      
      upn_node = cl.add_nodes( upn.id.to_s, :label => "{ ... }",
        :style => 'filled', :color => colorstr, :fillcolor => 'grey', :shape => 'record',
        :URL => root_url + "/issues/" + upn.id.to_s)
    end
    cl.add_edges(upn_node, n_node, :color => :blue)
    if not (force_end) then
      if (invocation_counter < 5) then
        invocation_counter += 1
        max_rel = 6
        count_rel = 0
        upn.relations_to.each {|upn2|
          if (count_rel < max_rel) then
            cl,torecalc=self.to_graphviz_depupn(cl,upn_node,upn,upn2.issue_from,isfirst,torecalc,root_url,invocation_counter,force_end)
          else
            if (count == max_rel) then
              cl,torecalc=self.to_graphviz_depupn(cl,upn_node,upn,upn2.issue_from,isfirst,torecalc,root_url,invocation_counter,true)
            end
          end
        }
      end
    end
    if (isfirst) then
      torecalc[upn.id.to_s.to_sym] = upn.id
    end      
    return cl,torecalc
  end

  def self.to_graphviz_depdwn(cl,n_node,n,dwn,isfirst,torecalc,root_url,invocation_counter,force_end)
    if not (force_end) then
      if (self.dependence_validation(dwn)) then
        colorstr = 'black'
      else
        colorstr = 'red'
      end
      dwn_node = cl.add_nodes( dwn.id.to_s, :label => "{ "+dwn.subject+"|" + word_wrap(dwn.custom_values.find_by_custom_field_id(@@cftitle.id).value, line_width: 12) + "}",  
        :style => 'filled', :color => colorstr, :fillcolor => 'grey', :shape => 'record',
        :URL => root_url + "/issues/" + dwn.id.to_s)
    else
      colorstr = 'blue'
      dwn_node = cl.add_nodes( dwn.id.to_s, :label => "{ ... }",  
        :style => 'filled', :color => colorstr, :fillcolor => 'grey', :shape => 'record',
        :URL => root_url + "/issues/" + dwn.id.to_s)
    end
    cl.add_edges(n_node, dwn_node, :color => :blue)
    if not (force_end) then
      if (invocation_counter < 5) then
        invocation_counter += 1
        max_rel = 6
        count_rel = 0
        dwn.relations_from.each {|dwn2|
          if (count_rel < max_rel) then
            cl,torecalc=self.to_graphviz_depdwn(cl,dwn_node,dwn,dwn2.issue_to,isfirst,torecalc,root_url,invocation_counter, force_end)
          else
            if (count == max_rel) then
              cl,torecalc=self.to_graphviz_depdwn(cl,dwn_node,dwn,dwn2.issue_to,isfirst,torecalc,root_url,invocation_counter, true)
            end
          end
        }
      end
    end
    if (isfirst) then
      torecalc[dwn.id.to_s.to_sym] = dwn.id
    end  
    return cl,torecalc
  end

  def self.to_graphviz_depcluster(cl,n,isfirst,torecalc,root_url,invocation_counter)
    if ((n.tracker == @@reqdoctracker) or (n.custom_values.find_by_custom_field_id(@@cftype.id).value == "Info")) then
      shapestr = "record"
      desc = self.get_descendents(n)
      added_nodes = []
      desc.each { |e|
        if (e.relations.size>0) then
          labelstr = "{"+e.subject+"|"+word_wrap(e.custom_values.find_by_custom_field_id(@@cftitle.id).value, line_width: 12) + "}"      
          e_node = cl.add_nodes(e.id.to_s, :label => labelstr,  
            :style => 'filled', :color => 'black', :fillcolor => 'grey', :shape => shapestr,
            :URL => root_url + "/issues/" + e.id.to_s)
          e.relations_from.each {|r|
            if (not(desc.include?(r.issue_to))) then
              if (not(added_nodes.include?(r.issue_to))) then
                added_nodes.append(r.issue_to)
                ext_node = cl.add_nodes(r.issue_to.id.to_s,
                  :URL => root_url + "/issues/" + r.issue_to.id.to_s)
              end
            end
            cl.add_edges(e_node, r.issue_to_id.to_s, :color => 'blue')
          }
        end          
      }
      return cl,torecalc
    else
      if (self.dependence_validation(n)) then
        colorstr = 'black'
      else
        colorstr = 'red'
      end
      n_node = cl.add_nodes( n.id.to_s, :label => "{"+n.subject+"|"+word_wrap(n.custom_values.find_by_custom_field_id(@@cftitle.id).value, line_width: 12) + "}",  
        :style => 'filled', :color => colorstr, :fillcolor => 'green', :shape => 'record',
        :URL => root_url + "/issues/" + n.id.to_s)
      invocation_counter += 1
      max_rel = 6
      count_rel = 0
      n.relations_from.each{|dwn|
        if (count_rel < max_rel) then
          cl,torecalc=self.to_graphviz_depdwn(cl,n_node,n,dwn.issue_to,isfirst,torecalc,root_url, invocation_counter, false)
        else
          if (count_rel == max_rel) then
            cl,torecalc=self.to_graphviz_depdwn(cl,n_node,n,dwn.issue_to,isfirst,torecalc,root_url, invocation_counter, true)
          end
        end
        count_rel += 1
      }
      count_rel = 0      
      n.relations_to.each{|upn|
        
        if (count_rel < 6) then
          cl,torecalc=self.to_graphviz_depupn(cl,n_node,n,upn.issue_from,isfirst,torecalc,root_url, invocation_counter, false)
        else
          if (count_rel == 6) then
            cl,torecalc=self.to_graphviz_depupn(cl,n_node,n,upn.issue_from,isfirst,torecalc,root_url, invocation_counter, true)
          end
        end
        count_rel += 1        
      }
      return cl,torecalc
    end    
  end

  def self.to_graphviz_depgraph(n,isfirst,torecalc,root_url,invocation_counter)
    # Create a new graph
    g = GraphViz.new( :G, :type => :digraph,:margin => 0, :ratio => 'compress', :size => "9.5,30" )
    if ((n.tracker == @@reqdoctracker) or (n.custom_values.find_by_custom_field_id(@@cftype.id).value == "Info")) then
      labelstr = 'Dependences (in subtree)'
      colorstr = 'orange'
      fontnamestr = 'times italic'
    else
      labelstr = 'Dependences'
      colorstr = 'black'
      fontnamestr = 'times'      
    end    
    cl = g.add_graph(:clusterD, :fontname => fontnamestr, :label => labelstr, :labeljust => 'l', :labelloc=>'t', :margin=> '5', :color => colorstr)
    # Generate output image
    #g.output( :png => "hello_world.png" )
    invocation_counter += 1
    cl,torecalc = self.to_graphviz_depcluster(cl,n,isfirst,torecalc,root_url,invocation_counter)  
    return g,torecalc
  end



  def self.to_graphviz_hieupn(cl,n_node,n,upn,isfirst,torecalc,root_url)
    colorstr = 'black'
    if (upn.tracker == @@reqdoctracker) then
      shapestr = "note"
      labelstr = upn.subject+"\n----\n"+word_wrap(upn.custom_values.find_by_custom_field_id(@@cftitle.id).value, line_width: 12)
      fontnamestr = 'times italic'
    else
      shapestr = "record"
      if (upn.custom_values.find_by_custom_field_id(@@cftype.id).value == "Info") then
        labelstr = word_wrap(upn.custom_values.find_by_custom_field_id(@@cftitle.id).value, line_width: 12)
        fontnamestr = 'times italic'
      else            
        labelstr = "{"+upn.subject+"|"+word_wrap(upn.custom_values.find_by_custom_field_id(@@cftitle.id).value, line_width: 12) + "}"
        fontnamestr = 'times'
      end
    end    
    upn_node = cl.add_nodes( upn.id.to_s, :label => labelstr, :fontname => fontnamestr,
      :style => 'filled', :color => colorstr, :fillcolor => 'grey', :shape => shapestr,
      :URL => root_url + "/issues/" + upn.id.to_s)
    cl.add_edges(upn_node, n_node)
    if (upn.parent != nil) then
      cl,torecalc=self.to_graphviz_hieupn(cl,upn_node,upn,upn.parent,isfirst,torecalc,root_url)
    end
    if (isfirst) then
      torecalc[upn.id.to_s.to_sym] = upn.id
    end  
    return cl,torecalc
  end

  def self.to_graphviz_hiedwn(cl,n_node,n,dwn,isfirst,torecalc,root_url)
    colorstr = 'black'
    if (dwn.tracker == @@reqdoctracker) then
      shapestr = "note"
      labelstr = dwn.subject+"\n----\n"+dwn.custom_values.find_by_custom_field_id(@@cftitle.id).value
      fontnamestr = 'times italic'
    else
      shapestr = "record"
      if (dwn.custom_values.find_by_custom_field_id(@@cftype.id).value == "Info") then
        labelstr = dwn.custom_values.find_by_custom_field_id(@@cftitle.id).value    
        fontnamestr = 'times italic'
      else            
        labelstr = "{"+dwn.subject+"|"+dwn.custom_values.find_by_custom_field_id(@@cftitle.id).value + "}"      
        fontnamestr = 'times'
      end
    end
    dwn_node = cl.add_nodes( dwn.id.to_s, :label => labelstr, :fontname => fontnamestr, 
      :style => 'filled', :color => colorstr, :fillcolor => 'grey', :shape => shapestr,
      :URL => root_url + "/issues/" + dwn.id.to_s)
    cl.add_edges(n_node, dwn_node)
    dwn.children.each {|dwn2|
      cl,torecalc=self.to_graphviz_hiedwn(cl,dwn_node,dwn,dwn2,isfirst,torecalc,root_url)
    }
    if (isfirst) then
      torecalc[dwn.id.to_s.to_sym] = dwn.id
    end      
    return cl,torecalc
  end


  def self.to_graphviz_hiecluster(cl,n,isfirst,torecalc,root_url,invocation_counter)
    colorstr = 'black'
    if (n.tracker == @@reqdoctracker) then
      shapestr = "note"
      labelstr = word_wrap(n.subject+"\n----\n"+n.custom_values.find_by_custom_field_id(@@cftitle.id).value, line_width: 12)
      fontnamestr = 'times italic'      
    else
      shapestr = "record"
      if (n.custom_values.find_by_custom_field_id(@@cftype.id).value == "Info") then
        labelstr = word_wrap(n.custom_values.find_by_custom_field_id(@@cftitle.id).value, line_width: 12)
        fontnamestr = 'times italic'
      else            
        labelstr = "{"+n.subject+"|"+word_wrap(n.custom_values.find_by_custom_field_id(@@cftitle.id).value, line_width: 12) + "}"      
        fontnamestr = 'times'
      end
    end
    n_node = cl.add_nodes( n.id.to_s, :label => labelstr, :fontname => fontnamestr, 
      :style => 'filled', :color => colorstr, :fillcolor => 'green', :shape => shapestr,
      :URL => root_url + "/issues/" + n.id.to_s)
    n.children.each{|dwn|
      cl,torecalc=self.to_graphviz_hiedwn(cl,n_node,n,dwn,isfirst,torecalc,root_url)
    }
    if (n.parent != nil) then
      cl,torecalc=self.to_graphviz_hieupn(cl,n_node,n,n.parent,isfirst,torecalc,root_url)
    end
    return cl,torecalc
  end

  def self.to_graphviz_hiegraph(n,isfirst,torecalc,root_url,invocation_counter)
    # Create a new graph
    g = GraphViz.new( :G, :type => :digraph,:margin => 0, :ratio => 'compress', :size => "9.5,30" )
    cl = g.add_graph(:clusterD, :label => 'Hierarchy', :labeljust => 'l', :labelloc=>'t', :margin=> '5')
    invocation_counter += 1
    cl,torecalc = self.to_graphviz_hiecluster(cl,n,isfirst,torecalc,root_url,invocation_counter)
    return g,torecalc
  end

  def self.to_graphviz_graph_str(n,isfirst,torecalc,root_url)
    g,torecalc = self.to_graphviz_depgraph(n,isfirst,torecalc,root_url,1)
    result="{{graphviz_link()\n" + g.to_s + "\n}}"
    g2,torecalc = self.to_graphviz_hiegraph(n,isfirst,torecalc,root_url,1)
    result+=" {{graphviz_link()\n" + g2.to_s + "\n}}"
    return result,torecalc
  end

  def self.show_graphs(n,root_url)
    strdiag,torecalc = self.to_graphviz_graph_str(n,true,{},root_url)
    return strdiag
  end

  def self.show_graphs_pr(p,root_url)
    # Create a new hierarchy graph
    hg = GraphViz.new( :G, :type => :digraph,:margin => 0, :ratio => 'compress', :size => "9.5,30" )
    hcl = hg.add_graph(:clusterD, :label => 'Hierarchy', :labeljust => 'l', :labelloc=>'t', :margin=> '5') 

    # Create a new hierarchy graph
    dg = GraphViz.new( :G, :type => :digraph,:margin => 0, :ratio => 'compress', :size => "9.5,30" )
    dcl = dg.add_graph(:clusterD, :label => 'Dependences', :labeljust => 'l', :labelloc=>'t', :margin=> '5') 

    p.issues.each{|n|
      colorstr = 'black'
      if (n.tracker == @@reqdoctracker) then
        shapestr = "note"
        labelstr = n.subject+"\n----\n"+word_wrap(n.custom_values.find_by_custom_field_id(@@cftitle.id).value, line_width: 12)
        fontnamestr = 'times italic'
      else
        shapestr = "record"
        if (n.custom_values.find_by_custom_field_id(@@cftype.id).value == "Info") then
          labelstr = word_wrap(n.custom_values.find_by_custom_field_id(@@cftitle.id).value, line_width: 12)
          fontnamestr = 'times italic'
        else            
          labelstr = "{"+n.subject+"|"+word_wrap(n.custom_values.find_by_custom_field_id(@@cftitle.id).value, line_width: 12) + "}"      
          fontnamestr = 'times'
        end
      end
      hn_node = hcl.add_nodes( n.id.to_s, :label => labelstr, :fontname => fontnamestr, 
        :style => 'filled', :color => colorstr, :fillcolor => 'grey', :shape => shapestr,
        :URL => root_url + "/issues/" + n.id.to_s)
      n.children.each{|c|
        hcl.add_edges(hn_node, c.id.to_s)
      }
      if (n.relations.size>0) then
        dn_node = dcl.add_nodes( n.id.to_s, :label => labelstr, :fontname => fontnamestr,   
          :style => 'filled', :color => colorstr, :fillcolor => 'grey', :shape => shapestr,
          :URL => root_url + "/issues/" + n.id.to_s)
        n.relations_from.each {|r|
          dcl.add_edges(dn_node, r.issue_to_id.to_s, :color => 'blue')
        }
      end
    }

    result="{{graphviz_link()\n" + hg.to_s + "\n}}"
    result+=" {{graphviz_link()\n" + dg.to_s + "\n}}"

    return result
  end



end

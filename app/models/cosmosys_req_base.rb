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
  @@cfdiag = IssueCustomField.find_by_name('RqDiagrams')
  @@cfdiagpr = ProjectCustomField.find_by_name('RqDiagrams')

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
def self.cfdiag
  @@cfdiag
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

  def self.to_graphviz_depupn(cl,n_node,n,upn,isfirst,torecalc)
    if (self.dependence_validation(upn)) then
      colorstr = 'black'
    else
      colorstr = 'red'
    end
    upn_node = cl.add_nodes( "{ "+upn.subject+"|"+upn.custom_values.find_by_custom_field_id(@@cftitle.id).value + "}",
      :style => 'filled', :color => 'black', :fillcolor => 'grey', :shape => 'record',
      :URL => "./"+upn.id.to_s)
    cl.add_edges(upn_node, n_node, :color => :blue)
    upn.relations_to.each {|upn2|
      cl,torecalc=self.to_graphviz_depupn(cl,upn_node,upn,upn2.issue_from,isfirst,torecalc)
    }
    if (isfirst) then
      torecalc[upn.id.to_s.to_sym] = upn.id
    end      
    return cl,torecalc
  end

  def self.to_graphviz_depdwn(cl,n_node,n,dwn,isfirst,torecalc)
    if (self.dependence_validation(dwn)) then
      colorstr = 'black'
    else
      colorstr = 'red'
    end
    dwn_node = cl.add_nodes( "{ "+dwn.subject+"|"+dwn.custom_values.find_by_custom_field_id(@@cftitle.id).value + "}",  
      :style => 'filled', :color => colorstr, :fillcolor => 'grey', :shape => 'record',
      :URL => "./"+dwn.id.to_s)
    cl.add_edges(n_node, dwn_node, :color => :blue)
    dwn.relations_from.each {|dwn2|
      cl,torecalc=self.to_graphviz_depdwn(cl,dwn_node,dwn,dwn2.issue_to,isfirst,torecalc)
    }
    if (isfirst) then
      torecalc[dwn.id.to_s.to_sym] = dwn.id
    end  
    return cl,torecalc
  end

  def self.to_graphviz_depcluster(cl,n,isfirst,torecalc)
    if (self.dependence_validation(n)) then
      colorstr = 'black'
    else
      colorstr = 'red'
    end
    n_node = cl.add_nodes( "{"+n.subject+"|"+n.custom_values.find_by_custom_field_id(@@cftitle.id).value + "}",  
      :style => 'filled', :color => colorstr, :fillcolor => 'green', :shape => 'record',
      :URL => "./"+n.id.to_s)
    n.relations_from.each{|dwn|
      cl,torecalc=self.to_graphviz_depdwn(cl,n_node,n,dwn.issue_to,isfirst,torecalc)
    }
    n.relations_to.each{|upn|
      cl,torecalc=self.to_graphviz_depupn(cl,n_node,n,upn.issue_from,isfirst,torecalc)
    }
    return cl,torecalc
  end

  def self.to_graphviz_depgraph(n,isfirst,torecalc)
    # Create a new graph
    g = GraphViz.new( :G, :type => :digraph,:margin => 0, :ratio => 'compress', :size => "9.5,30" )
    cl = g.add_graph(:clusterD, :label => 'Dependences', :labeljust => 'l', :labelloc=>'t', :margin=> '5')
    # Generate output image
    #g.output( :png => "hello_world.png" )
    cl,torecalc = self.to_graphviz_depcluster(cl,n,isfirst,torecalc)  
    return g,torecalc
  end



  def self.to_graphviz_hieupn(cl,n_node,n,upn,isfirst,torecalc)
    colorstr = 'black'
    if (upn.tracker == @@reqdoctracker) then
      shapestr = "note"
      labelstr = upn.subject+"\n----\n"+upn.custom_values.find_by_custom_field_id(@@cftitle.id).value
    else
      shapestr = "record"
      labelstr = "{"+upn.subject+"|"+upn.custom_values.find_by_custom_field_id(@@cftitle.id).value + "}"      
    end    
    upn_node = cl.add_nodes( labelstr,
      :style => 'filled', :color => colorstr, :fillcolor => 'grey', :shape => shapestr,
      :URL => "./"+upn.id.to_s)
    cl.add_edges(upn_node, n_node)
    if (upn.parent != nil) then
      cl,torecalc=self.to_graphviz_hieupn(cl,upn_node,upn,upn.parent,isfirst,torecalc)
    end
    if (isfirst) then
      torecalc[upn.id.to_s.to_sym] = upn.id
    end  
    return cl,torecalc
  end

  def self.to_graphviz_hiedwn(cl,n_node,n,dwn,isfirst,torecalc)
    colorstr = 'black'
    if (dwn.tracker == @@reqdoctracker) then
      shapestr = "note"
      labelstr = dwn.subject+"\n----\n"+dwn.custom_values.find_by_custom_field_id(@@cftitle.id).value
    else
      shapestr = "record"
      labelstr = "{"+dwn.subject+"|"+dwn.custom_values.find_by_custom_field_id(@@cftitle.id).value + "}"      
    end
    dwn_node = cl.add_nodes( labelstr,  
      :style => 'filled', :color => colorstr, :fillcolor => 'grey', :shape => shapestr,
      :URL => "./"+dwn.id.to_s)
    cl.add_edges(n_node, dwn_node)
    dwn.children.each {|dwn2|
      cl,torecalc=self.to_graphviz_hiedwn(cl,dwn_node,dwn,dwn2,isfirst,torecalc)
    }
    if (isfirst) then
      torecalc[dwn.id.to_s.to_sym] = dwn.id
    end      
    return cl,torecalc
  end


  def self.to_graphviz_hiecluster(cl,n,isfirst,torecalc)
    colorstr = 'black'
    if (n.tracker == @@reqdoctracker) then
      shapestr = "note"
      labelstr = n.subject+"\n----\n"+n.custom_values.find_by_custom_field_id(@@cftitle.id).value
    else
      shapestr = "record"
      labelstr = "{"+n.subject+"|"+n.custom_values.find_by_custom_field_id(@@cftitle.id).value + "}"      
    end
    n_node = cl.add_nodes( labelstr,  
      :style => 'filled', :color => colorstr, :fillcolor => 'green', :shape => shapestr,
      :URL => "./"+n.id.to_s)
    n.children.each{|dwn|
      cl,torecalc=self.to_graphviz_hiedwn(cl,n_node,n,dwn,isfirst,torecalc)
    }
    if (n.parent != nil) then
      cl,torecalc=self.to_graphviz_hieupn(cl,n_node,n,n.parent,isfirst,torecalc)
    end
    return cl,torecalc
  end

  def self.to_graphviz_hiegraph(n,isfirst,torecalc)
    # Create a new graph
    g = GraphViz.new( :G, :type => :digraph,:margin => 0, :ratio => 'compress', :size => "9.5,30" )
    cl = g.add_graph(:clusterD, :label => 'Hierarchy', :labeljust => 'l', :labelloc=>'t', :margin=> '5')
    # Generate output image
    #g.output( :png => "hello_world.png" )
    cl,torecalc = self.to_graphviz_hiecluster(cl,n,isfirst,torecalc)
    return g,torecalc
  end

  def self.to_graphviz_graph_str(n,isfirst,torecalc)
    g,torecalc = self.to_graphviz_depgraph(n,isfirst,torecalc)
    result="{{graphviz_link()\n" + g.to_s + "\n}}"
    g2,torecalc = self.to_graphviz_hiegraph(n,isfirst,torecalc)
    result+=" {{graphviz_link()\n" + g2.to_s + "\n}}"
    return result,torecalc
  end

  def self.recalculate_graphs(n)
    strdiag,torecalc = self.to_graphviz_graph_str(n,true,{})
    cfd = n.custom_values.find_by_custom_field_id(CosmosysReqBase.cfdiag.id)
    cfd.value = strdiag
    cfd.save
    torecalc.each do |key, value|
      i = Issue.find(value)
      strdiag,torecalc2 = self.to_graphviz_graph_str(i,false,{})
      cfd = i.custom_values.find_by_custom_field_id(CosmosysReqBase.cfdiag.id)
      cfd.value = strdiag
      cfd.save      
    end
  end

  def self.show_graphs(n)
    strdiag,torecalc = self.to_graphviz_graph_str(n,true,{})
    return strdiag
  end

  def self.show_graphs_pr(p)
    result = ""
    p.issues.each{ |n|
      if n.parent == nil then
        result += self.show_graphs(n) + "\n\n"
      end
    }
    return result
  end



end

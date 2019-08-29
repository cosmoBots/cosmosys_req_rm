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

def self.create_json(current_issue, root_url, include_doc_children,currentdoc)
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






end

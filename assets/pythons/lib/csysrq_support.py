def draw_descendants(redmine,server_url,issue_id,graph,req_title_cf_id):
    my_issue = redmine.issue.get(issue_id)
    title_str = my_issue.custom_fields.get(req_title_cf_id).value
    nodelabel = "{"+my_issue.subject+"|"+title_str+"}"
    descr = getattr(my_issue, 'description', my_issue.subject)
    graph.node(str(my_issue.id),nodelabel,URL=server_url+'/issues/'+str(my_issue.id),tooltip=descr)
    #print(my_issue.id,": ",my_issue.subject)
    for child in my_issue.children:
        #print(child.id,": ",child.subject)
        my_child = redmine.issue.get(child.id)
        title_str = my_child.custom_fields.get(req_title_cf_id).value
        nodelabel = "{"+my_child.subject+"|"+title_str+"}"
        childdescr = getattr(my_child, 'description', my_child.subject)
        graph.node(str(child.id),nodelabel,URL=server_url+'/issues/'+str(child.id),tooltip=childdescr)
        graph.edge(str(my_issue.id),str(child.id))
        draw_descendants(redmine,server_url,child.id,graph,req_title_cf_id)
    
    return my_issue

def draw_ancestors(redmine,server_url,issue_id,child_id,graph,req_title_cf_id):
    my_issue = redmine.issue.get(issue_id)
    title_str = my_issue.custom_fields.get(req_title_cf_id).value
    nodelabel = "{"+my_issue.subject+"|"+title_str+"}"
    descr = getattr(my_issue, 'description', my_issue.subject)
    graph.node(str(my_issue.id),nodelabel,URL=server_url+'/issues/'+str(my_issue.id),tooltip=descr)
    graph.edge(str(my_issue.id),str(child_id))
    # https://stackoverflow.com/questions/37543513/read-the-null-value-in-python-redmine-api
    # Short answer: Use getattr(id, 'assigned_to', None) instead of id.assigned_to.
    current_parent = getattr(my_issue, 'parent', None)
    #print("my_issue: "+str(my_issue))
    if current_parent is not None:
        #print("parent: "+str(current_parent))
        draw_ancestors(redmine,server_url,current_parent,issue_id,graph,req_title_cf_id)
    
    return my_issue


def draw_postpropagation(redmine,server_url,issue_id,graph,tracker_id,req_title_cf_id):
    my_issue = redmine.issue.get(issue_id)
    if (my_issue.tracker.id == tracker_id):
        print("* Node post",my_issue)
        title_str = my_issue.custom_fields.get(req_title_cf_id).value
        nodelabel = "{"+my_issue.subject+"|"+title_str+"}"
        descr = getattr(my_issue, 'description', my_issue.subject)
        graph.node(str(my_issue.id),nodelabel,URL=server_url+'/issues/'+str(my_issue.id),tooltip=descr)
        #print(my_issue.id,": ",my_issue.subject)

        my_issue_relations = redmine.issue_relation.filter(issue_id=my_issue.id)
        #print(len(my_issue_relations))
        my_filtered_issue_relations = list(filter(lambda x: x.issue_to_id != my_issue.id, my_issue_relations))
        #print(len(my_filtered_issue_relations))
        if (len(my_filtered_issue_relations)>0):
            for r in my_filtered_issue_relations:
                related_element = redmine.issue.get(r.issue_to_id)
                # print("related_element: ",related_element," : ",related_element.tracker)
                if (related_element.tracker.id == tracker_id):
                    # print("\t"+r.relation_type+"\t"+str(r.issue_id)+"\t"+str(r.issue_to_id))
                    graph.edge(str(my_issue.id),str(r.issue_to_id),color="blue") 
                    draw_postpropagation(redmine,server_url,r.issue_to_id,graph,tracker_id,req_title_cf_id)

        
    return my_issue

            
def draw_prepropagation(redmine,server_url,issue_id,graph,tracker_id,req_title_cf_id):
    my_issue = redmine.issue.get(issue_id)
    if (my_issue.tracker.id == tracker_id):
        print("* Node pre",my_issue)
        title_str = my_issue.custom_fields.get(req_title_cf_id).value
        nodelabel = "{"+my_issue.subject+"|"+title_str+"}"
        graph.node(str(my_issue.id),nodelabel,URL=server_url+'/issues/'+str(my_issue.id),tooltip=title_str)
        my_issue_relations = redmine.issue_relation.filter(issue_id=my_issue.id)
        #print(len(my_issue_relations))
        my_filtered_issue_relations = list(filter(lambda x: x.issue_to_id == my_issue.id, my_issue_relations))
        #print(len(my_filtered_issue_relations))
        if (len(my_filtered_issue_relations)>0):
            print("len(my_filtered_issue_relations): ",len(my_filtered_issue_relations))
            for r in my_filtered_issue_relations:
                related_element = redmine.issue.get(r.issue_id)
                print("related pre",related_element)
                if (related_element.tracker.id == tracker_id):
                    #print("\t"+r.relation_type+"\t"+str(r.issue_id)+"\t"+str(r.issue_to_id))
                    graph.edge(str(r.issue_id),str(my_issue.id),color="blue")
                    draw_prepropagation(redmine,server_url,r.issue_id,graph,tracker_id,req_title_cf_id)

    return my_issue


######### generic utils

import shutil
import os

def copy_and_replace_dir(from_path, to_path):
    if os.path.exists(to_path):
        shutil.rmtree(to_path)
        print("existía y lo borré ya")

    shutil.copytree(from_path, to_path)
    
def copy_dir(src, dest):
    try:
        shutil.copytree(src, dest)
        
    # Directories are the same
    except shutil.Error as e:
        print('Directory not copied. Error: %s' % e)
    # Any error saying that the directory doesn't exist
    except OSError as e:
        print('Directory not copied. Error: %s' % e)
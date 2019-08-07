class CreateCosmosysReqBases < ActiveRecord::Migration[5.2]
	def up

		##### CREATE TABLES
		create_table :cosmosys_req_bases do |t|
			t.string :name
			t.integer :project_id
			t.integer :user_id			
			t.text :result
		end

		##### CREATE REDMINE OBJECTS
		# Roles
		manager = Role.create! :name => 'RqMngr',
		:issues_visibility => 'all',
		:users_visibility => 'all'
		manager.permissions = manager.setable_permissions.collect {|p| p.name}
		manager.save!

=begin
		manager.add_permission!(:download_cosmosys)
		manager.add_permission!(:dstopexport_cosmosys)
		manager.add_permission!(:dstopimport_cosmosys)
		manager.add_permission!(:view_cosmosys)
		manager.add_permission!(:propagate_cosmosys)
		manager.add_permission!(:report_cosmosys)
		manager.add_permission!(:tree_cosmosys)
		manager.add_permission!(:upload_cosmosys)
		manager.add_permission!(:validate_cosmosys)
		manager.save
=end

		writer = Role.create!  :name => 'RqWriter',
		:permissions => [:manage_versions,
			:manage_categories,
			:view_issues,
			:add_issues,
			:edit_issues,
			:view_private_notes,
			:set_notes_private,
			:manage_issue_relations,
			:manage_subtasks,
			:add_issue_notes,
			:save_queries,
			:view_documents,
			:view_wiki_pages,
			:view_wiki_edits,
			:edit_wiki_pages,
			:delete_wiki_pages,
			:view_files,
			:manage_files,
			:browse_repository,
			:view_changesets,
			:commit_access,
			:manage_related_issues,
			:download_cosmosys,
			:dstopexport_cosmosys,
			:dstopimport_cosmosys,
			:view_cosmosys,
			:propagate_cosmosys,
			:report_cosmosys,
			:tree_cosmosys,
			:upload_cosmosys,
			:validate_cosmosys
		]

		reviewer = Role.create! :name => 'RqReviewer',
		:permissions => [:view_issues,
			:add_issue_notes,
			:save_queries,
			:view_documents,
			:view_wiki_pages,
			:view_wiki_edits,
			:view_files,
			:browse_repository,
			:view_changesets,
			:download_cosmosys,
			:dstopexport_cosmosys,
			:dstopimport_cosmosys,
			:view_cosmosys,
			:propagate_cosmosys,
			:report_cosmosys,
			:tree_cosmosys,
			:upload_cosmosys,
			:validate_cosmosys
		]

		developer = Role.create! :name => 'RqDev',
		:permissions => [:view_issues,
			:add_issue_notes,
			:save_queries,
			:view_documents,
			:view_wiki_pages,
			:view_wiki_edits,
			:view_files,
			:browse_repository,
			:view_changesets,
			:dstopexport_cosmosys,
			:view_cosmosys,
			:report_cosmosys,
			:tree_cosmosys,
			:validate_cosmosys
		]

		tester = Role.create! :name => 'RqTest',
		:permissions => [:view_issues,
			:add_issue_notes,
			:save_queries,
			:view_documents,
			:view_wiki_pages,
			:view_wiki_edits,
			:view_files,
			:browse_repository,
			:view_changesets,
			:dstopexport_cosmosys,
			:view_cosmosys,
			:report_cosmosys,
			:tree_cosmosys,
			:validate_cosmosys
		]


		# Statuses
		stdraft = IssueStatus.create!(:name => 'RqDraft', :is_closed => false)
		ststable = IssueStatus.create!(:name => 'RqStable', :is_closed => false)
		stapproved = IssueStatus.create!(:name => 'RqApproved', :is_closed => false)
		stincluded = IssueStatus.create!(:name => 'RqIncluded', :is_closed => false)
		stvalidated = IssueStatus.create!(:name => 'RqValidated', :is_closed => true)
		strejected = IssueStatus.create!(:name => 'RqRejected', :is_closed => false)
		sterased = IssueStatus.create!(:name => 'RqErased', :is_closed => true)
		stzombie = IssueStatus.create!(:name => 'RqZombie', :is_closed => true)

		rqstatuses = [stdraft, ststable, stapproved, stincluded, stvalidated, 
			strejected, sterased, stzombie]

		# Trackers
		rqtrck = Tracker.create!(:name => 'Req',    
			:default_status_id => stdraft.id, 
			:is_in_chlog => true,  :is_in_roadmap => true)
		rqdoctrck = Tracker.create!(:name => 'ReqDoc', 
			:default_status_id => stdraft.id, 
			:is_in_chlog => true, :is_in_roadmap => true)

		trackers = [rqtrck, rqdoctrck]

		trackers.each{|t|

			# Writer transitions
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => writer.id, :old_status_id => stdraft.id, 
				:new_status_id => ststable.id)
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => writer.id, :old_status_id => stdraft.id, 
				:new_status_id => sterased.id)
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => writer.id, :old_status_id => stdraft.id, 
				:new_status_id => stzombie.id)
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => writer.id, :old_status_id => ststable.id, 
				:new_status_id => stdraft.id)
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => writer.id, :old_status_id => stzombie.id, 
				:new_status_id => stdraft.id)
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => writer.id, :old_status_id => stapproved.id, 
				:new_status_id => stdraft.id)
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => writer.id, :old_status_id => strejected.id, 
				:new_status_id => sterased.id)
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => writer.id, :old_status_id => strejected.id, 
				:new_status_id => stdraft.id)
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => writer.id, :old_status_id => stvalidated.id, 
				:new_status_id => stdraft.id)
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => writer.id, :old_status_id => stincluded.id, 
				:new_status_id => stdraft.id)


			# Reviewer transitions
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => reviewer.id, :old_status_id => ststable.id, 
				:new_status_id => stapproved.id)
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => reviewer.id, :old_status_id => ststable.id, 
				:new_status_id => strejected.id)

			# Developer transitions
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => developer.id, :old_status_id => stapproved.id, 
				:new_status_id => stincluded.id)
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => developer.id, :old_status_id => stincluded.id, 
				:new_status_id => stapproved.id)

			# Reviewer transitions
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => tester.id, :old_status_id => stincluded.id, 
				:new_status_id => stvalidated.id)
			WorkflowTransition.create!(:tracker_id => t.id,
				:role_id => tester.id, :old_status_id => stvalidated.id, 
				:new_status_id => stincluded.id)

			# Manager transitions
			rqstatuses.each { |os|
				rqstatuses.each { |ns|
					WorkflowTransition.create!(:tracker_id => t.id, 
						:role_id => manager.id, 
						:old_status_id => os.id, 
						:new_status_id => ns.id) unless os == ns
				}
			}
		}

		# Custom fields
		rqtitlefield = IssueCustomField.create!(:name => 'RqTitle', 
			:field_format => 'string', :searchable => true,
			:is_for_all => true, :tracker_ids => [rqtrck.id, rqdoctrck.id])

		rqtypefield = IssueCustomField.create!(:name => 'RqType', 
			:field_format => 'list', :possible_values => ['Info', 'Complex',
				'Opt','Mech','Hw','Sw'], 
				:is_filter => true,
				:is_for_all => true, :tracker_ids => [rqtrck.id])

		rqlevelfield = IssueCustomField.create!(:name => 'RqLevel', 
			:field_format => 'list', :possible_values => ['None', 'System',
				'Derived','External','Shared'], 
				:is_filter => true,
				:is_for_all => true, :tracker_ids => [rqtrck.id])

		rqrationalefield = IssueCustomField.create!(:name => 'RqRationale', 
			:field_format => 'text',
			:description => 'Diagrams of Hierarchy and Dependence',
			:min_length => '', :max_length => '', :regexp => '',
			:default_value => '', :is_required => false, 
			:is_filter => false, :searchable => true, 
			:visible => true, :role_ids => [],
			:full_width_layout => true, :text_formatting => "full",
			:is_for_all => true, :tracker_ids => [rqtrck.id])

		rqsrcfield = IssueCustomField.create!(:name => 'RqSources', 
			:field_format => 'string', :searchable => true,
			:is_for_all => true, :tracker_ids => [rqtrck.id])

		rqchapterfield = IssueCustomField.create!(:name => 'RqChapter', 
			:field_format => 'string', :searchable => false,
			:is_for_all => true, :tracker_ids => [rqtrck.id, rqdoctrck.id])

		rqvarfield = IssueCustomField.create!(:name => 'RqVar', 
			:field_format => 'string', :searchable => true,
			:is_for_all => true, :tracker_ids => [rqtrck.id])

		rqvaluefield = IssueCustomField.create!(:name => 'RqValue', 
			:field_format => 'string', :searchable => true,
			:is_for_all => true, :tracker_ids => [rqtrck.id])

		rqprefixfield = IssueCustomField.create!(:name => 'RqPrefix', 
			:field_format => 'string', :searchable => false,
			:is_for_all => true, :tracker_ids => [rqdoctrck.id])	


		link_str = "link"
		diagrams_pattern = "$$d $$h"
		prj_diagram_pattern = "$$d $$h"

		# Issue part
		# Create diagrams custom fields
		rqdiagramsfield = IssueCustomField.create!(:name => 'RqDiagrams', 
			:field_format => 'text',
			:description => 'Diagrams of Hierarchy and Dependence',
			:min_length => '', :max_length => '', :regexp => '',
			:default_value => diagrams_pattern, 
			:is_required => false, 
			:is_filter => false, :searchable => false, 
			:visible => true, :role_ids => [],
			:full_width_layout => true, :text_formatting => "full",
			:is_for_all => true, :tracker_ids => [rqtrck.id, rqdoctrck.id]
			)

		rqhiediaglink = IssueCustomField.create!(:name => 'RqHierarchyDiagram',
			:field_format => 'link', :description => "A link to the Hierarchy Diagram",
			:url_pattern => "/projects/%project_identifier%/repository/rq/raw/reporting/doc/img/%id%_h.gv.svg",
			:default_value => link_str,
			:is_for_all => true, :tracker_ids => [rqtrck.id, rqdoctrck.id])

		rqdepdiaglink = IssueCustomField.create!(:name => 'RqDependenceDiagram',
			:field_format => 'link', :description => "A link to the Dependence Diagram",
			:url_pattern => "/projects/%project_identifier%/repository/rq/raw/reporting/doc/img/%id%_d.gv.svg",
			:default_value => link_str,
			:is_for_all => true, :tracker_ids => [rqtrck.id, rqdoctrck.id])

		# Project part
		# Create diagrams custom fields
		rqprjdiagramsfield = ProjectCustomField.create!(:name => 'RqDiagrams', 
			:field_format => 'text',
			:description => 'Diagrams of Hierarchy and Dependence',
			:min_length => '', :max_length => '', :regexp => '',
			:default_value => prj_diagram_pattern, 
			:is_required => false, 
			:is_filter => false, :searchable => false, 
			:visible => true, :role_ids => [],
			:full_width_layout => true, :text_formatting => "full"
			)

		rqprjhiediaglink = ProjectCustomField.create!(:name => 'RqHierarchyDiagram',
			:field_format => 'link', :description => "A link to the Hierarchy Diagram",
			:url_pattern => "/projects/%project_identifier%/repository/rq/raw/reporting/doc/img/%project_identifier%_h.gv.svg",
			:default_value => link_str)

		rqprjdepdiaglink = ProjectCustomField.create!(:name => 'RqDependenceDiagram',
			:field_format => 'link', :description => "A link to the Dependence Diagram",
			:url_pattern => "/projects/%project_identifier%/repository/rq/raw/reporting/doc/img/%project_identifier%_d.gv.svg",
			:default_value => link_str)


		link_str = "link"
		url_pattern = "/cosmosys_reqs/%id%/tree"

		Issue.find_each{|i|
			if i.tracker == rqtrck or i.tracker == rqdoctrck then
				foundhie = false
				founddep = false
				founddiag = false
				foundtree = false
				i.custom_values.each{|cf|
					if cf.custom_field_id == rqhiediaglink.id then
						foundhie = true
						cf.value = link_str
						cf.save
					end
					if cf.custom_field_id == rqdepdiaglink.id then
						founddep = true
						cf.value = link_str
						cf.save
					end
					if cf.custom_field_id == rqdiagramsfield.id then
						founddiag = true
						cf.value = diagrams_pattern
						cf.save
					end
					if cf.custom_field_id == rqhiediaglink.id then
						foundtree = true
						cf.value = link_str
						cf.save
					end
				}
				if not foundhie then
					icv = CustomValue.new
					icv.custom_field = rqhiediaglink
					icv.customized = i
					icv.value = link_str
					icv.save
				end
				if not founddep then
					icv = CustomValue.new
					icv.custom_field = rqdepdiaglink
					icv.customized = i
					icv.value = link_str
					icv.save
				end
				if not founddiag then
					icv = CustomValue.new
					icv.custom_field = rqdiagramsfield
					icv.customized = i
					icv.value = diagrams_pattern
					icv.save
				end				
				if not foundtree then
					icv = CustomValue.new
					icv.custom_field = rqhiediaglink
					icv.customized = i
					icv.value = link_str
					icv.save
				end
			end
		}
		Project.find_each{|i|
			foundhie = false
			founddep = false
			founddiag = false
			i.custom_values.each{|cf|
				if cf.custom_field_id == rqprjhiediaglink.id then
					foundhie = true
					cf.value = link_str
					cf.save
				end
				if cf.custom_field_id == rqprjdepdiaglink.id then
					founddep = true
					cf.value = link_str
					cf.save
				end
				if cf.custom_field_id == rqprjdiagramsfield.id then
					founddiag = true
					cf.value = prj_diagram_pattern
					cf.save
				end

			}
			if not foundhie then
				icv = CustomValue.new
				icv.custom_field = rqprjhiediaglink
				icv.customized = i
				icv.value = link_str
				icv.save
			end
			if not founddep then
				icv = CustomValue.new
				icv.custom_field = rqprjdepdiaglink
				icv.customized = i
				icv.value = link_str
				icv.save
			end
			if not founddiag then
				icv = CustomValue.new
				icv.custom_field = rqprjdiagramsfield
				icv.customized = i
				icv.value = prj_diagram_pattern
				icv.save
			end
		}
	end

	def down
		rqtrck = Tracker.find_by_name('Req')
		rqdoctrck = Tracker.find_by_name('ReqDoc')

		# Issue part
		tmp = IssueCustomField.find_by_name('RqDiagrams')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('RqHierarchyDiagram')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('RqDependenceDiagram')
		if (tmp != nil) then
			tmp.destroy
		end
		# Project part
		tmp = ProjectCustomField.find_by_name('RqDiagrams')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = ProjectCustomField.find_by_name('RqHierarchyDiagram')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = ProjectCustomField.find_by_name('RqDependenceDiagram')
		if (tmp != nil) then
			tmp.destroy
		end

		tmp = IssueCustomField.find_by_name('RqTitle')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('RqType')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('RqLevel')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('RqRationale')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('RqSources')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('RqChapter')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('RqVar')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueCustomField.find_by_name('RqValue')
		if (tmp != nil) then
			tmp.destroy
		end

		tmp = IssueCustomField.find_by_name('RqPrefix')
		if (tmp != nil) then
			tmp.destroy
		end

		# Trackers
		if (rqtrck != nil) then
			WorkflowTransition.all.each{ |tr|
				if (tr.tracker == rqtrck) then
					tr.destroy
				end
			}
			rqtrck.destroy
		end
		if (rqdoctrck != nil) then
			WorkflowTransition.all.each{ |tr|
				if (tr.tracker == rqdoctrck) then
					tr.destroy
				end
			}
			rqdoctrck.destroy
		end
		tmp = IssueStatus.find_by_name('RqDraft')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueStatus.find_by_name('RqStable')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueStatus.find_by_name('RqApproved')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueStatus.find_by_name('RqIncluded')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueStatus.find_by_name('RqValidated')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueStatus.find_by_name('RqRejected')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueStatus.find_by_name('RqErased')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = IssueStatus.find_by_name('RqZombie')
		if (tmp != nil) then
			tmp.destroy
		end

		# Roles
		tmp = Role.find_by_name('RqWriter')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = Role.find_by_name('RqReviewer')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = Role.find_by_name('RqMngr')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = Role.find_by_name('RqDev')
		if (tmp != nil) then
			tmp.destroy
		end
		tmp = Role.find_by_name('RqTest')
		if (tmp != nil) then
			tmp.destroy
		end 
		drop_table :cosmosys_req_bases
	end
end

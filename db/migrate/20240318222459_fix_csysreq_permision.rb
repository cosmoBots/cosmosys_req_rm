class FixCsysreqPermision < ActiveRecord::Migration[5.2]
  def up
    rqtrck = Tracker.find_by_name('rq')

    manager = Role.find_by_name('rqMngr')
    writer = Role.find_by_name('rqWriter')
    reviewer = Role.find_by_name('rqReviewer')
    reader = Role.find_by_name('rqReader')

    read_permissions = [:csys_req_compmatrix, :csys_req_refdocs, :csys_req_apldocs, :csys_req_compdocs]
    read_roles = [manager,writer,reviewer,reader]

    read_roles.each{|r|
      r.permissions += read_permissions
      r.save
    }
    # END This is a fix
  end
end

require 'integration_test_helper'
require 'integration/shared/host_finders'

class HostIntegrationTest < ActionDispatch::IntegrationTest
  include HostFinders

  before do
    as_admin { @host = FactoryBot.create(:host, :managed) }
  end

  test "index page with search" do
    visit current_hosts_path(search: "name = #{@host.name}")
    assert page.has_link?('Export', href: current_hosts_path(format: 'csv', search: "name = #{@host.name}"))
  end

  describe "view host page" do
    test "host with .ics extension" do
      domain = FactoryBot.create(:domain, name: 'example.ics')
      host = FactoryBot.create(:host, domain: domain)
      visit host_details_page_path(host)
    end
  end

  describe "create new host page" do
    test "tabs are present" do
      assert_new_button(current_hosts_path, "Create Host", new_host_path)
      assert page.has_link?("Host", :href => "#primary")
      assert page.has_link?("Interfaces", :href => "#network")
      assert page.has_link?("Operating System", :href => "#os")
      assert page.has_link?("Parameters", :href => "#params")
      assert page.has_link?("Additional Information", :href => "#info")
    end
  end

  describe 'edit page' do
    test 'displays warning when vm not found by uuid' do
      ComputeResource.any_instance.stubs(:find_vm_by_uuid).raises(ActiveRecord::RecordNotFound)
      host = FactoryBot.create(:host, :with_hostgroup, :on_compute_resource, :managed)

      visit edit_host_path(host)
      assert page.has_link?('Operating System')
      click_link 'Operating System'

      alert_header = page.find('#compute_resource div.alert strong')
      alert_body = page.find('#compute_resource div.alert span.text')

      assert_equal "'#{host.name}' not found on '#{host.compute_resource}'", alert_header.text
      assert_equal "'#{host.name}' could be deleted or '#{host.compute_resource}' is not responding.", alert_body.text
    end
  end

  describe 'clone page' do
    test 'shows no errors on lookup values' do
      host = FactoryBot.create(:host)
      FactoryBot.create(:lookup_key, :with_override, path: "fqdn\ncomment", overrides: { host.lookup_value_matcher => 'test' })

      visit clone_host_path(host)
      assert page.has_link?('Parameters', :href => '#params')
      click_link 'Parameters'
      assert page.has_no_selector?('#params .has-error')
    end

    test 'clones root_pass' do
      host = FactoryBot.create(:host, :managed)
      visit clone_host_path(host)
      assert page.has_link?('Operating System', :href => '#os')
      click_link 'Operating System'
      root_pass = page.find("#host_root_pass")
      assert_equal host.root_pass, root_pass.value
    end

    test 'build mode is enabled for managed hosts' do
      host = FactoryBot.create(:host, :managed)
      visit clone_host_path(host)
      assert page.has_checked_field?('host_build')
    end

    test 'build mode is not enabled for unmanaged hosts' do
      host = FactoryBot.create(:host)
      visit clone_host_path(host)
      assert page.has_no_checked_field?('host_build')
    end
  end
end

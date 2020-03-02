################################################################################
# (C) Copyright 2016-2020 Hewlett Packard Enterprise Development LP
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

require_relative '../oneview_resource'

Puppet::Type.type(:oneview_volume_attachment).provide :c7000, parent: Puppet::OneviewResource do
  desc 'Provider for OneView Volume Attachments using the C7000 variant of the OneView API'

  confine feature: :oneview
  confine true: login[:hardware_variant] == 'C7000'

  mk_resource_methods

  def initialize(*args)
    super(*args)
    @vas = []
  end

  # Provider methods
  def exists?
    prepare_environment
    empty_data_check([nil, :found, :get_extra_unmanaged_volumes])
    # This method at the moment only has gets, CRUD operations are disabled at SDK
    resource['ensure'].to_s != 'present'
  end

  def found
    @data.empty? ? find_for_empty : find_for_server_profile
    true
  end

  def get_extra_unmanaged_volumes
    unmanaged_volumes_out = @resource_type.get_extra_unmanaged_volumes(@client)
    raise "\n\nNo Unmanaged volumes were found on the appliance.\n\n" if unmanaged_volumes_out.empty?
    extra_unmanaged_volumes = unmanaged_volumes_out['members']
    Puppet.notice "\n\nUnmanaged volumes:\n\n"
    extra_unmanaged_volumes.each do |unmanaged_volume|
      Puppet.notice "\n- #{unmanaged_volume['ownerUri']}\n"
    end
    true
  end

  def remove_extra_unmanaged_volume
    server_profile = OneviewSDK::ServerProfile.find_by(@client, name: @data['name']).first
    raise "\n\nSpecified Server Profile does not exist.\n" unless server_profile
    @resource_type.remove_extra_unmanaged_volume(@client, server_profile)
    true
  end

  # List extra unmanaged storage volumes
  def get_paths
    id = @data.delete('id')
    storage_volume_attachment = get_single_resource_instance
    if id
      get_path_by_id(storage_volume_attachment, id)
    else
      get_all_paths(storage_volume_attachment)
    end
    true
  end

  def get_path_by_id(storage_volume_attachment, id)
    volume_path = storage_volume_attachment.get_path(id)
    raise "No Storage Volume Attachment Paths found with id #{id} on #{storage_volume_attachment['name']}" unless volume_path
    Puppet.notice "\n\nPath from attachment with id #{id}: \n"
    Puppet.notice JSON.pretty_generate(volume_path).to_s
  end

  def get_all_paths(storage_volume_attachment)
    volume_paths = storage_volume_attachment.get_paths
    raise "\n\nNo Storage Volume Attachment Paths found with on #{storage_volume_attachment['name']}\n" if volume_paths.empty?
    Puppet.notice "\n\nPaths from storage attachment #{storage_volume_attachment['name']}:\n"
    volume_paths.each do |path|
      Puppet.notice("- #{path['initiatorName']}")
    end
  end

  def find_for_empty
    resource_name = @resource_type.to_s.split('::')
    vas = @resource_type.find_by(@client, {})
    raise "No #{resource_name[1]}s found on the appliance" if vas.empty?
    vas.each do |va|
      Puppet.notice "\n\n Found matching #{resource_name[1]} with the following info: \n"
      Puppet.notice JSON.pretty_generate(va.data).to_s
    end
  end

  def find_for_server_profile
    unless @data['name']
      raise "A 'name' tag must be specified within data, containing the server profile name and/or server profile name/volume name "\
        'to find a specific storage volume attachment'
    end
    vas, volume = helper_retrieve_vas
    vas.each do |va|
      @vas.push(va) if va['volumeUri'] == volume.first['uri']
    end
    raise 'No Volume Attachments matching the specified Server Profile name and Volume name were found.' if @vas.empty?
    Puppet.notice "The following Volume Attachment resources match the Server Profile name and Volume name informed: \n"
    Puppet.notice JSON.pretty_generate(@vas).to_s
  end

  def helper_retrieve_vas
    server_name, volume_name = @data['name'].split(',').map(&:strip)
    raise 'A server profile name has not been provided' unless server_name
    raise 'A volume name has not been provided' unless volume_name
    server_profile = OneviewSDK::ServerProfile.find_by(@client, name: server_name)
    raise "A server profile with the name #{server_name} could not be found on the appliance" if server_profile.empty?
    vas = server_profile.first.data['sanStorage']['volumeAttachments']
    raise 'No Volume Attachments found on the specified Server Profile' if vas.empty?
    volume = OneviewSDK::Volume.find_by(@client, name: volume_name)
    raise "A volume with the name #{volume_name} could not be found on the appliance" if volume.empty?
    [vas, volume]
  end
end

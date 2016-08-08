################################################################################
# (C) Copyright 2016 Hewlett Packard Enterprise Development LP
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

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'login'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'common'))
require 'oneview-sdk'

Puppet::Type.type(:oneview_power_device).provide(:ruby) do
  mk_resource_methods

  def initialize(*args)
    super(*args)
    @client = OneviewSDK::Client.new(login)
    @resourcetype = OneviewSDK::PowerDevice
    @data = {}
  end

  def exists?
    @data = data_parse
    empty_data_check
    pd_uri_parser
    variable_assignments
    !@resourcetype.find_by(@client, @data).empty?
  end

  def create
    return true if resource_update(@data, @resourcetype)
    @resourcetype.new(@client, @data).add
  end

  # Remove
  def destroy
    pd = @resourcetype.find_by(@client, @data)
    raise('There were no matching Power Devices in the Appliance.') if pd.empty?
    pd.map(&:remove)
  end

  def found
    find_resources
  end

  def discover
    pd = @resourcetype.discover(@client, @data)
    Puppet.notice("IPDU #{pd['name']} has been discovered!")
  end

  def set_refresh_state
    raise('The refresh options need to be specified in the manifest.') unless @refresh_options
    pd = @resourcetype.find_by(@client, unique_id)
    pd.first.set_refresh_state(@refresh_options)
  end

  def set_power_state
    raise('The power state needs to be specified in the manifest.') unless @power_state
    pd = @resourcetype.find_by(@client, unique_id)
    pd.first.set_power_state(@power_state)
  end

  def set_uid_state
    raise('The uid state needs to be specified in the manifest.') unless @uid_state
    pd = @resourcetype.find_by(@client, unique_id)
    pd.first.set_uid_state(@uid_state)
  end

  def get_uid_state
    pd = @resourcetype.find_by(@client, unique_id)
    pretty pd.first.get_uid_state
  end

  def get_utilization
    raise('The query parameters need to be specified in the manifest.') unless @query_parameters
    pd = @resourcetype.find_by(@client, unique_id)
    parameters = if @query_parameters
                   @query_parameters
                 else
                   {}
                 end
    pretty pd.first.utilization(parameters)
  end

  # Gets values from @data and deletes them, if they're available
  def variable_assignments
    @refresh_options = @data.delete('refreshOptions') if @data['refreshOptions']
    @power_state = @data.delete('powerState') if @data['powerState']
    @uid_state = @data.delete('uidState') if @data['uidState']
    @query_parameters = @data.delete('queryParameters') if @data['queryParameters']
  end

  # Retrieves the connection uri in case it has not been specified
  def pd_uri_parser
    if @data['powerConnections']
      @data['powerConnections'].each do |pc|
        next if pc['connectionUri']
        type = pc.delete('connectionType')
        name = pc.delete('connectionName')
        uri = objectfromstring(type).find_by(@client, name: name)
        raise('The connection uri could not be found in the Appliance.') unless uri.first
        pc['connectionUri'] = uri.first.data['uri']
      end
    end
  end
end

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

# The uID and power state operations (commented-out blocks at the bottom)
# are not supported by all Power Device models

oneview_power_device{'Power Device Discover':
  ensure => 'discover',
  data   =>
  {
    hostname => '172.18.8.11',
    username => 'dcs',
    password => 'dcs'
  }
}

# Optional filters
oneview_power_device{'Power Device Found':
  ensure => 'found'
  # data   =>
  # {
  #   name => '172.18.8.11, PDU 1'
  # }
}

oneview_power_device{'Power Device Refresh':
  ensure => 'set_refresh_state',
  data   =>
  {
    name           => '172.18.8.11, PDU 1',
    refreshOptions =>
    {
      refreshState => 'RefreshPending',
      username     => 'dcs',
      password     => 'dcs'
    }
  }
}

# Optional filters
oneview_power_device{'Power Device Get Utilization':
  ensure => 'get_utilization',
  data   =>
  {
    name            => '172.18.8.11, PDU 1',
    queryParameters =>
    {
      fields    => ['AveragePower']
      # startDate => '2016-07-31T15:10:00.000Z',
      # endDate   => '2016-07-31T15:10:00.000Z'
    }
  }
}

# Caution: more than one Power Device can be deleted at once by adding optional filters
oneview_power_device{'Power Device Remove':
  ensure  => 'absent',
  require => Oneview_power_device['Power Device Discover'],
  data    =>
  {
    name => '172.18.8.11, PDU 1'
  }
}

# oneview_power_device{'Power Device Set Power State':
#   ensure => 'set_power_state',
#   data   =>
#   {
#     name       => '172.18.8.11, PDU 1',
#     powerState => 'On'
#   }
# }

# oneview_power_device{'Power Device Get UID State':
#   ensure => 'get_uid_state',
#   data   =>
#   {
#     name => '172.18.8.11, PDU 1'
#   }
# }
#
# oneview_power_device{'Power Device Set UID State':
#   ensure => 'set_uid_state',
#   data   =>
#   {
#     name     => '172.18.8.11, PDU 1',
#     uidState => 'On'
#   }
# }

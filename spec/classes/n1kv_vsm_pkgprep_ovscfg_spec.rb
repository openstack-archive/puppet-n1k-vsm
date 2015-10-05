#
# Copyright (C) 2015 eNovance SAS <licensing@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#

require 'spec_helper'

describe 'n1k_vsm::pkgprep_ovscfg' do

  let :params do
    {  }
  end

  shared_examples_for 'n1k vsm pkgprep_ovscfg' do

    context 'for default values' do
      let :pre_condition do
        "class { 'n1k_vsm':
           phy_if_bridge     => 'eth0',
           phy_gateway       => '1.1.1.3',
           vsm_domain_id     => '1',
           vsm_admin_passwd  => 'secrete',
           vsm_mgmt_ip       => '1.1.1.1',
           vsm_mgmt_netmask  => '255.255.255.0',
           vsm_mgmt_gateway  => '1.1.1.2',
           existing_bridge   => false,
         }"
      end

      it 'should require vswitch::ovs' do
         is_expected.to contain_class('vswitch::ovs')
      end

      it 'create ovs bridge' do
        is_expected.to contain_augeas('Augeas_modify_ifcfg-ovsbridge').with(
          'name'    => 'vsm-br',
          'context' => '/files/etc/sysconfig/network-scripts/ifcfg-vsm-br',
        )
      end

      it 'flap bridge' do
        is_expected.to contain_exec('Flap_n1kv_bridge').with(
          'command'  => '/sbin/ifdown vsm-br && /sbin/ifup vsm-br',
        )
      end

      it 'attach phy if port to bridge' do
        is_expected.to contain_augeas('Augeas_modify_ifcfg-phy_if_bridge').with(
          'name'    => 'eth0',
          'context' => '/files/etc/sysconfig/network-scripts/ifcfg-eth0',
        )
      end

      it 'flap port' do
        is_expected.to contain_exec('Flap_n1kv_phy_if').with(
          'command'  => '/sbin/ifdown eth0 && /sbin/ifup eth0',
        )
      end
    end

    context 'for existing bridge' do
      let :pre_condition do
        "class { 'n1k_vsm':
           phy_if_bridge     => 'br-ex',
           phy_gateway       => '1.1.1.3',
           vsm_domain_id     => '1',
           vsm_admin_passwd  => 'secrete',
           vsm_mgmt_ip       => '1.1.1.1',
           vsm_mgmt_netmask  => '255.255.255.0',
           vsm_mgmt_gateway  => '1.1.1.2',
           existing_bridge   => true,
         }"
      end

      it 'should require vswitch::ovs' do
         is_expected.to contain_class('vswitch::ovs')
      end

      it 'create ovs bridge' do
        is_expected.to contain_augeas('Augeas_modify_ifcfg-ovsbridge').with(
          'name'    => 'vsm-br',
          'context' => '/files/etc/sysconfig/network-scripts/ifcfg-vsm-br',
        )
      end

      it 'flap bridge' do
        is_expected.to contain_exec('Flap_n1kv_bridge').with(
          'command'  => '/sbin/ifdown vsm-br && /sbin/ifup vsm-br',
        )
      end

      it 'create patch port on existing bridge' do
        is_expected.to contain_exec('Create_patch_port_on_existing_bridge').with(
          'command' => '/bin/ovs-vsctl --may-exist add-port br-ex br-ex-vsm-br -- set Interface br-ex-vsm-br type=patch options:peer=vsm-br-br-ex'
        )
      end

      it 'create patch port on vsm bridge' do
        is_expected.to contain_exec('Create_patch_port_on_vsm_bridge').with(
          'command' => '/bin/ovs-vsctl --may-exist add-port vsm-br vsm-br-br-ex -- set Interface vsm-br-br-ex type=patch options:peer=br-ex-vsm-br'
        ) 
      end 
    end
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'n1k vsm pkgprep_ovscfg'
  end

end


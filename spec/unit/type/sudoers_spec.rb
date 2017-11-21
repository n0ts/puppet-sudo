require 'spec_helper'

describe Puppet::Type.type(:sudoers) do
  before(:each) do
    @sudoers = Puppet::Type.type(:sudoers).new(:name => 'default')
  end

  it "should exist" do
    expect(@sudoers).not_to eq(nil)
  end

  it "should not have valid attributes that are nil" do
    expect(@sudoers[:target]).not_to eq(nil)
    expect(@sudoers[:comment]).not_to eq(nil)
  end

  describe 'shared attributes' do
    describe 'ensure' do
      it 'should only accept absent/present' do
        @sudoers[:ensure] = :present
        expect(@sudoers[:ensure]).to eq(:present)

        @sudoers[:ensure] = :absent
        expect(@sudoers[:ensure]).to eq(:absent)

        expect {
          @sudoers[:ensure] = :not_present
        }.to raise_error(Puppet::ResourceError, /Invalid value :not_present/)
      end
    end
    describe 'comment attribute' do
      it 'should accept a value' do
        @sudoers[:comment] = 'mycomment'
        expect(@sudoers[:comment]).to eq('mycomment')
      end
      it 'should default to empty string' do
        expect(@sudoers[:comment]).to eq('')
      end
    end
    describe 'name attribute' do
      it 'should accept a value' do
        expect(@sudoers[:name]).to eq('default')
      end
      it 'should be required' do
        expect {
          @sudoers[:name] = nil
        }.to raise_error(Puppet::Error, /Got nil value for name/)
      end
    end
  end

  describe 'the user alias' do
    describe 'require attributes' do
      it 'cmd' do
        expect {
          described_class.new(:name => 'sudo_alias_only', :type => 'alias', :items => 'items')
        }.to raise_error(Puppet::Error, /missing attribute sudo_alias for type alias/)
      end
    end
    describe "sudo_alias" do
      it "should only accept certain aliases" do
        expect {
          %w( Cmnd Host User Runas
              Cmnd_Alias Host_Alias User_Alias Runas_Alias ).each do |sudo_alias|
            described_class.new(:name => 'sudo_alias', :sudo_alias => sudo_alias)
          end
        }.not_to raise_error
      end
    end
    describe 'items' do
      it 'should be required' do
        expect {
          described_class.new(:name => 'sudo_items', :type => 'alias', :sudo_alias => 'sudo_alias')
        }.to raise_error(Puppet::Error, /Invalid value "sudo_alias"/)
      end
      it 'should take a single element' do
        @sudoers[:items] = 'one'
        expect(@sudoers[:items]).to eq(['one'])
      end
      it 'should take a single element array' do
        @sudoers[:items] = ['one']
        expect(@sudoers[:items]).to eq(['one'])
      end
      it 'should take an array' do
        @sudoers[:items] = ['one', 'two']
        expect(@sudoers[:items]).to eq(['one', 'two'])
      end
    end
    describe 'type' do
      it 'should not accept other type' do
        expect {
          described_class.new(:name => 'bad_type', :type => 'bad_type')
        }.to raise_error(Puppet::Error, /unexpected sudoers type bad_type/)
      end
      it 'should not accept other type' do
        expect {
          described_class.new(:name => 'user_spec', :type => 'user_spec')
        }.to raise_error(Puppet::Error, /missing attribute users for type user_spec/)
      end
    end
    describe 'name' do
      it 'should only accept [A-Z]([A-Z][0-9]_)*' do
        expect {
          described_class.new(:name => 'type', :type => 'alias', :sudo_alias => 'Cmnd', :items => 'items')
        }.to raise_error(Puppet::Error, /Validation of Sudoers\[type\] failed: alias names type does not match \[A-Z\](\[A-Z\]\[0-9\]_)*/)
      end
    end
  end

  describe 'sudo defaults' do
    describe 'parameters' do
      it 'should take a single element' do
        @sudoers[:parameters] = 'one'
        expect(@sudoers[:parameters]).to eq(['one'])
      end
      it 'should take a single element array' do
        @sudoers[:parameters] = ['one']
        expect(@sudoers[:parameters]).to eq(['one'])
      end
      it 'should take an array' do
        @sudoers[:parameters] = ['one', 'two']
        expect(@sudoers[:parameters]).to eq(['one', 'two'])
      end
      it 'should require a parameter' do
        sudo = described_class.new(:name => 'parameters', :parameters => 'one')
        expect(sudo[:parameters]).to eq(['one'])
      end
    end
  end

  describe 'user specs' do
    describe 'users' do
      it 'should accept an array' do
        @sudoers[:users] = ['alice', 'bob']
        expect(@sudoers[:users]).to eq(['alice', 'bob'])
      end
      it 'should not accept Defaults' do
        expect {
          described_class.new(:name => 'defaults', :users => 'Defaults')
        }.to raise_error(Puppet::Error, /Cannot specify user named Defaults in sudoers/)
      end
      it 'should be required' do
        expect {
          described_class.new(:name => 'users', :type => 'user_spec')
        }.to raise_error(Puppet::Error, /missing attribute users for type user_spec/)
      end
    end
    describe 'hosts' do
      it 'should accept an array' do
        @sudoers[:hosts] = ['alice', 'bob']
        expect(@sudoers[:hosts]).to eq(['alice', 'bob'])
      end
      it 'should be required' do
        expect {
          described_class.new(:name => 'hosts', :type => 'user_spec',
                              :users => 'uers', :commands => 'commands')
        }.to raise_error(Puppet::Error, /missing attribute hosts for type user_spec/)
      end
    end
    describe 'commands' do
      it 'should accept an array' do
        @sudoers[:commands] = ['alice', 'bob']
        expect(@sudoers[:commands]).to eq(['alice', 'bob'])
      end
      it 'should be required' do
        expect {
          described_class.new(:name => 'commands', :type => 'user_spec',
                              :hosts => 'hosts', :users => 'users')
        }.to raise_error(Puppet::Error, /missing attribute commands for type user_spec/)
      end
    end
  end
end

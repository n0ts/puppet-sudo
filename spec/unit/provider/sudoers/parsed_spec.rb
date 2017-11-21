require 'spec_helper'

describe Puppet::Type.type(:sudoers).provider(:parsed) do
  include ParsedHelper

  before(:each) do
    @provider = Puppet::Type.type(:sudoers).provider(:parsed)
    @init_records = {}
  end

  it 'should not be nil' do
    expect(@provider).not_to eq(nil)
  end

  describe 'when parsing a line' do
    describe 'when the line is a default' do
      before do
        @init_records = { :type => 'default' }
        @params_hash = { :name => 'Defaults', :parameters => ['param', 'param2'] }
      end
      ['Defaults', 'Defaults@host', 'Defaults:user_list', 'Defaults>runlist'].each do |d|
        it "should parse default #{d} with a single parameter" do
          parse_line_helper("#{d} param", {
                              :name => d,
                              :parameters => ['param'],
                            })
        end
      end
      it 'should parse a parameter list' do
        parse_line_helper('Defaults param,param2', @params_hash)
      end
      it 'should parse a parameter list with spaces' do
        parse_line_helper('Defaults param,  param2', @params_hash)
      end
      it 'should not care about spaces before and after' do
        parse_line_helper(' Defaults  param,  param2 ', @params_hash)
      end
    end

    describe 'when the line is an alias' do
      before do
        @init_records = { :type => 'alias', :name => 'NAM3_1' }
      end
       ['User_Alias', 'Runas_Alias', 'Host_Alias', 'Cmnd_Alias'].each do |a|
        it "should parse a(n) #{a}" do
          parse_line_helper("#{a} NAM3_1 = var",
                            { :items => ['var'], :sudo_alias => a })
        end
      end
      it 'should parse a list' do
        parse_line_helper('User_Alias NAM3_1 = var,var2',
                          { :sudo_alias => 'User_Alias', :items => ['var', 'var2'] })
      end
    end
    describe 'when the line is a user spec' do
      before do
        @init_records = { :type => 'user_spec' }
      end
      it 'should require user and host' do
        expect { @provider.parse_line('x = y') }.to raise_error(Puppet::Error)
      end
      it 'should call my function' do
        parse_line_helper('x y = z',
                          { :users => ['x'], :hosts => ['y'], :commands => ['z'] })
      end
    end
    describe 'when parsing a comment' do
      it 'should parse comments' do
        parse_line_helper('# something!!', { :comment => ' something!!' })
      end
      it 'should parse out a namevar line' do
        parse_line_helper('# Puppet NAMEVAR foo', { :name => 'foo' })
      end
    end
  end

  describe 'when processing prefetch hook' do
    # test that namevar is consumed from previous line
    it 'should use previous namevar as :name for user spec' do
      allow(@provider).to receive(:retrieve).and_return([
                                                         { :record_type => :comment, :name => 'foo' },
                                                         { :record_type => :parsed, :type => 'user_spec' },
                                                        ])

      records = @provider.prefetch_target('foo')
      expect(records.size).to eq(1)
      expect(records.last[:name]).to eq('foo')
    end
    it 'should supply a fakenamevar if one is missing' do
      allow(@provider).to receive(:retrieve).and_return([
                                                         { :record_type => :parsed, :type => 'user_spec' }
                                                        ])
      records = @provider.prefetch_target('foo')
      expect(records[0][:name]).to eq('fake_namevar_0')
      allow(@provider).to receive(:retrieve).and_return([
                                                         { :record_type => :parsed, :type => 'user_spec' }
                                                        ])
      records = @provider.prefetch_target('foo')
      expect(records[0][:name]).to eq('fake_namevar_0')
    end
    # there is some crazy code that tries to associate comments with types
  end

  describe 'when writing out the target files' do
    # test to_line
  end

  context "failing for commands containing =", :issue => 2 do
    before do
      @init_records = { :type => 'user_spec' }
    end

    it "can parse users and hosts for lines containing =" do
      line = "root ALL=(ALL) NOPASSWD: /bin/grep --color=auto example /var/log/messages"
      expect {
        @provider.parse_line(line)
      }.to_not raise_error
    end
  end
end

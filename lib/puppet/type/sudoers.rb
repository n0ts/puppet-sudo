Puppet::Type.newtype(:sudoers) do
  @doc = "Manage the contents of /etc/sudoers

Author:: Dan Bode (dan@reductivelabs.com)
Copyright:: BLAH!!
License:: GPL3

= Summary

The sudoers type supports managing individual lines from the sudoers file.

Supports present/absent.

supports purging.

= Record Types

There are 3 types of records that are supported:

== Aliases:

Manages an alias line of a sudoers file.

Example:

sudoers { 'ALIAS_NAME':
  ensure     => present,
  sudo_alias => 'Cmnd',
  items      => ['/bin/true', '/usr/bin/su - bob'],
}

creates the following line:

Cmnd_Alias ALIAS_NAME=/bin/true,/usr/bin/su - bob

== User Specification

sudoers line that specifies how users can run commands.

This there is no way to clearly determine uniqueness, a comment line is added above user spec lines that contains the namevar.

Example:

sudoers { 'NAME':
  ensure   => present,
  users    => ['dan1', 'dan2'],
  hosts    => 'ALL',
  commands => [
    '(root) /usr/bin/su - easapp',
    '(easapp)/usr/local/eas-ts/bin/appctl',
  ],
}

creates the following line:

# Puppet NAMEVAR NAME
dan1,dan2 ALL=(root) /usr/bin/su - easapp,(easapp)/usr/local/eas-ts/bin/appctl

Defaults:

the default name is used to determine uniqueness.

sudoers { 'Defaults@host':
  parameters => ['x=y', 'one=1', 'two=2'],
}

Defaults@host x=y,one=1,two=2

== Notes:

- parsing of multi-line sudoers records is not currently supported.
- ordering only applies when records are created.
"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Either the name of the alias, default, or arbitrary unique string for user specifications"

    munge do |value|
      value
    end

    validate do |value|
      if value =~ /^fake_namevar_\d+/ and resource.line
        raise Puppet::Error, "cannot use reserved namevar #{value}"
      end
    end
  end

  newproperty(:type) do
    desc "optional parameter used to determine what the record type is"

    validate do |my_type|
      unless my_type =~ /(default|alias|user_spec)/
        raise Puppet::Error, "unexpected sudoers type #{my_type}"
      end
    end
    isrequired
  end

  newproperty(:sudo_alias) do
    desc "Type of alias. Options are Cmnd, Host, User, and Runas"

    newvalue(/^(Cmnd|Host|User|Runas)(_Alias)?$/)
    # add _Alias if it was ommitted
    munge do |value|
      if value =~ /^(Cmnd|Host|User|Runas)$/
        value << '_Alias'
      end
      value
    end
    # this is now an alias type
  end

  newproperty(:items, :array_matching => :all) do
    desc "list of items applied to an alias"
  end

  newproperty(:target) do
    desc "Location of the shells file"

    defaultto do
      if
        @resource.class.defaultprovider.ancestors.include?(Puppet::Provider::ParsedFile)
        @resource.class.defaultprovider.default_target
      else
        nil
      end
    end
  end

  # single user is namevar
  newproperty(:users, :array_matching => :all) do
    desc "list of users for user spec"

    validate do |value|
      if value == 'Defaults'
        raise Puppet::Error, 'Cannot specify user named Defaults in sudoers'
      end
    end
  end

  newproperty(:hosts, :array_matching => :all) do
    desc "list of hosts for user spec"
  end

  # maybe I should do more validation for commands
  newproperty(:commands, :array_matching => :all) do
    desc "commands to run"
  end

  newproperty(:parameters, :array_matching => :all) do
    desc "default parameters"
  end

  # I should check that this is not /PUPPET NAMEVAR/
  newproperty(:comment) do
    defaultto ''
  end

  # make sure that we only have attributes for either default, alias, or user_spec
  SUDOERS_DEFAULT = [:parameters]
  SUDOERS_ALIAS = [:sudo_alias, :items]
  SUDOERS_SPEC = [:users, :hosts, :commands]

  validate do
    if self[:ensure] == :present
      case self.value(:type)
       when 'default'
        checkprops(SUDOERS_DEFAULT)
       when 'alias'
        checkprops(SUDOERS_ALIAS)
        unless self[:name] =~ /^[A-Z]([A-Z]|[0-9]|_)*$/
          raise Puppet::Error, "alias names #{self[:name]} does not match [A-Z]([A-Z][0-9]_)*"
        end
      when 'user_spec'
        checkprops(SUDOERS_SPEC)
      end
    end
  end


 private

  def checkprops(props)
    props.each do |prop|
      raise Puppet::Error, "missing attribute #{prop} for type #{self[:type]}" unless self[prop.to_s]
    end
  end
end

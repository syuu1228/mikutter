# -*- coding: utf-8 -*-
#
# userlist.rb
#

# users list

require File.expand_path('utils')
miquire :core, 'autotag'
miquire :core, 'user'
miquire :core, 'retriever'

require 'set'

class UserList < Retriever::Model
  @@system_id = 0

  # args format
  # key         | value(class)
  #-------------+--------------
  # id          | id of status(mixed)
  # name        | name of list(String)
  # public      | access mode(boolean:public if true)
  # description | memo(String)
  # user        | user who post this message(User or Hash or mixed(User IDNumber))
  # slug        | list slug(String)

  self.keys = [[:id, :int, true],
               [:name, :string, true],
               [:mode, :bool],
               [:description, :string],
               [:user, User, true],
               [:slug, :string, true],
               [:member, [User]]
             ]

  def initialize(value)
    assert_type(Hash, value)
    super(value)
  end

  def member
    atomic{ self[:member] = Set.new } if not self[:member]
    self[:member] end

  def member?(user)
    if user.is_a? User
      member.include?(user)
    else
      member.any?{ |m| m.id == user.to_i } end end

  def add_member(user)
    member_update_transaction do
      if user.is_a? User
        member.add(user)
      elsif user.is_a? Integer
        Thread.new {
          user = User.findbyid(user)
          member.add(user) }
      elsif user.is_a? Enumerable
        user.each(&method(:add_member))
      else
        raise ArgumentError.new('UserList member must be User') end end
    self end

  def remove_member(user)
    member_update_transaction do
      if user.is_a? User
        member.delete(user)
      elsif user.is_a? Integer
        member.delete(User.findbyid(user))
      elsif user.is_a? Enumerable
        user.map(&remove_member)
      else
        raise ArgumentError.new('UserList member must be User') end end
    self end

  private
  def member_update_transaction
    before = member.dup
    result = yield
    if before != member
      Plugin.call(:list_member_changed, self)
      self.class.store_datum(self) end
    result end

end

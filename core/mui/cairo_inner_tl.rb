# -*- coding: utf-8 -*-

miquire :mui, 'timeline'
miquire :lib, 'ruby-bsearch-1.5/bsearch'
miquire :lib, 'uithreadonly'
require 'gtk2'

class Gtk::TimeLine::InnerTL < Gtk::CRUD

  include UiThreadOnly

  attr_writer :force_retrieve_in_reply_to
  attr_accessor :postbox, :hp
  type_register('GtkInnerTL')

  # TLの値を返すときに使う
  Record = Struct.new(:id, :message, :created, :miracle_painter)

  MESSAGE_ID = 0
  MESSAGE = 1
  CREATED = 2
  MIRACLE_PAINTER = 3

  def self.current_tl
    ctl = @@current_tl and @@current_tl.toplevel.focus.get_ancestor(Gtk::TimeLine::InnerTL) rescue nil
    ctl if(ctl.is_a?(Gtk::TimeLine::InnerTL) and not ctl.destroyed?)
  end

  def initialize
    super
    @force_retrieve_in_reply_to = :auto
    @hp = 252
    @@current_tl ||= self
    self.name = 'timeline'
    set_headers_visible(false)
    set_enable_search(false)
    last_geo = nil
    selection.mode = Gtk::SELECTION_MULTIPLE
    get_column(0).set_sizing(Gtk::TreeViewColumn::AUTOSIZE)
    signal_connect(:focus_in_event){
      @@current_tl.selection.unselect_all if not(@@current_tl.destroyed?) and @@current_tl and @@current_tl != self
      @@current_tl = self
      false } end

  def cell_renderer_message
    @cell_renderer_message ||= Gtk::CellRendererMessage.new()
  end

  def column_schemer
    [ {:renderer => lambda{ |x,y|
          cell_renderer_message.tree = self
          cell_renderer_message
        },
        :kind => :message_id, :widget => :text, :type => String, :label => ''},
      {:kind => :text, :widget => :text, :type => Message},
      {:kind => :text, :type => Integer},
      {:kind => :text, :type => Object}
    ].freeze
  end

  def menu_pop(widget, event)
  end

  def handle_row_activated
  end

  def reply(message, options = {})
    ctl = Gtk::TimeLine::InnerTL.current_tl
    if(ctl)
      message = model.get_iter(message) if(message.is_a?(Gtk::TreePath))
      message = message[1] if(message.is_a?(Gtk::TreeIter))
      type_strict message => Message
      postbox.closeup(pb = Gtk::PostBox.new(message, options).show_all)
      pb.on_delete(&Proc.new) if block_given?
      get_ancestor(Gtk::Window).set_focus(pb.post)
      ctl.selection.unselect_all end
    self end

  def get_active_messages
    get_active_iterators.map{ |iter| iter[1] } end

  def get_active_iterators
    selected = []
    if not destroyed?
      selection.selected_each{ |model, path, iter|
        selected << iter } end
    selected end

  def get_active_pathes
    selected = []
    if not destroyed?
      selection.selected_each{ |model, path, iter|
        selected << path } end
    selected end

  # 選択範囲の時刻(UNIX Time)の最初と最後を含むRangeを返す
  def selected_range_bytime
    start, last = visible_range
    start_record, last_record = get_record(start), get_record(last)
    Range.new(last_record.created, start_record.created) if (start_record and last_record)
  end

  # _message_ のレコードの _column_ 番目のカラムの値を _value_ にセットする。
  # 成功したら _value_ を返す
  def update!(message, column, value)
    iter = get_iter_by_message(message)
    if iter
      iter[column] = value
      value end end

  # _path_ からレコードを取得する。なければnilを返す。
  def get_record(path)
    iter = model.get_iter(path)
    if iter
      Record.new(iter[0].to_i, iter[1], iter[2], iter[3]) end end

  # _message_ に対応する Gtk::TreePath を返す。なければnilを返す。
  def get_path_by_message(message)
    get_path_and_iter_by_message(message)[1] end

  # _message_ に対応する値の構造体を返す。なければnilを返す。
  def get_record_by_message(message)
    path = get_path_and_iter_by_message(message)[1]
    get_record(path) if path end

  def force_retrieve_in_reply_to
    if(:auto == @force_retrieve_in_reply_to)
      UserConfig[:retrieve_force_mumbleparent]
    else
      @force_retrieve_in_reply_to end end

  private

  # _message_ に対応する Gtk::TreeIter を返す。なければnilを返す。
  def get_iter_by_message(message)
    get_path_and_iter_by_message(message)[2] end

  # _message_ から [model, path, iter] の配列を返す。見つからなかった場合は空の配列を返す。
  def get_path_and_iter_by_message(message)
    id = message[:id].to_i
    found = model.to_enum(:each).find{ |mpi| mpi[2][0].to_i == id }
    found || [] end

end

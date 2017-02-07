{CompositeDisposable} = require 'atom'
{complexityOf} = require './flog-adapter'

module.exports = Flogger =
  markers: null
  activeEditors: null
  subscriptions: null
  statusBarTile: null

  config:
    mediumThreshold:
      type: 'number'
      default: 10
      minimum: 1

    highThreshold:
      type: 'number'
      default: 20
      minimum: 1

    flogCommand:
      type: 'string'
      default: 'flog'

  activate: (state) ->
    @markers = []
    @activeEditors = {}

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'flogger:toggle': => @toggle()
    @subscriptions.add atom.workspace.onDidStopChangingActivePaneItem (item) => @watchCurrentEditor()

  consumeStatusBar: (statusBar) ->
    @status = document.createElement 'span'
    @status.textContent = ''
    @statusBarTile = statusBar.addLeftTile item: @status, priority: 100

  deactivate: ->
    @subscriptions.dispose()
    @statusBarTile?.destroy()
    @statusBarTile = null

  toggle: ->
    return unless te = atom.workspace.getActiveTextEditor()

    if (updater = @activeEditors[te.id])?
      @subscriptions.remove updater
      delete @activeEditors[te.id]
      te.gutterWithName('flogger')?.destroy()
    else
      updater = te.onDidStopChanging => @watchEditor te
      @activeEditors[te.id] = updater
      @subscriptions.add updater
      @watchCurrentEditor()

  watchCurrentEditor: ->
    @setStatus ''
    @watchEditor atom.workspace.getActiveTextEditor()

  watchEditor: (te) ->
    return unless te?.getGrammar()?.name in ['Ruby', 'Ruby on Rails'] and @activeEditors[te.id]?

    complexityOf(te.getText()).then (flogData) =>
      {total, perMethod, methods} = flogData
      @setStatus "Complexity: #{total} (#{perMethod}/method)"
      @setGutter te, methods
    .catch (err) ->
      console.error err

  setStatus: (status) ->
    @status?.textContent = status

  setGutter: (te, methods) ->
    g = te.gutterWithName('flogger') ? te.addGutter name: 'flogger'

    marker.destroy() for marker in @markers
    @markers = []

    for [line_num, complexity] in methods
      m = te.markBufferRange [[line_num - 1, 0], [line_num - 1, 0]]
      d = document.createElement 'span'
      d.classList.add @classify complexity
      d.textContent = complexity.toFixed 1
      g.decorateMarker m, item: d, class: 'flogger'
      @markers.push m

  classify: (complexity) ->
    switch
      when complexity < atom.config.get('flogger.mediumThreshold') then 'low'
      when complexity < atom.config.get('flogger.highThreshold') then 'medium'
      else 'high'

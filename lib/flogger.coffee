{CompositeDisposable, BufferedProcess} = require 'atom'

module.exports = Flogger =
  markers: null
  activeEditors: null
  subscriptions: null
  statusBarTile: null

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

  parse: (flogData) ->
    lines = flogData.split "\n"

    total = +lines.shift().match /\d+\.\d+(?=:)/
    per_method = +lines.shift().match /\d+\.\d+(?=:)/

    methods = []
    lines.shift()

    while value = lines.shift()
      [_, complexity, line_num] = value.match /^\s+(\d+\.\d+):.*:(\d+)$/
      methods.push [+line_num, +complexity]

    [[total, per_method], methods]

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
    return unless te?.getGrammar()?.name is 'Ruby' and @activeEditors[te.id]?
    @update te

  update: (te) ->
    output = ''

    process = new BufferedProcess
      command: 'flog'
      args: ['-aqm']
      stdout: (out) -> output += out
      exit: (code) =>
        if code
          console.error "flog barfed with #{code}"
        else
          [[total, per_method], methods] = @parse output
          @setStatus "Complexity: #{total} (#{per_method}/method)"
          @setGutter te, methods
    .process

    if process.stdin.writable
      process.stdin.write te.getText()
      process.stdin.end()

  setStatus: (status) ->
    @status?.textContent = status

  setGutter: (te, methods) ->
    #te = atom.workspace.getActiveTextEditor()
    g = te.gutterWithName('flogger') ? te.addGutter name: 'flogger'

    marker.destroy() for marker in @markers
    @markers = []

    for [line_num, complexity] in methods
      m = te.markBufferRange [[line_num - 1, 0], [line_num - 1, 0]]
      d = document.createElement 'span'
      d.classList.add @classify complexity
      d.textContent = complexity
      g.decorateMarker m, item: d, class: 'flogger'
      @markers.push m

  classify: (complexity) ->
    switch
      when complexity < 10 then 'low'
      when complexity < 20 then 'medium'
      else 'high'

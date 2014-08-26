url = require 'url'
querystring = require 'querystring'
JadeCompileView = require './jade-compile-view'

module.exports =
  # Define default configuration
  configDefaults:
    pretty: true
    compileDebug: true
    compileOnSave: false
    focusEditorAfterCompile: true

  # Public: Activate the plugin.
  #
  # Returns the view as `JadeCompileView`.
  activate: ->
    atom.workspaceView.command 'jade-compile:compile', => @display()
    atom.workspace.registerOpener (uriToOpen) ->
      {protocol, host, pathname} = url.parse uriToOpen
      pathname = (querystring.unescape pathname) if pathname
      return unless protocol is 'jade-compile:'
      new JadeCompileView sourceEditorId: (pathname.substr 1)

  # Public: Display the content in a preview pane.
  #
  # Returns undefined.
  display: ->
    editor     = atom.workspace.getActiveEditor()
    activePane = atom.workspace.getActivePane()
    return unless editor?
    uri = "jade-compile://editor/#{editor.id}"
    atom.workspace.open uri,
      searchAllPanes: true
      split: 'right'
    .done (jadeCompileView) ->
      if jadeCompileView instanceof JadeCompileView
        jadeCompileView.renderCompiled()
        if atom.config.get 'jade-compile.compileOnSave'
          jadeCompileView.saveCompiled()
        if atom.config.get 'jade-compile.focusEditorAfterCompile'
          activePane.activate()

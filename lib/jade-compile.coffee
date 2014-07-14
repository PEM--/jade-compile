url = require 'url'
querystring = require 'querystring'
JadeCompileView = require './jade-compile-view'

module.exports =
  # Define default configuration
  configDefaults:
    pretty: true
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
      console.log 'Pathname', pathname
      return unless protocol is 'jade-compile:'
      new JadeCompileView(editorId: pathname.substr(1))

  # Public: Display the content in a preview pane.
  #
  # Returns undefined.
  display: ->
    editor     = atom.workspace.getActiveEditor()
    activePane = atom.workspace.getActivePane()
    return unless editor?
    uri = "jade-compile://editor/#{editor.id}"
    # If a pane with the uri
    pane = atom.workspace.paneContainer.paneForUri uri
    # If not, always split right
    pane ?= activePane.splitRight()
    atom.workspace.openUriInPane(uri, pane, {}).done (jadeCompileView) ->
      if jadeCompileView instanceof JadeCompileView
        jadeCompileView.renderCompiled()
        if atom.config.get 'jade-compile.compileOnSave'
          jadeCompileView.saveCompiled()
        if atom.config.get 'jade-compile.focusEditorAfterCompile'
          activePane.activate()

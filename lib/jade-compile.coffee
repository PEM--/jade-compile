url         = require 'url'
querystring = require 'querystring'

JadeCompileView = require './jade-compile-view'

module.exports =
  configDefaults:
    grammars: [
      'source.jade'
    ]
    noTopLevelFunctionWrapper: true
    compileOnSave: false
    focusEditorAfterCompile: false

  activate: ->
    console.log 'Activated'
    atom.workspaceView.command 'jade-compile:compile', => @display()
    atom.workspace.registerOpener (uriToOpen) ->
      {protocol, host, pathname} = url.parse uriToOpen
      pathname = querystring.unescape(pathname) if pathname

      return unless protocol is 'jadecompile:'
      new JadeCompileView(editorId: pathname.substr(1))

  display: ->
    console.log 'Displayed'
    editor     = atom.workspace.getActiveEditor()
    activePane = atom.workspace.getActivePane()

    return unless editor?

    grammars = atom.config.get('jade-compile.grammars') or []
    unless (grammar = editor.getGrammar().scopeName) in grammars
      console.warn("Cannot compile non-Jade to HTML")
      return

    uri = "jadecompile://editor/#{editor.id}"

    # If a pane with the uri
    pane = atom.workspace.paneContainer.paneForUri uri
    # If not, always split right
    pane ?= activePane.splitRight()

    atom.workspace.openUriInPane(uri, pane, {}).done (jadeCompileView) ->
      if jadeCompileView instanceof JadeCompileView
        jadeCompileView.renderCompiled()

        if atom.config.get('jade-compile.compileOnSave')
          jadeCompileView.saveCompiled()
        if atom.config.get('jade-compile.focusEditorAfterCompile')
          activePane.activate()

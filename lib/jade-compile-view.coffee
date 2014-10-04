# Inspiration from: https://github.com/adrianlee44/atom-coffee-compile/
# blob/master/lib/coffee-compile-view.coffee

{EditorView} = require 'atom'
_ = require 'underscore-plus'
path = require 'path'
fs = require 'fs'
{allowUnsafeNewFunction} = require 'loophole'
jade = require 'jade'

module.exports =

# Public: Main Jade compile view that extends the {EditorView} prototype.
class JadeCompileView extends EditorView
  # Public: C-tor
  #
  # @editorId     - The Id of a previously allocated editor as {Number}.
  # @sourceEditor - The instance of the source editor.
  #
  # Returns the instanciated object as `JadeCompileView`.
  constructor: ({@sourceEditorId, @sourceEditor}) ->
    super
    # Used for unsubscribing callbacks on editor text buffer
    @disposables = []
    if @sourceEditorId? and not @sourceEditor
      @sourceEditor = @getSourceEditor @sourceEditorId
    if @sourceEditor?
      @bindJadeCompileEvents()
    @editor.setGrammar atom.syntax.selectGrammar 'hello.html'

  # Public: Bind events on Jade compilation
  #
  # Returns `undefined`.
  bindJadeCompileEvents: ->
    if atom.config.get 'jade-compile.compileOnSave'
      buffer = @sourceEditor.getBuffer()
      @disposables.push buffer.onDidSave =>
        @renderCompiled()
        JadeCompileView.saveCompiled @sourceEditor
      @disposables.push buffer.onDidReload =>
        @renderCompiled()
        JadeCompileView.saveCompiled @sourceEditor

  # Public: Called when view is destroyed
  #
  # Returns `undefined`.
  destroy: ->
    disposable.dispose() for disposable in @disposables

  # Public: Get current editor instance if exists.
  #
  # id - The Id of the searched editor as {Number}.
  #
  # Returns the instance of the editor as `JadeCompileView`, null otherwise.
  getSourceEditor: (id) ->
    for editor in atom.workspace.getEditors()
      return editor if editor.id?.toString() is id.toString()
    null

  # Public: Get the current code to be previewed.
  #
  # Returns the complete content of the edited code or only the currently
  #  selected text `String`.
  getSelectedCode: ->
    range = @sourceEditor.getSelectedBufferRange()
    code  =
      if range.isEmpty()
        @sourceEditor.getText()
      else
        @sourceEditor.getTextInBufferRange range

  # Public: Render compiled code.
  #
  # Returns `undefined`.
  renderCompiled: ->
    code = @getSelectedCode()
    try
      text = JadeCompileView.compile code
    catch e
      text = e.stack
    @getEditor().setText text

  # Public: Create a title depending on context usage.
  #
  # Returns the title as `String`.
  getTitle: ->
    if @sourceEditor?
      "Compiled #{@sourceEditor.getTitle()}"
    else
      'Compiled HTML'

  # Public: Get editor's URI.
  #
  # Returns the URI as `String`.
  getUri: -> "jade-compile://editor/#{@sourceEditorId}"

  # Public: Render code using Jade. Note that the evaluation is done
  # in an internal context (sandboxed) thanks to loophole.
  #
  # code - The code to render as {String}.
  #
  # Returns the rendered HTML as `String`.
  @compile: (code) ->
    html = ''
    try
      allowUnsafeNewFunction ->
        html = jade.render code,
          pretty: atom.config.get 'jade-compile.pretty'
          compileDebug: atom.config.get 'jade-compile.compileDebug'
    catch e
      html = e.message
    html

  # Public: Save compiled code.
  #
  # callback - The asynchroneous callback.
  #
  # Returns the callback result if any, `undefined` otherwise.
  saveCompiled: (editor, callback) ->
    try
      text     = JadeCompileView.compile editor.getText()
      srcPath  = editor.getPath()
      srcExt   = path.extname srcPath
      destPath = path.join (path.dirname srcPath),
        "#{path.basename srcPath, srcExt}.html"
      fs.writeFile destPath, text, callback
    catch e
      console.error "jade-compile: #{e.stack}"

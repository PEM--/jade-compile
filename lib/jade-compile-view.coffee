{$, $$$, EditorView, ScrollView} = require 'atom'
_ = require 'underscore-plus'
path = require 'path'
fs = require 'fs'
{allowUnsafeNewFunction} = require 'loophole'
jade = require 'jade'

module.exports =

# Public: Main Jade compile view that extends the {ScrollView} prototype.
class JadeCompileView extends ScrollView
  @content: ->
    @div class: 'jade-compile native-key-bindings', tabindex: -1, =>
      @div class: 'editor editor-colors', =>
        @div outlet: 'compiledCode', class: 'lang-html lines'

  # Public: C-tor
  #
  # {@editorId - The Id of a previously allocated editor as {Number}.
  # editor}    - The instance of a previously allocated
  #              editor as {JadeCompileView}.
  #
  # Returns the instanciated object as `JadeCompileView`.
  constructor: ({@editorId, @editor}) ->
    super
    if @editorId? and not @editor
      @editor = @getEditor @editorId

    if @editor?
      @trigger 'title-changed'
      @bindEvents()

  # Public: Destroy current instance.
  #
  # Returns `undefined`.
  destroy: -> @unsubscribe()

  bindEvents: ->
    @subscribe atom.syntax,
      'grammar-updated',
      _.debounce (=> @renderCompiled()), 250

    @subscribe this, 'core:move-up', => @scrollUp()
    @subscribe this, 'core:move-down', => @scrollDown()

    if atom.config.get('jade-compile.compileOnSave')
      @subscribe @editor.buffer, 'saved', => @saveCompiled()

  # Public: Get current editor instance if exists.
  #
  # id - The Id of the searched editor as {Number}.
  #
  # Returns the instance of the editor as `JadeCompileView`, null otherwise.
  getEditor: (id) ->
    for editor in atom.workspace.getEditors()
      return editor if editor.id?.toString() is id.toString()
    null

  # Public: Get the current code to be previewed.
  #
  # Returns the complete content of the edited code or only the currently
  #  selected text `String`.
  getSelectedCode: ->
    range = @editor.getSelectedBufferRange()
    code  =
      if range.isEmpty()
        @editor.getText()
      else
        @editor.getTextInBufferRange(range)


  # Public: Render code using Jade. Note that the evaluation is done
  # in an internal context (sandboxed) thanks to loophole.
  #
  # code - The code to render as {String}.
  #
  # Returns the rendered HTML as `String`.
  compile: (code) ->
    html = ''
    try
      allowUnsafeNewFunction ->
        html = jade.render code,
          pretty: false
    catch e
      console.error 'jade-compile', e
    html

  # Public: Save compiled code.
  #
  # callback - An optional asynchroneous callback.
  #
  # Returns the callback result if any, `undefined` otherwise.
  saveCompiled: (callback) ->
    try
      text     = @compile @editor.getText()
      srcPath  = @editor.getPath()
      srcExt   = path.extname srcPath
      destPath = path.join(
        path.dirname(srcPath), "#{path.basename(srcPath, srcExt)}.html"
      )
      fs.writeFileSync destPath, text
    catch e
      console.error "jade-compile: #{e.stack}"
    callback?()

  # Public: Render compile Jade code in the preview editor.
  #
  # callback - An optional asynchroneous callback.
  #
  # Returns the callback result if any, `undefined` otherwise.
  renderCompiled: (callback) ->
    code = @getSelectedCode()
    try
      text = @compile code
    catch e
      text = e.stack
    grammar = atom.syntax.selectGrammar 'hello.html', text
    @compiledCode.empty()

    for tokens in grammar.tokenizeLines text
      attributes = class: 'line'
      @compiledCode.append(EditorView.buildLineHtml {tokens, text, attributes})

    # Match editor styles
    @compiledCode.css
      fontSize: atom.config.get('editor.fontSize') or 12
      fontFamily: atom.config.get 'editor.fontFamily'
    callback?()

  # Public: Create a title depending on context usage.
  #
  # Returns the title as `String`.
  getTitle: ->
    if @editor?
      "Compiled #{@editor.getTitle()}"
    else
      'Compiled HTML'

  # Public: Get editor's URI.
  #
  # Returns the URI as `String`.
  getUri: -> "jade-compile://editor/#{@editorId}"

  # Public: Get editor's path.
  #
  # Returns the editor's path as `String` it it exists,
  #  an empty `String` otherwise.
  getPath: -> @editor?.getPath() or ''

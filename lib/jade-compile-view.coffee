{$, $$$, EditorView, ScrollView} = require 'atom'
_ = require 'underscore-plus'
path = require 'path'
fs = require 'fs'
{allowUnsafeNewFunction} = require 'loophole'
jade = require 'jade'

module.exports =
class JadeCompileView extends ScrollView
  @content: ->
    @div class: 'jade-compile native-key-bindings', tabindex: -1, =>
      @div class: 'editor editor-colors', =>
        @div outlet: 'compiledCode', class: 'lang-html lines'

  constructor: ({@editorId, @editor}) ->
    super
    if @editorId? and not @editor
      @editor = @getEditor @editorId

    if @editor?
      @trigger 'title-changed'
      @bindEvents()

  destroy: -> @unsubscribe()

  bindEvents: ->
    @subscribe atom.syntax,
      'grammar-updated',
      _.debounce((=> @renderCompiled()), 250)

    @subscribe this, 'core:move-up', => @scrollUp()
    @subscribe this, 'core:move-down', => @scrollDown()

    if atom.config.get('jade-compile.compileOnSave')
      @subscribe @editor.buffer, 'saved', => @saveCompiled()

  getEditor: (id) ->
    for editor in atom.workspace.getEditors()
      return editor if editor.id?.toString() is id.toString()
    null

  getSelectedCode: ->
    range = @editor.getSelectedBufferRange()
    code  =
      if range.isEmpty()
        @editor.getText()
      else
        @editor.getTextInBufferRange(range)

  compile: (code) ->
    html = ''
    try
      allowUnsafeNewFunction ->
        html = jade.render code, pretty: true
    catch e
      console.error 'jade-compile', e
    html

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

  renderCompiled: (callback) ->
    code = @getSelectedCode()
    try
      text = @compile code
    catch e
      text = e.stack
    grammar = atom.syntax.selectGrammar('hello.html', text)
    @compiledCode.empty()

    for tokens in grammar.tokenizeLines(text)
      attributes = class: 'line'
      @compiledCode.append(EditorView.buildLineHtml({tokens, text, attributes}))

    # Match editor styles
    @compiledCode.css
      fontSize: atom.config.get('editor.fontSize') or 12
      fontFamily: atom.config.get('editor.fontFamily')
    callback?()

  getTitle: ->
    if @editor?
      "Compiled #{@editor.getTitle()}"
    else
      'Compiled HTML'

  getUri:   -> "jadecompile://editor/#{@editorId}"
  getPath:  -> @editor?.getPath() or ''

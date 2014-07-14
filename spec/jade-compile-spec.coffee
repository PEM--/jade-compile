{WorkspaceView} = require 'atom'
AtomJadeCompile = require '../lib/atom-jade-compile'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "AtomJadeCompile", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('atom-jade-compile')

  describe "when the atom-jade-compile:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.atom-jade-compile')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'atom-jade-compile:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.atom-jade-compile')).toExist()
        atom.workspaceView.trigger 'atom-jade-compile:toggle'
        expect(atom.workspaceView.find('.atom-jade-compile')).not.toExist()

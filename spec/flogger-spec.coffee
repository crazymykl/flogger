path = require 'path'
Flogger = require '../lib/flogger'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "Flogger", ->
  [workspaceElement, activationPromise, fixturesPath] = []
  gutterSelector = "::shadow .gutter[gutter-name='flogger']"

  beforeEach ->
    fixturesPath = path.join __dirname, 'fixtures'
    workspaceElement = atom.views.getView atom.workspace
    activationPromise = atom.packages.activatePackage 'flogger'
    atom.project.setPaths [fixturesPath]

    waitsForPromise ->
      atom.packages.activatePackage 'language-ruby'

    waitsForPromise ->
      atom.workspace.open "test.rb"

  describe "when the flogger:toggle event is triggered", ->

    it "hides and shows the gutter on a ruby file", ->
      jasmine.attachToDOM workspaceElement

      floggerElement = workspaceElement.querySelector gutterSelector
      expect(floggerElement).not.toExist()

      atom.commands.dispatch workspaceElement, 'flogger:toggle'

      waitsForPromise ->
        activationPromise

      waitsFor ->
        floggerElement = workspaceElement.querySelector gutterSelector

      runs ->
        expect(floggerElement).toBeVisible()
        atom.commands.dispatch workspaceElement, 'flogger:toggle'
        expect(floggerElement).not.toBeVisible()

    it "debugs", ->
      atom.commands.dispatch workspaceElement, 'flogger:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        flogger = atom.packages.getActivePackage('flogger').mainModule
